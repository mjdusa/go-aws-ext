#!/bin/bash

GOBIN=${GOPATH}/bin

if [ ! -f "${GOBIN}/golangci-lint" ]; then
	echo "Installing ${GOBIN}/golangci-lint"
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
fi

if [ ! -f "${GOBIN}/gcov2lcov" ]; then
	echo "Installing ${GOBIN}/gcov2lcov"
	go install github.com/jandelgado/gcov2lcov@latest
fi

if [ ! -f "$(which pre-commit)" ]; then
	echo "Brew installing pre-commit"
	brew install pre-commit || true
fi

if [ -f "$(which pre-commit)" ]; then
	echo "pre-commit=[$(which pre-commit)]"
	if [ ! -f "$(pwd)/.git/hooks/pre-commit" ]; then
		echo "Installing pre-commit hook to $(pwd)/.git/hooks/pre-commit"
		pre-commit install
	fi
fi
