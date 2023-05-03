package filtering

import (
	"bufio"
	"io"
	"strings"
)

type GLuaTestFilter struct {
	in         io.ReadCloser
	scanner    *bufio.Scanner
	showOutput bool
}

func FilterGLuaTestOutput(in io.ReadCloser) io.ReadCloser {
	scanner := bufio.NewScanner(in)
	return &GLuaTestFilter{in: in, scanner: scanner}
}

func (f *GLuaTestFilter) Close() error {
	return f.in.Close()
}

var startMessage = "[GLuaTest]: Test run starting..."
var endMessage = "[GLuaTest]: Test run complete!"

// TODO filter certain lines and trigger events like force closing the server or printing
//
// Error loading gamemode!
// Cannot find/load "gamemodes/terrortown/gamemode/init.lua"!
//
// Add "-debug" to the /home/steam/gmodserver/srcds_run_x64 command line to generate a debug.log to help with solving this problem
// : Server restart in 10 seconds

func (f *GLuaTestFilter) Read(p []byte) (int, error) {
	for {
		f.scanner.Scan()
		lineBytes := f.scanner.Bytes()
		if len(lineBytes) == 0 {
			return 0, io.EOF
		}
		if !f.showOutput && len(lineBytes) >= len(startMessage) && strings.HasSuffix(string(lineBytes), startMessage) {
			f.showOutput = true
		} else if f.showOutput && len(lineBytes) >= len(endMessage) && strings.HasSuffix(string(lineBytes), endMessage) {
			f.showOutput = false
		} else if f.showOutput {
			lineBytes = append(lineBytes, '\n')
			copy(p, lineBytes)
			return len(lineBytes), nil
		}
	}
}
