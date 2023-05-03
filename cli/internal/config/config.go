package config

import (
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/spf13/pflag"
	"github.com/spf13/viper"
)

type Values struct {
	Config Config `mapstructure:"config"`
	Flags  Flags  `mapstructure:"flags"`
}

type Config struct {
	MaxContainerAge  time.Duration `mapstructure:"max_container_age"`
	ServerConfigPath string        `mapstructure:"server_config_path"`
	RequirementsPath string        `mapstructure:"requirements_path"`
	ProjectsDir      string        `mapstructure:"projects_dir"`
	Gamemode         string        `mapstructure:"gamemode"`
	CollectionID     string        `mapstructure:"collection_id"`
	GithubToken      string        `mapstructure:"github_token"`
	SSHPrivateKey    string        `mapstructure:"ssh_private_key"`
	Timeout          time.Duration `mapstructure:"timeout"`
}

// TODO merge config and flags, flags should always overwrite config values

type Flags struct {
	NoFilter bool   `mapstructure:"nofilter"`
	LogLevel string `mapstructure:"loglevel"`
}

func defaults() {
	viper.SetDefault("config.max_container_age", time.Hour*24)
	viper.SetDefault("config.projects_dir", "./")
	viper.SetDefault("config.gamemode", "sandbox")
	viper.SetDefault("config.timeout", time.Minute*5)
}

func getFlags() {
	flagSet := pflag.NewFlagSet("gluatest", pflag.ExitOnError)

	flagSet.Bool("nofilter", false, "filter projects")
	flagSet.String("loglevel", "warn", "log level")

	flagSet.Parse(os.Args)

	viper.BindPFlag("flags.nofilter", flagSet.Lookup("nofilter"))
	viper.BindPFlag("flags.loglevel", flagSet.Lookup("loglevel"))
}

func LoadConfig() (*Values, error) {
	defaults()
	// TODO also load from env
	viper.AddConfigPath(".")
	viper.SetConfigName("gluatest")
	viper.SetConfigType("yaml")

	err := viper.ReadInConfig()
	if err != nil {
		log.Printf("could not read in config file: %v", err)
	}

	getFlags()

	var cfg Values

	err = viper.Unmarshal(&cfg)
	if err != nil {
		return nil, err
	}
	return setAbsolutePaths(&cfg), err
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

func setAbsolutePaths(values *Values) *Values {
	values.Config.ServerConfigPath = mustAbs(values.Config.ServerConfigPath)
	values.Config.RequirementsPath = mustAbs(values.Config.RequirementsPath)
	values.Config.ProjectsDir = mustAbs(values.Config.ProjectsDir)

	return values
}
