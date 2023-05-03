package main

import (
	"context"
	"log"
	"os"

	"github.com/cfc-servers/gluatest/cli/internal/config"
	"github.com/cfc-servers/gluatest/cli/internal/gluatest"
)

func main() {
	ctx := context.Background()

	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	r, err := gluatest.NewTestRun(cfg)
	if err != nil {
		log.Fatalf("Failed to create test run: %v", err)
	}
	r.Run(ctx)

	os.Exit(r.ExitCode())
}
