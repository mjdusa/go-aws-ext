package tools

import (
	"encoding/base64"
	"fmt"
	"os"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/secretsmanager"
	"github.com/aws/aws-sdk-go/service/secretsmanager/secretsmanageriface"
)

func wrapError(message string, err error) error {
	return fmt.Errorf("%s: %w", message, err)
}

// SmFactory is a Secrets Manager Factory for wrapping the underlying SecretsManager API.
type SmFactory struct {
	client secretsmanageriface.SecretsManagerAPI
}

// NewSecretsManagerFactory creates a factory for retreiving secrets from SecretsManager.
func NewSecretsManagerFactory(smclient secretsmanageriface.SecretsManagerAPI) SmFactory {
	return SmFactory{smclient}
}

func NewSmFactory() SmFactory {
	sess := session.Must(session.NewSession())

	region := os.Getenv("AWS_REGION")
	if len(region) <= 1 {
		panic("Missing required 'AWS_REGION' environment variable.")
	}

	return NewSecretsManagerFactoryWithRegion(sess, &region)
}

func NewSecretsManagerFactoryWithRegion(sess *session.Session, region *string) SmFactory {
	cfg := aws.NewConfig()

	cfg.Region = region

	return NewSecretsManagerFactoryWithConfig(sess, cfg)
}

func NewSecretsManagerFactoryWithConfig(sess *session.Session, cfg *aws.Config) SmFactory {
	secMgr := secretsmanager.New(sess, cfg)

	secMgrFactory := NewSecretsManagerFactory(secMgr)

	return secMgrFactory
}

// GetSecretString will retrieve a secret string SecretsManager.
func (s *SmFactory) GetSecretString(name string) (*string, error) {
	param := secretsmanager.GetSecretValueInput{ //nolint:exhaustruct // VersionId is optional and defaulted
		SecretId:     aws.String(name),
		VersionStage: aws.String("AWSCURRENT"), // VersionStage defaults to AWSCURRENT if unspecified
	}

	result, err := s.client.GetSecretValue(&param)
	if err != nil {
		return nil, wrapError("GetSecretValue error", err)
	}

	secret, decodeErr := decodeSecretValue(result)

	return secret, decodeErr
}

func decodeSecretValue(value *secretsmanager.GetSecretValueOutput) (*string, error) {
	if value.SecretString != nil {
		return value.SecretString, nil
	}

	decodedBinarySecretBytes := make([]byte, base64.StdEncoding.DecodedLen(len(value.SecretBinary)))

	decodedLength, err := base64.StdEncoding.Decode(decodedBinarySecretBytes, value.SecretBinary)
	if err != nil {
		return nil, wrapError("Decode error", err)
	}

	decodedBinarySecret := string(decodedBinarySecretBytes[:decodedLength])

	return &decodedBinarySecret, nil
}
