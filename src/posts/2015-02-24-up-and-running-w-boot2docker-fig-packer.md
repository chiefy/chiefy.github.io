---
layout: post.swig
title: Up & Running With boot2docker, Fig (now docker-compose) and Packer on OSX
date: 2015-02-24 12:00:00
tags:
  - docker
  - boot2docker
  - devops
  - fig
  - packer
  - OSX
  - Darwin
---

Recently my job has been focusing a bit more on the devops side of things and I have been trying to learn and use docker via boot2docker on OSX. During the process I kept wishing that someone had written about some of the issues I was running into such that I could easily letmegooglethatforyou or SO the answers in a non day-killing manner. Please keep in mind that this stuff moves extremely fast (or slow depending on the project), so be sure to check out the issue links and check on the status before yelling at me that it's already been fixed.

## boot2docker

> [boot2docker](http://boot2docker.io/) is a lightweight Linux distribution based on Tiny Core Linux made specifically to run Docker containers. It runs completely from RAM, weighs ~27MB and boots in ~5s (YMMV).

In case you aren't aware, or you've been living under a devops rock, [Docker](http://docker.io) is the new hotness in virtualization and container technology. I'm not going to get into it here, but there are a zillion posts around the interwebs describing what it is, and what it can help you accomplish.

Because Docker requires a specific Linux Kernel, [you can't use Docker exclusively with Darwin/OSX](https://docs.docker.com/installation/mac/), you must use a proxy VM to manage your Docker images and containers. This is where boot2docker comes in.

So instead of having to ssh into a VM and manage your Docker images and containers (potentially a pretty big PITA), boot2docker provides a proxy layer, so you can use docker commands in your local shell just as if you were the docker host. At the time of writing here are versions of these programs I was using:

```
$ docker --version && boot2docker version && uname -a
Docker version 1.5.0, build a8a31ef
Boot2Docker-cli version: v1.5.0
Git commit: ccd9032
Darwin cnaje1ML1 13.4.0 Darwin Kernel Version 13.4.0: Wed Dec 17 19:05:52 PST 2014; root:xnu-2422.115.10~1/RELEASE_X86_64 x86_64
```

Along with this great convenience, comes more complexity, and with more complexity, comes various issues when trying to use Docker-dependent programs and utilities.

### Some Important `boot2docker` Commands

```
$ boot2docker init && boot2docker up
```

To get things started, you will need to create/init the boot2docker VM, and then actually start the instance.

See-also: `boot2docker save`, `boot2docker down`, `boot2docker restart` etc. which will manage the state of your VM.

```
$ boot2docker ip
```

When you use boot2docker, it spawns a new VM instance through VirtualBox. This new VM exposes it's network interface, and if you will be creating any Docker containers which expose network services (you proabbly will), you need to know the VM's IP address in order to interface with them. The `ip` command, like it's name implies, simply prints out the IP address assigned to the VM.

```
$ boot2docker shellinit
```

To get your shell setup properly, you will need to run `shellinit` at some point (obviously after you have `boot2docker up`).

Depending on how your shell is setup, it might be handy to add this to your `.bashrc` or `.zshrc`:

```
#!/bin/zsh
...
boot2docker shellinit && export DOCKER_IP=$(boot2docker ip)
...
```

## Fig (or *docker-compose*)

> Fast, isolated development environments using Docker.

When you are developing an application using docker containers, you are going to need something to help you orchestrate containers. There are plenty of great write-ups on using Fig, so I will not go into that here. Fig (or `docker-compose`) is a great orchestration toolset and was [recently purchased by Docker](http://venturebeat.com/2014/07/22/docker-buys-orchard-a-2-man-startup-with-a-cloud-service-for-running-docker-friendly-apps/). Funny story: since I wrote this about a week ago, it's now known as `docker-compose`.

```
$ fig --version
fig 1.0.1
```

#### Shared Data Volumes

One of the first issues I ran into using fig and boot2docker was the issue of mounting writable shared volumes with the volumes_from config. The problem is that when boot2docker mounts volumes, it uses vboxfs, and causes several problems when the host container tries to write or change permissions to the shared volume.

If you are interested, there are various [threads](https://github.com/docker/docker/issues/4023) on [issues](https://github.com/boot2docker/boot2docker/issues/587#issuecomment-66935011) relating to boot2docker / vboxfs / shared volumes / permissions etc. It's actually a lot to sort through, and I spent a few days trying to find a solution to the issue I was running into.

I ended up using GitHub user [@paolomainardi](https://github.com/paolomainardi)'s solution to nix using VirtualBox's vboxfs and [instead expose folders via NFS](https://github.com/boot2docker/boot2docker/issues/587#issuecomment-66935011).

First, modify `/etc/exports`:

```
/Users -mapall=[youruser]:[yourgroup] [boot2dockerip]
```

After you save, you  may or may not need to sudo /sbin/nfsd restart to restart the NFS daemon in OSX to pick up the changes.

Then `boot2docker ssh` into your VM, and run the following:

```
sudo umount /Users
sudo /usr/local/etc/init.d/nfs-client start
sudo mount 192.168.59.3:/Users /Users -o rw,async,noatime,rsize=32768,wsize=32768,proto=tcp
```

Now when you need your `Dockerfile` to change permissions on files mounted via data volumes, it should take. This approach also helps another issue I ran into while running `packer`.

### Dangling images, or, dockerberries

One thing you'll notice when you start working with Fig is that you will start generating a lot of intermediate images that for whatever reason, don't get cleaned up by fig clean. I have a feeling that [the next release of docker will include a command to do this](https://github.com/docker/docker/issues/928), but for now to remedy this, you can [try this tip](https://www.calazan.com/docker-cleanup-commands/):

```
$ docker rmi $(docker images -q -f dangling=true)
```

or to force cleanup:

```
$ docker rmi -f $(docker images -q -f dangling=true)
```

even better add this to your aliases:

```
alias docker_clean_danglers="docker rmi -f $(docker images -q -f dangling=true)"
```

## Packer

> [Packer](http://packer.io) is a tool for creating identical machine images for multiple platforms from a single source configuration.

Packer is a great utility, from HashiCorp, the makers of [Vagrant](http://vagrantup.com), to use configuration files to generate multiple images for different services such as: Amazon EC2, Docker and Vagrant. Need to generate an Amazon AMI, but also want a Docker image you can use elsewhere or push to a registry? Packer is the tool for the job.

I quickly ran into a weird issue running `packer build` using a shell provisioner with `inline`. My builder would start, and then mysteriously just sit there and hang when it tried to copy the script. As it turns out, part of the issue is because of [a bug using Packer with the latest version of Docker (1.4+)](https://github.com/mitchellh/packer/issues/1752). I didn't want to downgrade Docker to 1.3, so I [incorporated the fix](https://github.com/mariussturm/packer/commit/3a286ab6bdba7b8e5bf6a43c357a0ffeacd3dc97) locally, and re-built the packer binaries for OSX_x64.

As of this writing, Packer still hasn't merged the patch, but you can [download my OSX binaries](https://www.dropbox.com/s/4v5jvvxj1k5mpst/packer-osx-patched-0.7.5.zip?dl=1) (install them to `/usr/local/bin`), or [build them yourself](https://github.com/mitchellh/packer#developing-packer) if you want to get up and running with _Go_.

The second issue is that packer stores it's temporary files and folders into `/var/folders` on OSX. You'll note from my findings with Fig above, by default boot2docker mounts `/Users`, and that's it, so there is no way for Docker to get provisioned by anything Packer wants to send to it since the boot2docker VM can't read `/var/folders`.

There are [several](https://github.com/mitchellh/packer/issues/398) [issues](https://github.com/mitchellh/packer/issues/1888) that have been reported around this, and it looks like most people solved it by setting their `TMPDIR` environment variable to something inside their `/Users` folder, like: `/Users/myuser/tmp` since that folder gets mounted in the boot2docker VM.

```
$ TMPDIR=/Users/chief/tmp packer build mybuild.json
```
