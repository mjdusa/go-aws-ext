GIT_REPO:=github.com/mjdusa/go-aws-ext
BRANCH:=$(shell git rev-parse --abbrev-ref HEAD)
COMMIT:=$(shell git log --pretty=format:'%H' -n 1)
BUILD_TS:=$(shell date -u "+%Y-%m-%dT%TZ")
BUILD_DIR:=dist
GO_VERSION:=$(shell go version | sed -r 's/go version go(.*)\ .*/\1/')
GOBIN:=${GOPATH}/bin

GOFLAGS = -a
LDFLAGS =
GOCMD = go
GOCLEAN = $(GOCMD) clean
GOENV = $(GOCMD) env
GOTEST = $(GOCMD) test

LINTER_REPORT = $(BUILD_DIR)/golangci-lint-$(BUILD_TS).out
COVERAGE_REPORT = $(BUILD_DIR)/unit-test-coverage-$(BUILD_TS)

.PHONY: default
default: help

.PHONY: clean
clean:
	@echo "clean"
	rm -rf $(BUILD_DIR)
	$(GOCLEAN) --cache

.PHONY: $(BUILD_DIR)
$(BUILD_DIR):
	mkdir -p $@

.PHONY: installdep
installdep:
	./install-deps.sh

.PHONY: init
init:

.PHONY: prebuild
prebuild: init $(BUILD_DIR)
	@echo "Running $(GOCMD) mod tidy and $(GOCMD) mod vendor"
	@$(GOCMD) version
	@$(GOENV)
	@$(GOENV) -w GOPRIVATE=""
	@$(GOENV) -w CGO_ENABLED="0"
	@$(GOENV) -w GO111MODULE="on"
	@$(GOENV)
	@$(GOCMD) go mod tidy && $(GOCMD) go mod vendor

.PHONY: golangcilint
golangcilint: init
	@echo "Running golangci-lint"
	${GOPATH}/bin/golangci-lint --version
	${GOPATH}/bin/golangci-lint run --verbose --tests=true --config=.github/linters/.golangci.yml \
	  --issues-exit-code=0 --out-format=checkstyle > "$(LINTER_REPORT)"
	cat $(LINTER_REPORT)

.PHONY: lint
lint: $(BUILD_DIR) golangcilint

.PHONY: fuzz
fuzz: init
	$(GOTEST) -fuzz=Fuzz -fuzztime 30s ./...

.PHONY: race
race: init
	$(GOTEST) -race ./...

.PHONY: unit
unit: init $(BUILD_DIR)
	$(GOTEST) -coverprofile="$(COVERAGE_REPORT).gcov" ./... && gcov2lcov -infile "$(COVERAGE_REPORT).gcov" -outfile "$(COVERAGE_REPORT).lcov"
	$(GOCMD) tool cover -func="$(COVERAGE_REPORT).gcov"
#	$(GOCMD) tool cover -html="$(COVERAGE_REPORT).gcov"
	cat "$(COVERAGE_REPORT).gcov"
	cat "$(COVERAGE_REPORT).lcov"

.PHONY: tests
tests: unit race # fuzz

.PHONY: all
all: clean $(BUILD_DIR) lint tests

.PHONY: usage
usage:
	@echo "usage:"
	@echo "  make [command]"
	@echo "available commands:"
	@echo "  clean - clean up build artifacts"
	@echo "  help - show usage"
	@echo "  installdep - install latest build app dependancies  ie: golangci-lint, gcov2lcov"
	@echo "  lint - run all linter checks"
	@echo "  tests - run all tests  ie: fuzz, race, and unit"
	@echo "  fuzz - run all fuzz tests"
	@echo "  race - run all race tests"
	@echo "  unit - run all unit tests"
	@echo "  usage - show this information"

.PHONY: help
help: usage
