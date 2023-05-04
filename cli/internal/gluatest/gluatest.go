package gluatest

import (
	"context"
	"fmt"
	"io"
	"log"
	"os"
	"time"

	"github.com/cfc-servers/gluatest/cli/internal/config"
	"github.com/cfc-servers/gluatest/cli/internal/filtering"
	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/api/types/mount"
	"github.com/docker/docker/client"
	"github.com/docker/docker/pkg/stdcopy"
	"github.com/sirupsen/logrus"
)

type TestRun struct {
	Client             *client.Client
	Config             *config.Values
	Log                logrus.FieldLogger
	statusCode         int
	runningContainerID string
}

func NewTestRun(cfg *config.Values) (*TestRun, error) {
	log := logrus.StandardLogger()

	level, err := logrus.ParseLevel(cfg.Flags.LogLevel)
	if err != nil {
		log.Fatalf("Failed to parse log level: %v", err)
	}
	log.SetLevel(level)

	client, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		log.Fatalf("Failed to create docker client: %v", err)
	}

	return &TestRun{
		Config: cfg,
		Client: client,
		Log:    log,
	}, nil
}

func (r *TestRun) ExitCode() int {
	return r.statusCode
}

func (r *TestRun) Kill(ctx context.Context) error {
	log := r.Log.WithField("containerID", r.runningContainerID)
	timeout := 5
	err := r.Client.ContainerStop(ctx, r.runningContainerID, container.StopOptions{Timeout: &timeout})
	if err != nil {
		return err
	}
	log.Infof("Killed container")
	return nil
}

func (r *TestRun) Run(ctx context.Context) {
	r.Log.Info("Starting test run")

	if err := r.pruneExistingContainers(ctx); err != nil {
		r.Log.Errorf("Failed to prune existing containers: %v", err)
	}

	containerID, err := r.createContainer(ctx)
	if err != nil {
		r.Log.Fatalf("Failed to create container: %v", err)
	}

	r.runContainer(ctx, containerID)
}

func (r *TestRun) pruneExistingContainers(ctx context.Context) error {
	containers, err := r.Client.ContainerList(ctx, types.ContainerListOptions{All: true})
	if err != nil {
		return fmt.Errorf("failed to list containers: %v", err)
	}
	for _, c := range containers {
		containerWorkingDir, ok := c.Labels[workingDirLabelKey]
		if !ok {
			continue
		}

		if time.Since(time.Unix(c.Created, 0)) > r.Config.Config.MaxContainerAge {
			r.Log.Debugf("Removing container %s as it is older than %s", c.ID, r.Config.Config.MaxContainerAge)
			if err := r.Client.ContainerRemove(ctx, c.ID, types.ContainerRemoveOptions{}); err != nil {
				log.Printf("Failed to remove container %s: %v", c.ID, err)
			}
			continue
		}

		if containerWorkingDir == r.Config.Config.Mounts.Project {
			r.Log.Debugf("Removing old container %s", c.ID)
			r.Client.ContainerRemove(ctx, c.ID, types.ContainerRemoveOptions{})
		}
	}
	return nil
}

const (
	dockerImage        = "ghcr.io/cfc-servers/gluatest"
	workingDirLabelKey = "org.cfcservers.org-gluatest-project-dir"
)

func (r *TestRun) createContainer(ctx context.Context) (string, error) {
	reader, err := r.Client.ImagePull(ctx, dockerImage, types.ImagePullOptions{})
	if err != nil {
		return "", err
	}
	defer reader.Close()
	io.Copy(io.Discard, reader) // TODO display this taking up at most one line

	resp, err := r.Client.ContainerCreate(ctx, &container.Config{
		Env: getEnv(r.Config),
		Cmd: []string{},
		Labels: map[string]string{
			workingDirLabelKey: r.Config.Config.Mounts.Project,
		},
		Tty:   false,
		Image: dockerImage,
	}, &container.HostConfig{
		Mounts: getMounts(r.Config),
	}, nil, nil, "")

	if err != nil {
		return "", err
	}

	return resp.ID, nil
}

func (r *TestRun) runContainer(ctx context.Context, containerID string) {
	r.Log.Info("Starting container...")

	containerStartTime := time.Now()

	r.runningContainerID = containerID

	if err := r.Client.ContainerStart(ctx, containerID, types.ContainerStartOptions{}); err != nil {
		logrus.Fatalf("Failed to start container: %v", err)
	}

	logHandlerDone := make(chan struct{})
	go func() {
		r.handleContainerLogs(ctx, containerID, containerStartTime)
		close(logHandlerDone)
	}()

	statusCh, errCh := r.Client.ContainerWait(ctx, containerID, container.WaitConditionNotRunning)
	select {
	case err := <-errCh:
		log.Fatalf("Failed waiting for container: %v", err)
	case resp := <-statusCh:
		r.statusCode = int(resp.StatusCode)
	case <-ctx.Done():
		log.Fatalf("Timed out waiting for container to finish")
	}

	<-logHandlerDone
}

func (r *TestRun) handleContainerLogs(ctx context.Context, containerID string, since time.Time) {
	sinceStr := since.Format(time.RFC3339)

	r.Log.WithField("since", sinceStr).Info("Getting container logs")

	out, err := r.Client.ContainerLogs(ctx, containerID, types.ContainerLogsOptions{Follow: true, Since: since.Format(time.RFC3339), ShowStdout: true})
	if err != nil {
		log.Fatalf("Failed to get container logs: %v", err)
	}

	if !r.Config.Flags.NoFilter {
		r.Log.Debug("Filtering output enabled")
		out = filtering.FilterGLuaTestOutput(out)
	}

	stdcopy.StdCopy(os.Stderr, os.Stdout, out)
}

func getEnv(cfg *config.Values) []string {
	potentialnEnv := map[string]string{
		"GAMEMODE":        cfg.Config.Gamemode,
		"COLLECTION_ID":   cfg.Config.CollectionID,
		"SSH_PRIVATE_KEY": cfg.Config.SSHPrivateKey,
		"GITHUB_TOKEN":    cfg.Config.GithubToken,
	}

	out := make([]string, 0, len(potentialnEnv))
	for k, v := range potentialnEnv {
		if v != "" {
			out = append(out, k+"="+v)
		}
	}

	return out
}

func getMounts(cfg *config.Values) []mount.Mount {
	mountCfg := &cfg.Config.Mounts

	mounts := []mount.Mount{

		{
			Type:     mount.TypeBind,
			Source:   mountCfg.Project,
			Target:   "/home/steam/gmodserver/garrysmod/addons/project",
			ReadOnly: true,
		},
	}

	if mountCfg.ServerConfig != "" {
		mounts = append(mounts, mount.Mount{
			Type:     mount.TypeBind,
			Source:   mountCfg.ServerConfig,
			Target:   "/home/steam/gmodserver/garrysmod/cfg/server.cfg",
			ReadOnly: true,
		})
	}

	if mountCfg.Requirements != "" {
		mounts = append(mounts, mount.Mount{
			Type:     mount.TypeBind,
			Source:   mountCfg.Requirements,
			Target:   "/home/steam/gmodserver/custom_requirements.txt",
			ReadOnly: true,
		})
	}
	return mounts
}
