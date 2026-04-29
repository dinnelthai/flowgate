package service

import (
	"strings"

	"github.com/QuantumNous/flowgate/constant"
)

func CoverTaskActionToModelName(platform constant.TaskPlatform, action string) string {
	return strings.ToLower(string(platform)) + "_" + strings.ToLower(action)
}
