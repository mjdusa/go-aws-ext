#!/bin/bash

GOBIN=${GOPATH}/bin

echo ""
echo "Checking ${GOBIN}/golangci-lint"
if [ ! -f "${GOBIN}/golangci-lint" ]; then
	echo "Installing ${GOBIN}/golangci-lint"
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
else
	echo "${GOBIN}/golangci-lint already installed."
fi

echo ""
echo "Checking ${GOBIN}/gcov2lcov"
if [ ! -f "${GOBIN}/gcov2lcov" ]; then
	echo "Installing ${GOBIN}/gcov2lcov"
	go install github.com/jandelgado/gcov2lcov@latest
else
	echo "${GOBIN}/gcov2lcov already installed."
fi

echo ""
echo "Checking pre-commit"
if [ ! -f "$(which pre-commit)" ]; then
	echo "Brew installing pre-commit"
	brew install pre-commit || true
else
	echo "pre-commit already installed."
fi

if [ -f "$(which pre-commit)" ]; then
	echo "Checking $(pwd)/.git/hooks/pre-commit"
	if [ ! -f "$(pwd)/.git/hooks/pre-commit" ]; then
		echo "Installing pre-commit hook to $(pwd)/.git/hooks/pre-commit"
		pre-commit install
	else
		echo "$(pwd)/.git/hooks/pre-commit already installed."
	fi
else
	echo "pre-commit install failed."
fi

echo ""
