# Container Intro

Containers refer to a lightweight, portable, and self-sufficient unit of
software that puts together code and all its dependencies so one can run an
application/service.

Virtual machine (VM)s virtualize the underlying hardware so that multiple
operating system (OS) instances can run on that hardware. Each VM runs an OS and
has access to virtualized resources representing the underlying hardware. On the
other hand, a container virtualizes the underlying OS and causes the
containerized app to perceive that it has the OS—including CPU, memory, file
storage, and network connections—all to itself. Besides, containers share the
host OS, so they do not need to boot an OS. So contenarized applications can
start much faster.

There are several container runtimes available, including
[Docker](https://www.docker.com/), [Podman](https://podman.io/),
[containerd](https://containerd.io/), [Apptainer
(Singularity)](https://apptainer.org/).

### Quick docker example

Here we assume you have docker install on your machine (e.g. on macos: `brew
install --cask docker` or install it by going to the docker
[website](https://www.docker.com/)).

Once installed you can run

```
$ docker run hello-world
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

```
$ docker images
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
hello-world   latest    74cc54e27dc4   4 months ago   10.1kB
```

You can create your own image. (files: [folder](https://github.com/marconetto/technotes/tree/main/docs/containers/containerintro/))
)

Create `app.py` with this content:

```
# app.py
print("Hello, world from Docker!")
```

Create this `Dockerfile`:


```dockerfile title="Dockerfile"
--8<-- "docs/containers/containerintro/Dockerfile"
```

Run:

```
$ docker build -t hello-python .
$ docker run hello-python
Hello, world from Docker!
```

```
$ docker images
REPOSITORY     TAG       IMAGE ID       CREATED          SIZE
hello-python   latest    e8cc71bba03c   45 seconds ago   124MB
hello-world    latest    74cc54e27dc4   4 months ago     10.1kB
```


### Quick podman example

[Podman](https://podman.io/docs/installation) has basically the same syntax then docker. However, docker does not have
a daemon as a requirement.

Install it:

```
brew install podman
```
Start the VM (required in macos; for linux you don't need that)

```
podman machine init
podman machine start
```

Then you can do the same commands as described in the docker section above. For
instance:

```
$ podman run hello-world
Resolved "hello-world" as an alias (/etc/containers/registries.conf.d/000-shortnames.conf)
Trying to pull quay.io/podman/hello:latest...
Getting image source signatures
Copying blob sha256:81df7ff16254ed9756e27c8de9ceb02a9568228fccadbf080f41cc5eb5118a44
Copying config sha256:5dd467fce50b56951185da365b5feee75409968cbab5767b9b59e325fb2ecbc0
Writing manifest to image destination
!... Hello Podman World ...!
```

You can check the podman VM running:

```
$ podman machine list
NAME                     VM TYPE     CREATED        LAST UP            CPUS        MEMORY      DISK SIZE
podman-machine-default*  applehv     4 minutes ago  Currently running  4           2GiB        100GiB
```

You can turn it off:

```
podman machine stop
```


## Other notes


If you want to get into a container image to explore file system for instance:

```
docker run -it --rm <myimage> bash
```

```
-it: interactive terminal
--rm: remove container on exit
<myimage>: use the image your original container used
```

You can check the content of a file in the image for instance:

```
docker run -it --rm hello-python cat /app/app.py
```

If you want to get into a running container:

```
docker exec -it <mycontainer> bash
```

Or just check something there:

```
docker exec -it <mycontainer> ls /app
```

## Linux

In Linux, docker may fail because it says the daemon: "docker: permission denied
while trying to connect to the Docker daemon socket"

By default, Docker runs as a root-owned service. To manage Docker as a non-root
user, your user needs to be part of the docker group. This allows you to run
Docker commands without needing sudo. Add user to docker group:

```
sudo usermod -aG docker $USER
```
