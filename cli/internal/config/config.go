package config

import (
	"log"
	"path/filepath"
	"time"

	"github.com/spf13/viper"
)

type Config struct {
	MaxContainerAge  time.Duration `mapstructure:"max_container_age"`
	Gamemode         string        `mapstructure:"gamemode"`
	ServerConfigPath string        `mapstructure:"server_config_path"`
	RequirementsPath string        `mapstructure:"requirements_path"`
	ProjectsDir      string        `mapstructure:"projects_dir"`
}

func defaults() {
	viper.SetDefault("max_container_age", time.Hour*24)
	viper.SetDefault("gamemode", "sandbox")
}

func LoadConfig() (*Config, error) {
	// TODO also load from env
	viper.AddConfigPath(".")
	viper.SetConfigName("gluatest")
	viper.SetConfigType("yaml")

	err := viper.ReadInConfig()
	if err != nil {
		return nil, err
	}

	cfg := struct {
		Config Config
	}{}

	err = viper.Unmarshal(&cfg)
	if err != nil {
		return nil, err
	}
	log.Printf("Loaded config: %+v", cfg)
	return setAbsolutePaths(&cfg.Config), err
}

func mustAbs(path string) string {
	if path == "" {
		return ""
	}

	abs, err := filepath.Abs(path)
	if err != nil {
		panic(err)
	}
	return abs
}

func setAbsolutePaths(cfg *Config) *Config {
	cfg.ServerConfigPath = mustAbs(cfg.ServerConfigPath)
	cfg.RequirementsPath = mustAbs(cfg.RequirementsPath)
	cfg.ProjectsDir = mustAbs(cfg.ProjectsDir)
	return cfg
}
