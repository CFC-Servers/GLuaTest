package filtering

import (
	"bufio"
	"io"
	"regexp"
)

type GLuaTestFilter struct {
	in         io.ReadCloser
	scanner    *bufio.Scanner
	showOutput bool
	buffer     []byte
}

func FilterGLuaTestOutput(in io.ReadCloser) io.ReadCloser {
	scanner := bufio.NewScanner(in)
	return &GLuaTestFilter{in: in, scanner: scanner}
}

func (f *GLuaTestFilter) Close() error {
	return f.in.Close()
}

const (
	actionTypeOutputRaw = iota
	actionTypeEnableOutput
	actionTypeDisableOutput
)

type filterAction struct {
	pattern *regexp.Regexp
	action  int
}

var outputMessages = []filterAction{
	{regexp.MustCompile(`Error loading gamemode!$`), actionTypeOutputRaw},
	{regexp.MustCompile(`: Server restart in 10 seconds`), actionTypeOutputRaw},
	{regexp.MustCompile(`\[GLuaTest\]\: Test run starting...$`), actionTypeEnableOutput},
	{regexp.MustCompile(`\[GLuaTest\]\: Test run complete!$`), actionTypeDisableOutput},
}

func (f *GLuaTestFilter) Read(p []byte) (int, error) {
	if len(f.buffer) == 0 {
		if !f.readNextLine() {
			return 0, io.EOF
		}
	}

	n := copy(p, f.buffer)
	f.buffer = f.buffer[n:]
	return n, nil
}

func (f *GLuaTestFilter) applyFilters(lineBytes []byte) bool {
	showOutputThisLine := f.showOutput
	for _, action := range outputMessages {
		if f.showOutput && action.action == actionTypeEnableOutput {
			continue
		}
		if !f.showOutput && action.action == actionTypeDisableOutput {
			continue
		}
		if !action.pattern.Match(lineBytes) {
			continue
		}

		switch action.action {
		case actionTypeEnableOutput:
			f.showOutput = true
			showOutputThisLine = false
		case actionTypeDisableOutput:
			f.showOutput = false
			showOutputThisLine = false
		case actionTypeOutputRaw:
			showOutputThisLine = true
		}
		break

	}
	return showOutputThisLine
}

func (f *GLuaTestFilter) readNextLine() bool {
	for f.scanner.Scan() {
		lineBytes := f.scanner.Bytes()

		shouldShow := f.applyFilters(lineBytes)
		if shouldShow {
			lineBytes = append(lineBytes, '\n')
			f.buffer = lineBytes
			return true
		}
	}
	return false
}
