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
	testCases := []struct {
		name     string
		input    []byte
		expected []byte
	}{
		{
			name:     "test failed",
			input:    mustReadFile(t, "testdata/testfail_1.txt"),
			expected: mustReadFile(t, "testdata/testfail_1_expected_output.txt"),
		},
		{
			name:     "bad gamemode",
			input:    mustReadFile(t, "testdata/testbadgamemode_2.txt"),
			expected: mustReadFile(t, "testdata/testbadgamemode_2_expected_output.txt"),
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			output := FilterGLuaTestOutput(io.NopCloser(bytes.NewReader(tc.input)))
			outputdata, _ := io.ReadAll(output)

			assert.Equal(t, string(tc.expected), string(outputdata))
		})
	}
}
