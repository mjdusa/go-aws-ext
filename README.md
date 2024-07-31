# go-aws-ext

## Description

Go AWS extensions library

## Setting up for development

1. Clone Repository
```bash
git clone https://github.com/mjdusa/go-aws-ext
```

3. Setup Pre-commit Hooks
When you clone this repository to your workstation, make sure to install the [pre-commit](https://pre-commit.com/) hooks. [GitHub Repository](https://github.com/pre-commit/pre-commit)

* Installing tools
```bash
brew install pre-commit
```

* Check installed versions.
```bash
$ pre-commit --version
pre-commit 3.3.2
```

* Update configured pre-commit plugins.  Updates repository versions in .pre-commit-config.yaml to the latest.
```bash
pre-commit autoupdate
```

* Install pre-commit into the local instance of git.
```bash
pre-commit install --install-hooks
```

* Run pre-commit checks manually.
```bash
pre-commit run --all-files
```

## Maintaining, Housekeeping, Greenkeeping, etc

### Upgrade Go Version
```bash
go mod edit -go=<go_version> && go mod tidy
```

### Upgrade Dependency Versions
```bash
go get -u && go mod tidy
```

### Running GitHub Super-Linter Locally
```bash
docker run --rm -e RUN_LOCAL=true --env-file ".github/super-linter.env" -v $PWD:/tmp/lint github/super-linter:latest
```

### Running golangci-lint Locally
```bash
golangci-lint run --verbose --tests=true --config=.github/linters/.golangci.yml --issues-exit-code=0 --out-format=checkstyle
```
