package service

import (
	"github.com/QuantumNous/flowgate/setting/operation_setting"
	"github.com/QuantumNous/flowgate/setting/system_setting"
)

func GetCallbackAddress() string {
	if operation_setting.CustomCallbackAddress == "" {
		return system_setting.ServerAddress
	}
	return operation_setting.CustomCallbackAddress
}
