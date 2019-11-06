Hello world app
===============

hello-world-app web service in 8080 port used for training and/or testing. It simply shows data about k8s deployment info and http request headers. 

It also provides a `/version` uri to get the version of the app.

## Building from Source

To build `rawmind/hello-world-app` docker image, run `make app`.  To use a custom Docker repository, do `REPO_NAME=custom make image`, which produces a `custom/hello-world-app` image.

## Running Docker Image

### Docker

Run `docker run -td -p <PORT>:8080 rawmind/hello-world-app`.

### K8s

Deployment manifest
```
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  labels:
    app: hello-world-app
  name: hello-world-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-world-app
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: hello-world-app
    spec:
      containers:
      - image: rawmind/hello-world-app
        imagePullPolicy: Always
        name: hello-world
        ports:
        - name: http-port
          containerPort: 8080
          protocol: TCP
        env:
        - name: MY_NODE_IP
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: status.hostIP
        livenessProbe:
          tcpSocket:
            port: http-port
          initialDelaySeconds: 15
          periodSeconds: 20
        readinessProbe:
          httpGet:
            path: /
            port: http-port
          initialDelaySeconds: 15
          periodSeconds: 20
---
apiVersion: v1
kind: Service
metadata:
  name: hello-world-app
  namespace: default
spec:
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: hello-world-app
  type: NodePort
```

Run `kubectl apply -f <DEPLOY_MANIFEST>`

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
