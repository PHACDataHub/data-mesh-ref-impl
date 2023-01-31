### Install Docker Engine and Docker Compose

The purpose of containerization - by Docker in this case - is to provide a secure, reliable, and lightweight runtime environment for applications that is consistent from host to host. In contrast, the purpose of serverless technology is to provide a way to build and run applications without having to consider the underlying hosts at all.

[Docker Engine](https://docs.docker.com) is an open source containerization technology for building and containerizing your applications. Docker Compose is a tool for defining and running multi-container Docker applications. With Compose, we can use a YAML file to configure our application’s services. Then, with a single command, we can create and start all the services from our configuration. Docker Compose works in all environments: production, staging, development, testing, as well as CI workflows. It also has commands for managing the whole lifecycle of your application:
+ Start, stop, and rebuild services
+ View the status of running services
+ Stream the log output of running services
+ Run a one-off command on a service

### A. Install Docker Engine and Docker Compose

To install Docker Engine and Docker Compose, run
```bash
./scripts/docker/install.sh
```

Make sure that Docker Engine is running
```bash
docker system info
```

Test if you can pull and run a `hell-world` Docker image
```bash
./scripts/docker/test.sh
```

### B. Cleanup Docker

In case if you need to cleanup previously Docker images, volumes, networks, containers, and folders
```bash
./scripts/docker/cleanup.sh
```

### C. Uninstall Docker

In case if you don't want Docker Engine and Docker Compose on your system any more.
```bash
./scripts/docker/uninstall.sh
```
Of course, you can reinstall Docker Engine and Docker Compose by running.
```bash
./scripts/docker/install.sh
```

*Note: do not install Docker over an existing installation, removing Docker where there is no installation, and other similar cases.*