---
layout: post
title:  "Best practises of deploying apps to kubernetes"
date:   2022-10-15 22:00:00 +0700
categories:
tags: Kubernetes Microservices
---

![Perfection](/images/articles/kubernetes-best-practises/perfection.jpg)

### Must have

- stateless app and whole container (no volumes needed)
- one container = one service
- There is no way when container is up, but the app is down and not launching.
- Ensure that you are allowed to use all app dependencies (check licenses)
- Ingress is used. All TLS termination is done on ingress.
- The docker image must have explicit version (not "latest")

### Less image size

- small docker base image (i. e. alpine)
- multi-stage Dockerfile (in case of it is needed)
- all big static data (images, videos, sounds, etc) is out of container.

### Security

- all processes are launched by not root user
- Container doesn't include vulnerabilities that are excluded by current politics (sometimes the politics are quite strict, for example for medical applications)
- no sensitive data inside container. All sensitive data must be in kubernetes secrets.

### Durability

- CPU and memory limits must be set.

### Observability

- Logs are published to console (not to some file inside container)
- All probes are implemented and set: livelinessProbe, readinessProbe, startupProbe
- The app and container must produce at least important metrics.

### Good style

- Cron tasks are managed by kubernetes cronjob
- Configurations are excluded from container to configMap kubernetes.