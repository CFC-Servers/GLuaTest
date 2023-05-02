package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/cfc-servers/gluatest/cli/internal/config"
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
	if err != nil {
		log.Println("No container found, creating container")
		containerID, err = createContainer(ctx, cfg, client)
		if err != nil {
			log.Fatalf("Failed to create container: %v", err)
		}
	}

	runContainer(ctx, *cfg, client, containerID)
}

func runContainer(ctx context.Context, cfg config.Config, client *client.Client, containerID string) {
	log.Println("Starting container")
	start := time.Now()
	if err := client.ContainerStart(ctx, containerID, types.ContainerStartOptions{}); err != nil {
		log.Fatalf("Failed to start container: %v", err)
	}

	statusCh, errCh := client.ContainerWait(ctx, containerID, container.WaitConditionNotRunning)
	select {
	case err := <-errCh:
		if err != nil {
			log.Fatalf("Failed to wait for container: %v", err)
		}
	case <-statusCh:
	}

	out, err := client.ContainerLogs(ctx, containerID, types.ContainerLogsOptions{Since: start.Format(time.RFC3339), ShowStdout: true})
	if err != nil {
		log.Fatalf("Failed to get container logs: %v", err)
	}

	stdcopy.StdCopy(os.Stdout, os.Stderr, out)
}

func resolveDesiredContainerName() (string, error) {
	path, err := os.Getwd()
	if err != nil {
		return "", err
	}
	return filepath.Base(path), nil
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
	reader, err := client.ImagePull(ctx, dockerImage, types.ImagePullOptions{})
	if err != nil {
		log.Fatalf("Failed to pull docker image: %v", err)
	}
	defer reader.Close()
	io.Copy(os.Stdout, reader)

	log.Println("No container found, creating container with Name: gluatest")
	start := time.Now()
	resp, err := client.ContainerCreate(ctx, &container.Config{
		Env: []string{"GAMEMODE=sandbox"},
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
	log.Printf("Created container %s in %s", resp.ID, time.Since(start))
	return resp.ID, nil
}

func getMounts(cfg *config.Config) []mount.Mount {
	fmt.Println(cfg.ServerConfigPath)
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
