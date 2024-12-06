# Kubernetes

## Running Puma in Kubernetes

In general running Puma in Kubernetes works as-is, no special configuration is needed beyond what you would write anyway to get a new Kubernetes Deployment going. There is one known interaction between the way Kubernetes handles pod termination and how Puma handles `SIGINT`, where some request might be sent to Puma after it has already entered graceful shutdown mode and is no longer accepting requests. This can lead to dropped requests during rolling deploys. A workaround for this is listed at the end of this article.

## Basic setup

Assuming you already have a running cluster and docker image repository, you can run a simple Puma app with the following example Dockerfile and Deployment specification. These are meant as examples only and are deliberately very minimal to the point of skipping many options that are recommended for running in production, like healthchecks and envvar configuration with ConfigMaps. In general you should check the [Kubernetes documentation](https://kubernetes.io/docs/home/) and [Docker documentation](https://docs.docker.com/) for a more comprehensive overview of the available options.

A basic Dockerfile example: 
```
FROM ruby:2.5.1-alpine # can be updated to newer ruby versions
RUN apk update && apk add build-base # and any other packages you need 

# Only rebuild gem bundle if Gemfile changes
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy over the rest of the files
COPY . .

# Open up port and start the service
EXPOSE 9292
CMD bundle exec rackup -o 0.0.0.0
```

A sample `deployment.yaml`:
```
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-awesome-puma-app
spec:
  selector:
    matchLabels:
      app: my-awesome-puma-app
  template:
    metadata:
      labels:
        app: my-awesome-puma-app
        service: my-awesome-puma-app
    spec:
      containers:
      - name: my-awesome-puma-app
        image: <your image here>
        ports:
        - containerPort: 9292
``` 

## Graceful shutdown and pod termination

For some high-throughput systems, it is possible that some HTTP requests will return responses with response codes in the 5XX range during a rolling deploy to a new version. This is caused by [the way that Kubernetes terminates a pod during rolling deploys](https://cloud.google.com/blog/products/gcp/kubernetes-best-practices-terminating-with-grace):

1. The replication controller determines a pod should be shut down.
2. The Pod is set to the “Terminating” State and removed from the endpoints list of all Services, so that it receives no more requests.
3. The pods pre-stop hook get called. The default for this is to send `SIGTERM` to the process inside the pod.
4. The pod has up to `terminationGracePeriodSeconds` (default: 30 seconds) to gracefully shut down. Puma will do this (after it receives SIGTERM) by closing down the socket that accepts new requests and finishing any requests already running before exiting the Puma process.
5. If the pod is still running after `terminationGracePeriodSeconds` has elapsed, the pod receives `SIGKILL` to make sure the process inside it stops. After that, the container exits and all other Kubernetes objects associated with it are cleaned up.

There is a subtle race condition between step 2 and 3: The replication controller does not synchronously remove the pod from the Services AND THEN call the pre-stop hook of the pod, but rather it asynchronously sends "remove this pod from your endpoints" requests to the Services and then immediately proceeds to invoke the pods' pre-stop hook. If the Service controller (typically something like nginx or haproxy) receives this request handles this request "too" late (due to internal lag or network latency between the replication and Service controllers) then it is possible that the Service controller will send one or more requests to a Puma process which has already shut down its listening socket. These requests will then fail with 5XX error codes.

The way Kubernetes works this way, rather than handling step 2 synchronously, is due to the CAP theorem: in a distributed system there is no way to guarantee that any message will arrive promptly. In particular, waiting for all Service controllers to report back might get stuck for an indefinite time if one of them has already been terminated or if there has been a net split. A way to work around this is to add a sleep to the pre-stop hook of the same time as the `terminationGracePeriodSeconds` time. This will allow the Puma process to keep serving new requests during the entire grace period, although it will no longer receive new requests after all Service controllers have propagated the removal of the pod from their endpoint lists. Then, after `terminationGracePeriodSeconds`, the pod receives `SIGKILL` and closes down. If your process can't handle SIGKILL properly, for example because it needs to release locks in different services, you can also sleep for a shorter period (and/or increase `terminationGracePeriodSeconds`) as long as the time slept is longer than the time that your Service controllers take to propagate the pod removal. The downside of this workaround is that all pods will take at minimum the amount of time slept to shut down and this will increase the time required for your rolling deploy.

More discussions and links to relevant articles can be found in https://github.com/puma/puma/issues/2343.
