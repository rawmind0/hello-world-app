PKG_FILES?=$$(find . -name '*.go' |grep -v vendor)
SERVICE_NAME?=hello-world-app
SERVICE_FQDN?=${SERVICE_NAME}.test.dev
SERVICE_REPLICA?=2
VERSION=$$(sh scripts/version)
ANSWER_VERSION=$$(curl localhost:8080/version)
BUILDER_NAME=golang
BUILDER_VERSION=1.12.13-alpine
DOCKER_USER?=rawmind
DOCKER_PASS?=test
IMAGE_NAME=${DOCKER_USER}/${SERVICE_NAME}:${VERSION}
K8S_DEPLOYMENT=k8s/${SERVICE_NAME}-deployment.yaml
K8S_SERVICE=k8s/${SERVICE_NAME}-service.yaml
K8S_INGRESS=k8s/${SERVICE_NAME}-ingress.yaml

default: app

build: version fmtcheck vet lint
	CGO_ENABLED=0 go build -ldflags="-w -s -X main.VERSION=$(VERSION) -extldflags -static" -o $(SERVICE_NAME)

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
	@echo "==> Building app and docker image ${IMAGE_NAME} ..."
	@docker build -t ${IMAGE_NAME} -f package/Dockerfile.multistage .

apptest: version
	@echo "==> Testing docker image ${IMAGE_NAME} ..." 
	@if [ -n "$$(docker ps -qf name=${SERVICE_NAME}-${VERSION})" ]; then \
		docker rm -fv ${SERVICE_NAME}-${VERSION} > /dev/null; \
	fi
	@docker run -td --name ${SERVICE_NAME}-${VERSION} ${IMAGE_NAME} > /dev/null
	@if [ "$$(docker exec -it ${SERVICE_NAME}-${VERSION} curl -s localhost:8080/version 2>&1 /dev/null)" != "${VERSION}" ]; then \
		echo "==> ERROR: got version ${answer} expected ${VERSION} ..."; \
		docker rm -fv ${SERVICE_NAME}-${VERSION} > /dev/null; \
		exit 1; \
	fi
	@docker rm -fv ${SERVICE_NAME}-${VERSION} > /dev/null;

publish: apptest
	@echo "==> Publishing docker image ${IMAGE_NAME} ..."
	@echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin
	@docker push ${IMAGE_NAME}

k8s_deploy: k8s_manifests
	@echo "==> Generating k8s deployment file ${K8S_DEPLOYMENT} ..."
	@kubectl apply -f ${K8S_DEPLOYMENT}
	@kubectl apply -f ${K8S_SERVICE}
	@kubectl apply -f ${K8S_INGRESS}

k8s_manifests: k8s_deploy k8s_service k8s_ingress

k8s_deployment: 
	@echo "==> Generating k8s deployment file ${K8S_DEPLOYMENT} ..."
	@SERVICE_REPLICA=${SERVICE_REPLICA} IMAGE_NAME=${IMAGE_NAME} scripts/build_k8s_deployment > ${K8S_DEPLOYMENT}

k8s_service: 
	@echo "==> Generating k8s service file ${K8S_SERVICE} ..." 
	@scripts/build_k8s_service > ${K8S_SERVICE}

k8s_ingress: 
	@echo "==> Generating k8s ingress file ${K8S_INGRESS} ..."
	@SERVICE_FQDN=${SERVICE_FQDN} scripts/build_k8s_ingress > ${K8S_INGRESS}

.PHONY: build test vet fmt fmtcheck lint version image imagetest publish k8s_manifests k8s_deploy

