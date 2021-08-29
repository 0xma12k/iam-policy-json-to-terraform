.PHONY: build test clean fmt fmtcheck tools test-readme
.DEFAULT_GOAL := help
export GOFLAGS = -mod=readonly

build: test iam-policy-json-to-terraform_amd64 iam-policy-json-to-terraform_alpine iam-policy-json-to-terraform_darwin iam-policy-json-to-terraform_darwin_arm iam-policy-json-to-terraform.exe ## Test and build the whole application

clean: ## Remove build artifacts
	rm -f *_amd64 *_darwin *_alpine *.exe
	rm -rf vendor
	rm -f web/web.js*
	rm -rf web/node_modules
	rm -rf web/screenshots

test: fmtcheck seccheck **/*.go ## Run all tests
	go test -v ./...
	golint -set_exit_status ./converter
	golint -set_exit_status .
	go vet ./...

fmt: **/*.go ## Format code
	go fmt ./...

tools: tools-main tools-web ## Install additional required tooling

tools-web: ## Install additional required tooling for the web version
	test -z "${NO_TOOLS_WEB}" && (cd web && npm install) || echo "skipping tools web because of environment variable (only for testing readme)"

tools-main:  ## Install additional required tooling for the main version
	go list -f '{{range .Imports}}{{.}} {{end}}' tools.go | xargs go install

iam-policy-json-to-terraform_amd64: **/*.go
	 GOOS=linux GOARCH=amd64 CGO_ENABLED=1 go build -o $@

iam-policy-json-to-terraform_alpine: **/*.go
	 GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o $@

iam-policy-json-to-terraform_darwin: **/*.go
	GOOS=darwin GOARCH=amd64 go build -o $@

iam-policy-json-to-terraform_darwin_arm: **/*.go
	GOOS=darwin GOARCH=arm64 go build -o $@

iam-policy-json-to-terraform.exe: **/*.go
	GOOS=windows GOARCH=amd64 go build -o $@

fmtcheck: **/*.go ## Run linter
	@gofmt_files=$$(gofmt -l `find . -name '*.go' | grep -v vendor`); \
    if [ -n "$${gofmt_files}" ]; then \
        echo 'gofmt needs running on the following files:'; \
        echo "$${gofmt_files}"; \
        echo "You can use the command: \`make fmt\` to reformat code."; \
        exit 1; \
    fi; \
    exit 0

seccheck: **/*.go ## Run security checks
	gosec -exclude G104 ./...

test-readme: README.md scripts/test-readme.sh ## Run the commands mentioned in the README for sanity-checking
	scripts/test-readme.sh

web-serve: web/*
	cd web && gopherjs serve github.com/flosell/iam-policy-json-to-terraform/web/

web-build: web/*.go
	cd web && gopherjs build --minify

web-e2e: web/*.go web/*.js
	cd web && npm test

help:
	@grep -h -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' | sort
