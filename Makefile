PKG_FILES?=$$(find . -name '*.go' |grep -v vendor)
PKG_NAME?=hello-world-app
REPO_NAME?=rawmind
IMAGE_NAME=${REPO_NAME}/${PKG_NAME}
VERSION=$$(sh scripts/version)
ANSWER_VERSION=$$(curl localhost:8080/version)
BUILDER_NAME=golang
BUILDER_VERSION=1.12.13-alpine
DOCKER_USER?=rawmind
DOCKER_PASS?=test

default: app

build: version fmtcheck vet lint
	CGO_ENABLED=0 go build -ldflags="-w -s -X main.VERSION=$(VERSION) -extldflags -static" -o $(PKG_NAME)

test: version fmtcheck
	@echo "==> Testing code ..."
	go test -cover -tags=test ${PACKAGES} -timeout=30s -parallel=4

vet:
	@echo "==> Checking that code complies with go vet requirements..."
	@go vet $$(go list ./... | grep -v vendor/) ; if [ $$? -eq 1 ]; then \
		echo ""; \
		echo "Vet found suspicious constructs. Please check the reported constructs"; \
		echo "and fix them if necessary before submitting the code for review."; \
		exit 1; \
	fi

lint:
	@echo "==> Checking that code complies with golint requirements..."
	@go get -u golang.org/x/lint/golint
	@if [ -n "$$(golint $$(go list ./...) | grep -v 'should have comment.*or be unexported' | tee /dev/stderr)" ]; then \
		echo ""; \
		echo "golint found style issues. Please check the reported issues"; \
		echo "and fix them if necessary before submitting the code for review."; \
    	exit 1; \
	fi

fmt:
	go fmt $(PKG_FILES)

fmtcheck:
	@echo "==> Checking that code complies with gofmt requirements..."
	@gofmt_files=$$(gofmt -l $(PKG_FILES))
	@if [ -n "${gofmt_files}" ]; then \
	    echo "gofmt needs running on the following files:"; \
	    echo "${gofmt_files}"; \
	    echo "You can use the command: \`make fmt\` to reformat code."; \
	    exit 1; \
	fi

version:
	@echo "==> Version ${VERSION}"

app: version
	@echo "==> Building app and docker image ${IMAGE_NAME}:${VERSION} ..."
	@docker build -t ${IMAGE_NAME}:${VERSION} -f package/Dockerfile.multistage .

apptest: version
	@echo "==> Testing docker image ${IMAGE_NAME}:${VERSION} ..." 
	@if [ -n "$$(docker ps -qf name=${PKG_NAME}-${VERSION} 2>&1 /dev/null)" ]; then \
		docker rm -fv ${PKG_NAME}-${VERSION} > /dev/null; \
	fi
	@docker run -td --name ${PKG_NAME}-${VERSION} ${IMAGE_NAME}:${VERSION} > /dev/null
	@if [ "$$(docker exec -it ${PKG_NAME}-${VERSION} curl -s localhost:8080/version 2>&1 /dev/null)" != "${VERSION}" ]; then \
		echo "==> ERROR: got version ${answer} expected ${VERSION} ..."; \
		docker rm -fv ${PKG_NAME}-${VERSION} > /dev/null; \
		exit 1; \
	fi
	@docker rm -fv ${PKG_NAME}-${VERSION} > /dev/null;

publish: apptest
	@echo "==> Publishing docker image ${IMAGE_NAME}:${VERSION} ..."
	@echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin
	@docker push ${IMAGE_NAME}:${VERSION}

.PHONY: build test vet fmt fmtcheck lint version image imagetest publish

