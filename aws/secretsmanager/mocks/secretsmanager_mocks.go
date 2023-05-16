package mocks

import (
	"github.com/aws/aws-sdk-go/service/secretsmanager"
	"github.com/aws/aws-sdk-go/service/secretsmanager/secretsmanageriface"
)

type mockSMClient struct {
	secretsmanageriface.SecretsManagerAPI
	Response *secretsmanager.GetSecretValueOutput
	Error    error
}

func NewMockSMClient(resp *secretsmanager.GetSecretValueOutput,
	err error) mockSMClient { //nolint:revive // use only with mock
	return mockSMClient{ //nolint:exhaustruct // mockSMClient is a mock for testing only
		Response: resp,
		Error:    err,
	}
}

func (m mockSMClient) GetSecretValue(*secretsmanager.GetSecretValueInput) (
	*secretsmanager.GetSecretValueOutput, error) {
	return m.Response, m.Error
}
