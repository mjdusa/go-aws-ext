GIT_REPO:=github.com/mjdusa/go-aws-ext
BRANCH:=$(shell git rev-parse --abbrev-ref HEAD)
COMMIT:=$(shell git log --pretty=format:'%H' -n 1)
BUILD_TS:=$(shell date -u "+%Y-%m-%dT%TZ")
BUILD_DIR:=dist
GO_VERSION:=$(shell go version | sed -r 's/go version go(.*)\ .*/\1/')
GOBIN:=${GOPATH}/bin

GOFLAGS = -a
LDFLAGS =
#GOCMD = GOPRIVATE='github.com/gdcorp-*' ; CGO_ENABLED='0' ; GO111MODULE='on' ; go
GOCMD = GOPRIVATE='github.com/gdcorp-*' ; GO111MODULE='on' ; go

LINTER_REPORT = $(BUILD_DIR)/golangci-lint-$(BUILD_TS).out
COVERAGE_REPORT = $(BUILD_DIR)/unit-test-coverage-$(BUILD_TS)

.PHONY: clean
clean:
	@echo "clean"
	rm -rf $(BUILD_DIR)
	go clean --cache

.PHONY: $(BUILD_DIR)
$(BUILD_DIR):
	mkdir -p $@

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
	ln -s $(shell pwd)/hooks/pre-commit $(shell pwd)/.git/hooks/pre-commit || true
endif

.PHONY: prebuild
prebuild: init $(BUILD_DIR)
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
	${GOPATH}/bin/golangci-lint --version
	${GOPATH}/bin/golangci-lint run --verbose --config .github/linters/.golangci.yml \
	  --issues-exit-code 0 --out-format=checkstyle > "$(LINTER_REPORT)"

.PHONY: lint
lint: installdep golangcilint

.PHONY: unittest
unittest: init $(BUILD_DIR)
	$(GOCMD) test -coverprofile="$(COVERAGE_REPORT).gcov" ./... && gcov2lcov -infile "$(COVERAGE_REPORT).gcov" -outfile "$(COVERAGE_REPORT).lcov"
	$(GOCMD) tool cover -func="$(COVERAGE_REPORT).gcov"
#	$(GOCMD) tool cover -html="$(COVERAGE_REPORT).gcov"
#	gcov2lcov -infile "$(COVERAGE_REPORT).gcov" -outfile "$(COVERAGE_REPORT).lcov"
#	cat "$(COVERAGE_REPORT).gcov"
#	cat "$(COVERAGE_REPORT).lcov"

.PHONY: racetest
racetest:
	$(GOCMD) test -race ./...

.PHONY: test
test: unittest racetest

.PHONY: all
all: clean $(BUILD_DIR) lint test
