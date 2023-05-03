package main

import (
	"context"
	"log"
	"os"
	"os/signal"

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

	done := make(chan struct{})
	go func() {
		r.Run(ctx)
		close(done)
	}()

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)

	select {
	case <-done:
		return
	case sig := <-c:
		r.Log.Warnf("Got %s signal. Aborting...", sig)
		err := r.Kill(ctx)
		if err != nil {
			r.Log.Fatalf("Failed to kill docker container: %v", err)
		}
	}
}
