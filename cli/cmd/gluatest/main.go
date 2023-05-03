package main

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
)

const dockerImage = "ghcr.io/cfc-servers/gluatest"

func main() {
	ctx := context.Background()

	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	client, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		log.Fatalf("Failed to create docker client: %v", err)
	}

	containerID, err := findExistingContainer(ctx, cfg, client)
	if err == nil {
		client.ContainerRemove(ctx, containerID, types.ContainerRemoveOptions{})
	}

	containerID, err = createContainer(ctx, cfg, client)
	if err != nil {
		log.Fatalf("Failed to create container: %v", err)
	}

	runContainer(ctx, *cfg, client, containerID)
}

func runContainer(ctx context.Context, cfg config.Config, client *client.Client, containerID string) {
	log.Println("Starting container")
	start := time.Now()
	if err := client.ContainerStart(ctx, containerID, types.ContainerStartOptions{}); err != nil {
		log.Fatalf("Failed to start container: %v", err)
	}

	var statusCode int64
	statusCh, errCh := client.ContainerWait(ctx, containerID, container.WaitConditionNotRunning)

	done := make(chan struct{})
	go func() {
		out, err := client.ContainerLogs(ctx, containerID, types.ContainerLogsOptions{Follow: true, Since: start.Format(time.RFC3339), ShowStdout: true})
		if err != nil {
			log.Fatalf("Failed to get container logs: %v", err)
		}
		stdcopy.StdCopy(os.Stderr, os.Stdout, filtering.FilterGLuaTestOutput(out))
		close(done)
	}()

	select {
	case err := <-errCh:
		if err != nil {
			log.Fatalf("Failed to wait for container: %v", err)
		}
	case resp := <-statusCh:
		statusCode = resp.StatusCode
	}
	<-done
	os.Exit(int(statusCode))
}

const (
	workingDirLabelKey = "org.cfcservers.org-gluatest-project-dir"
)

var ErrContainerNotFound = fmt.Errorf("container not found")

func findExistingContainer(ctx context.Context, cfg *config.Config, client *client.Client) (string, error) {
	containers, err := client.ContainerList(ctx, types.ContainerListOptions{All: true})
	if err != nil {
		return "", fmt.Errorf("failed to list containers: %v", err)
	}
	for _, c := range containers {
		containerWorkingDir, ok := c.Labels[workingDirLabelKey]
		if !ok {
			continue
		}

		if time.Since(time.Unix(c.Created, 0)) > cfg.MaxContainerAge {
			log.Printf("Removing container %s as it is older than %s", c.ID, cfg.MaxContainerAge)
			if err := client.ContainerRemove(ctx, c.ID, types.ContainerRemoveOptions{}); err != nil {
				log.Printf("Failed to remove container %s: %v", c.ID, err)
			}
			continue
		}

		if containerWorkingDir == cfg.ProjectsDir {
			return c.ID, nil
		}
	}
	return "", ErrContainerNotFound
}

func createContainer(ctx context.Context, cfg *config.Config, client *client.Client) (string, error) {
	fmt.Println("TEST")
	reader, err := client.ImagePull(ctx, dockerImage, types.ImagePullOptions{})
	if err != nil {
		log.Fatalf("Failed to pull docker image: %v", err)
	}
	defer reader.Close()
	io.Copy(io.Discard, reader)

	resp, err := client.ContainerCreate(ctx, &container.Config{
		Env: getEnv(cfg),
		Cmd: []string{},
		Labels: map[string]string{
			workingDirLabelKey: cfg.ProjectsDir,
		},
		Tty:   false,
		Image: dockerImage,
	}, &container.HostConfig{
		Mounts: getMounts(cfg),
	}, nil, nil, "")

	if err != nil {
		log.Fatalf("Failed to create container: %v", err)
	}
	return resp.ID, nil
}

func getEnv(cfg *config.Config) []string {
	var out []string

	if cfg.Gamemode != "" {
		out = append(out, "GAMEMODE="+cfg.Gamemode)
	}

	if cfg.CollectionID != "" {
		out = append(out, "COLLECTION_ID="+cfg.CollectionID)
	}

	if cfg.SSHPrivateKey != "" {
		out = append(out, "SSH_PRIVATE_KEY="+cfg.SSHPrivateKey)
	}

	if cfg.GithubToken != "" {
		out = append(out, "GITHUB_TOKEN="+cfg.GithubToken)
	}

	return out
}
func getMounts(cfg *config.Config) []mount.Mount {
	mounts := []mount.Mount{

		{
			Type:     mount.TypeBind,
			Source:   cfg.ProjectsDir,
			Target:   "/home/steam/gmodserver/garrysmod/addons/project",
			ReadOnly: true,
		},
	}

	if cfg.ServerConfigPath != "" {
		mounts = append(mounts, mount.Mount{
			Type:     mount.TypeBind,
			Source:   cfg.ServerConfigPath,
			Target:   "/home/steam/gmodserver/garrysmod/cfg/server.cfg",
			ReadOnly: true,
		})
	}

	if cfg.RequirementsPath != "" {
		mounts = append(mounts, mount.Mount{
			Type:     mount.TypeBind,
			Source:   cfg.RequirementsPath,
			Target:   "/home/steam/gmodserver/custom_requirements.txt",
			ReadOnly: true,
		})
	}
	return mounts
}
