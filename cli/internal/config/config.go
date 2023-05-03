package config

import (
	"log"
	"path/filepath"
	"time"

	"github.com/spf13/viper"
)

type Config struct {
	MaxContainerAge  time.Duration `mapstructure:"max_container_age"`
	ServerConfigPath string        `mapstructure:"server_config_path"`
	RequirementsPath string        `mapstructure:"requirements_path"`
	ProjectsDir      string        `mapstructure:"projects_dir"`
	Gamemode         string        `mapstructure:"gamemode"`
	CollectionID     string        `mapstructure:"collection_id"`
	GithubToken      string        `mapstructure:"github_token"`
	SSHPrivateKey    string        `mapstructure:"ssh_private_key"`
}

func defaults() {
	viper.SetDefault("config.max_container_age", time.Hour*24)
	viper.SetDefault("config.projects_dir", "./")
	viper.SetDefault("config.gamemode", "sandbox")
}

func LoadConfig() (*Config, error) {
	defaults()

	// TODO also load from env
	viper.AddConfigPath(".")
	viper.SetConfigName("gluatest")
	viper.SetConfigType("yaml")

	err := viper.ReadInConfig()
	if err != nil {
		log.Printf("could not read in config file: %v", err)
	}

	cfg := struct {
		Config Config `mapstructure:"config"`
	}{}

	err = viper.Unmarshal(&cfg)
	if err != nil {
		return nil, err
	}

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
