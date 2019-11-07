# Hello world app

hello-world-app web service in 8080 port used for training and/or testing. It simply shows data about k8s deployment info and http request headers. 

It also provides a `/version` uri to get the version of the app.

## Building from Source

To build `rawmind/hello-world-app` docker image, run `make app`.  

To use a custom Docker repository, do `DOCKER_USER=custom make image`, which produces a `custom/hello-world-app` image.

## Running Docker Image

### Docker

Run `docker run -td -p <PORT>:8080 rawmind/hello-world-app`.

## Generating K8s manifests

K8S manifests are generated under `/k8s` folder. App fqdn for ingress (default hello-world-app.test.dev) and app replica (default: 2) can be overriden setting `SERVICE_FQDN` and `SERVICE_REPLICA` env variables.

Run `make k8s_manifests`

### Deployment

Run `make k8s_deploy`

### Service

Run `make k8s_service`

### Ingress

Run `make k8s_ingress`

## License
Copyright (c) 2014-2018 [Rancher Labs, Inc.](http://rancher.com)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
