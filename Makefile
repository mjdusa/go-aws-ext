GIT_REPO:=github.com/mdonahue-godaddy/go-aws-ext
BRANCH:=$(shell git rev-parse --abbrev-ref HEAD)
COMMIT:=$(shell git log --pretty=format:'%h' -n 1)
BUILD_TS:=$(shell date -u "+%Y-%m-%dT%TZ")
APP_NAME:=example
#APP_VERSION:=$(shell git describe --tags)
APP_VERSION:=$(shell cat .version)
GO_VERSION:=$(shell go version | sed -r 's/go version go(.*)\ .*/\1/')
GOBIN:=${GOPATH}/bin

GOFLAGS:=" GOPRIVATE='github.com/gdcorp-*' ; "
GOFLAGS+=" CGO_ENABLED='0' ; "
GOFLAGS+=" GO111MODULE='on' ; "

GOCMD:=$(GOFLAGS) go

LINTER_REPORT:="golangci-lint-$(BUILD_TS).out"
COVERAGE_REPORT="unit-test-coverage-$(BUILD_TS)"

.PHONY: installdep
installdep:
ifeq (,$(wildcard $(GOBIN)/golangci-lint))
	@echo "Installing golangci-lint..."
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
else
	@echo "$(GOBIN)/golangci-lint detected, skipping install."
endif
ifeq (,$(wildcard $(GOBIN)/gcov2lcov))
	@echo "Installing gcov2lcov..."
	go install github.com/jandelgado/gcov2lcov@latest
else
	@echo "$(GOBIN)/gcov2lcov detected, skipping install."
endif

.PHONY: init
init: installdep
ifeq (,$(wildcard ./.git/hooks/pre-commit))
	@echo "Adding pre-commit hook to .git/hooks/pre-commit"
	@ln -s $(shell pwd)/hooks/pre-commit $(shell pwd)/.git/hooks/pre-commit || true
endif

.PHONY: setup
setup: init
	@echo "git init"
	@git init

.PHONY: clean
clean:
	@echo "clean"
	@rm -f *.out *.gcov *.lcov $(APP_NAME)
	@go clean --cache

.PHONY: prebuild
prebuild: clean
	@echo "Running go mod tidy & vendor"
	@go version
	@go env
	@go env -w GOPRIVATE="github.com/gdcorp-*"
	@go env -w CGO_ENABLED="0"
	@go env -w GO111MODULE="on"
	@go env
	@$(GOFLAGS) go mod tidy && $(GOFLAGS) go mod vendor

.PHONY: golangcilint
golangcilint: init
	@echo "Running golangci-lint"
	@${GOPATH}/bin/golangci-lint  --version
	@${GOPATH}/bin/golangci-lint  run --verbose > "$(LINTER_REPORT)"

.PHONY: lint
lint: installdep golangcilint

.PHONY: unittest
unittest: init
	@echo "go test -coverprofile=\"$(COVERAGE_REPORT).gcov\" ./..."
	@go test -coverprofile="$(COVERAGE_REPORT).gcov" ./... && gcov2lcov -infile "$(COVERAGE_REPORT).gcov" -outfile "$(COVERAGE_REPORT).lcov"
	@go tool cover -func="$(COVERAGE_REPORT).gcov"
#	@go tool cover -html="$(COVERAGE_REPORT).gcov"
#	@cat "$(COVERAGE_REPORT).gcov"
#	@cat "$(COVERAGE_REPORT).lcov"

.PHONY: racetest
racetest:
	@echo "go test -race ./..."
	@go test -race ./...

.PHONY: test
test: unittest racetest

.PHONY: all
all: clean lint test
