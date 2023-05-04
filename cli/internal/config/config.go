package config

import (
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
	Gamemode     string `mapstructure:"gamemode"`
	CollectionID string `mapstructure:"collection_id"`

	// TODO support another way to pass these in such as env
	// if gluatest.yaml is source controlled they cannot be in that file
	GithubToken   string `mapstructure:"github_token"`
	SSHPrivateKey string `mapstructure:"ssh_private_key"`

	Mounts MountConfig `mapstructure:"mounts"`

	MaxContainerAge time.Duration `mapstructure:"max_container_age"`
}

type MountConfig struct {
	Project      string `mapstructure:"project"`
	ServerConfig string `mapstructure:"server_config"`
	Requirements string `mapstructure:"requirements_path"`
}

type Flags struct {
	NoFilter bool   `mapstructure:"nofilter"`
	LogLevel string `mapstructure:"loglevel"`
}

func defaults() {
	viper.SetDefault("config.max_container_age", time.Hour*1)
	viper.SetDefault("config.mounts.project", "./")
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
	viper.ReadInConfig()

	getFlags()

	var cfg Values

	err := viper.Unmarshal(&cfg)
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
	mounts := &values.Config.Mounts

	mounts.ServerConfig = mustAbs(mounts.ServerConfig)
	mounts.Requirements = mustAbs(mounts.Requirements)
	mounts.Project = mustAbs(mounts.Project)

	return values
}
