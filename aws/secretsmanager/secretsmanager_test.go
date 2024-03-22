package tools_test

import (
	"context"
	"encoding/base64"
	"fmt"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/secretsmanager"
	tools "github.com/mjdusa/go-aws-ext/aws/secretsmanager"
	smmocks "github.com/mjdusa/go-aws-ext/aws/secretsmanager/mocks"
	"github.com/stretchr/testify/assert"
)

func CreateContext() context.Context {
	return context.Background()
}

func Test_NewSmFactory_Good(t *testing.T) {
	region := "us-west-2"
	t.Setenv("AWS_REGION", region)
	assert.NotPanics(t, func() { _ = tools.NewSmFactory() }, "NewSmFactory() should not Panic()")
	t.Setenv("AWS_REGION", "")
}

func Test_NewSmFactory_Panic(t *testing.T) {
	t.Setenv("AWS_REGION", "")
	assert.Panics(t, func() { _ = tools.NewSmFactory() }, "NewSmFactory() should Panic()")
}

func Test_NewSecretsManagerFactoryWithRegion_Good(t *testing.T) {
	sess := session.Must(session.NewSession())
	region := "us-west-2"

	assert.NotPanics(t, func() { _ = tools.NewSecretsManagerFactoryWithRegion(sess, &region) },
		"NewSecretsManagerFactoryWithRegion(...) should not Panic()")
}

func Test_NewSecretsManagerFactoryWithConfig_Good(t *testing.T) {
	sess := session.Must(session.NewSession())
	region := "us-west-2"
	cfg := aws.NewConfig()
	cfg.Region = &region

	assert.NotPanics(t, func() { _ = tools.NewSecretsManagerFactoryWithConfig(sess, cfg) },
		"NewSecretsManagerFactoryWithConfig(...) should not Panic()")
}

func Test_GetSecretString_GoodString(t *testing.T) {
	expected := "foobar"

	mockClient := smmocks.NewMockSMClient(&secretsmanager.GetSecretValueOutput{
		SecretString: aws.String(expected),
	}, nil)

	f := tools.NewSecretsManagerFactory(mockClient)

	actual, err := f.GetSecretString("foo")

	assert.Nil(t, err)
	assert.Equal(t, expected, *actual)
}

func Test_GetSecretString_DecodeError(t *testing.T) {
	badBytes := []byte{'f', 'o'}

	mockClient := smmocks.NewMockSMClient(&secretsmanager.GetSecretValueOutput{
		SecretBinary: badBytes,
	}, nil)

	f := tools.NewSecretsManagerFactory(mockClient)

	actual, err := f.GetSecretString("foo")

	assert.NotNil(t, err)
	assert.Equal(t, "Decode error: illegal base64 data at input byte 0", err.Error())
	assert.Nil(t, actual)
}

func Test_GetSecretString_GoodBinary(t *testing.T) {
	expected := "Here is a string...."

	originalSecretBinary := []byte(expected)
	encodedBinarySecretBytes := make([]byte, base64.StdEncoding.EncodedLen(len(originalSecretBinary)))
	base64.StdEncoding.Encode(encodedBinarySecretBytes, originalSecretBinary)
	mockClient := smmocks.NewMockSMClient(&secretsmanager.GetSecretValueOutput{
		SecretBinary: encodedBinarySecretBytes,
	}, nil)

	f := tools.NewSecretsManagerFactory(mockClient)

	actual, err := f.GetSecretString("foo")

	assert.Nil(t, err)
	assert.Equal(t, expected, *actual)
}

func Test_Nil_GetSecretString(t *testing.T) {
	mockClient := smmocks.NewMockSMClient(&secretsmanager.GetSecretValueOutput{
		Name:         nil,
		SecretBinary: nil,
		SecretString: nil,
	}, nil)

	f := tools.NewSecretsManagerFactory(mockClient)

	actual, err := f.GetSecretString("foo")

	assert.Nil(t, err)
	assert.Equal(t, "", *actual)
}

func Test_GetSecretString_Error(t *testing.T) {
	errMsg := "Oops"
	mockClient := smmocks.NewMockSMClient(nil, fmt.Errorf(errMsg))
	expectedErrorMessage := fmt.Sprintf("GetSecretValue error: %s", errMsg)

	f := tools.NewSecretsManagerFactory(mockClient)

	actual, err := f.GetSecretString("foo")

	assert.NotNil(t, err)
	assert.Equal(t, expectedErrorMessage, err.Error())
	assert.Nil(t, actual)
}
