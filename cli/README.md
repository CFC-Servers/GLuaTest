### Running
- Install docker and make sure its running
- Run `gluatest` in the root of your project

##### Flags
- `--nofilter` dont filter non gluatest output out of printed server logs
- `--loglevel <level>`  set the log level to `debug/info/warn` defaults to `warn`

### Configuring
gluatest can be configured by creating a file 
`gluatest.yaml`

```yaml
config:
  # gamemode the server will run on
  gamemode: sandbox
  
  # workshop collection id for the server
  collection_id: ""

  mounts:
    # path to your lua addon, optiona, defaults to ./
    project: "./"

    # path to your requirements file listing addons for gluatest to fetch
    requirements: "deps.txt"

    # path to your server cfg file
    server_config: "myserver.cfg"
    
    # path to mount to lua/bin
    binary_modules: "gmod_bin"
```

  
