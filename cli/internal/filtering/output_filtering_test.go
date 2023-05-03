package filtering

import (
	"bytes"
	"io"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func mustReadFile(t *testing.T, filename string) []byte {
	t.Helper()
	b, err := os.ReadFile(filename)
	if err != nil {
		t.Fatal(err)
	}
	return b
}

func TestFilterGLuaTestOutput(t *testing.T) {
	input := mustReadFile(t, "testdata/testfail_1.txt")
	expected := mustReadFile(t, "testdata/testfail_1_expected_output.txt")

	output := FilterGLuaTestOutput(io.NopCloser(bytes.NewReader(input)))
	outputdata, _ := io.ReadAll(output)

	assert.Equal(t, string(expected), string(outputdata))
}
