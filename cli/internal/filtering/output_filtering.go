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

var startMessage = "Running project_name"
var endMessage = "Test failures"

func (f *GLuaTestFilter) Read(p []byte) (int, error) {
	for {
		f.scanner.Scan()
		lineBytes := f.scanner.Bytes()
		if len(lineBytes) == 0 {
			return 0, io.EOF
		}
		if len(lineBytes) >= len(startMessage) && strings.Contains(string(lineBytes), startMessage) {
			f.showOutput = true
		}
		if len(lineBytes) >= len(endMessage) && strings.Contains(string(lineBytes), endMessage) {
			f.showOutput = false
		}
		if f.showOutput {
			lineBytes = append(lineBytes, '\n')
			copy(p, lineBytes)
			return len(lineBytes), nil
		}
	}
}
