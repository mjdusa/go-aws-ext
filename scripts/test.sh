#!/usr/bin/env bash

# Run the test and coverage reports. May be run locally and is used by the Jenkinsfile.
# To run locally, set TESTSPACE in your environment to the root directory of the git repo.
# For example, when running directly in the repo root:
#   TESTSPACE=$(pwd) bash build/test.sh

set -e

source "$(dirname "$0")/common.sh"
: ${WORKSPACE:?}

cd $WORKSPACE/src/$REPONAME

mkdir -p ./reports

echo "Updating go-junit-report ..."
go install github.com/jstemmer/go-junit-report/v2@latest

echo "Updating gocover-cobertura ..."
go install github.com/t-yuki/gocover-cobertura@latest

echo "Running tests ..."
go test -v ./... 2>&1 | ${WORKSPACE}/bin/go-junit-report > reports/junit_results.xml

echo "Generating coverage report ..."
go test -coverprofile=reports/cover.out ./...
${WORKSPACE}/bin/gocover-cobertura < reports/cover.out > reports/cobertura-coverage.xml

echo "Running linter ..."
linterbin=$(go env GOPATH)/bin
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $linterbin
$linterbin/golangci-lint run --issues-exit-code 0 --out-format checkstyle > reports/checkstyle-result.xml
