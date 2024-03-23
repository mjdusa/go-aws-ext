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

if [ ! -f "$(pwd)/.git/hooks/pre-commit" ] && [ -f "$(pwd)/hooks/pre-commit" ]; then
	echo "Adding pre-commit hook to $(pwd)/.git/hooks/pre-commit"
	ln -s "$(pwd)/hooks/pre-commit" "$(pwd)/.git/hooks/pre-commit" || true
fi
