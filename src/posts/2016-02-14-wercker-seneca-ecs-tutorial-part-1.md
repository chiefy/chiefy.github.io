---
layout: post.swig
title: "Easily Deploy A Seneca Microservice to ECS with Wercker and Terraform: Part I"
date: 2016-02-14 12:00:00
tags:
  - ecs
  - aws
  - docker
  - wercker
  - seneca
  - nodejs
  - microservices
  - ci
  - cd
---
Among the many players in the continious integration & deployment SaaS providers, I recently discovered [Wercker](https://wercker.com):

> Build apps faster. Release often. Automate all the things.

Wercker's docker stack and *pipeline* concept are not dissimilar to [CodeShip's own docker offering](http://pages.codeship.com/docker), however Wercker provides a free level of usage for public repositories to use their docker stack (CodeShip's is still in closed beta). Further, Wercker users can [create and share their own *steps*](https://app.wercker.com/#explore) that help you create a unique CI/CD pipeline.

The following tutorial will show you how easy it is to create various Wercker pipelines to develop, test, build and deploy a simple [Seneca-based microservice](http://senecajs.org/) to Amazon's [Elastic Container Service (ECS)](https://aws.amazon.com/ecs/?hp=tile) using Hashicorp's Terraform for dynamically creating the required infrastructure (IaaS).

# Preface
To complete this tutorial, you will need to provision Amazon Web Services infrastructure and you will need to create an account. Please make sure to destroy any resources you create during this as you will be charged real money (**$$**) if you forget to leave up any of what follows, and I wouldn't want you to receive a surprise bill from Amazon at the end of the month for hundreds or thousands of dollars.

For the sake of simplicity, I will be using MacOS related tooling below. If you are on Windows or Linux things may be easier or more difficult depending on the task at hand. If you are having issues, feel free to [hit me up on twitter](https://twitter.com/tehsuck) for any help I might be able to provide.

## Setup
In order to complete this tutorial, you will need the following:

  * [Docker](https://www.docker.com/) / [docker-machine](https://docs.docker.com/machine/)
  * [Wercker cli tool](http://wercker.com/cli/)
  * [AWS cli tool](https://aws.amazon.com/cli/)
  * [Terraform](https://terraform.io)
  * [node / npm](https://nodejs.org)
  * [A Wercker account](https://app.wercker.com/users/new/)
  * [An AWS account](https://aws.amazon.com/), with keys provisioned for ["PowerUser" access](https://aws.amazon.com/code/AWS-Policy-Examples/2768921669666308)
  * [DockerHub account](https://hub.docker.com/)


If you are using `homebrew` on OSX:

```bash
$ brew update && brew install docker docker-machine terraform wercker-cli awscli
```

## Check Out Project
To get started, you will need to clone the [demo project](https://github.com/chiefy/wercker-node-ecs-demo):

```
$ git clone --recursive git@github.com:/chiefy/wercker-node-ecs-demo
```

# Pipelines, Steps and Boxes
Wercker's YAML definition allows you to specify various *steps* such as `npm-install` or `script` inside pre-defined *pipelines* (**dev**, **build** and **deploy**). When you push a code change to a linked repository, wercker will automagically run your `build` *pipeline* inside a specified *box* and upon success, deploy using the *deploy* pipeline (this needs to be explicity setup on the wercker website). A *box* is simply a docker image where wercker runs a *pipeline*. *Boxes* can be defined on a per-pipeline or global basis, but there **must** be a *box* definition for each pipeline (or a global), otherwise wercker will have problems and die.

## The *Dev* Pipeline
Our sample app here is a microservice written in node utilizing the great Seneca framework. I am not going to go into a lot of detail of what a microservice is, but for this example it is a simple web service that looks up a movie by title which is stored in redis.

### Navigating `wercker.yml`
`wercker` uses a YAML file for all of its orchestration definition and config.

```
box:
  id: quay.io/chiefy/alpine-nodejs
  tag: 4.3.0
  registry: https://quay.io
  cmd: /bin/sh

dev:
  services:
    - redis
  steps:
    - script:
      name: set env vars
      code: |
        export NODE_ENV=development
        export SVC_REDIS_HOST=${REDIS_PORT_6379_TCP_ADDR}

    - script:
      name: npm rebuild
      code: npm rebuild

    - internal/watch:
      code: node index.js
      reload: true
```

The first thing to note here is that we have defined the `dev` *pipeline*, which, just as it sounds is to setup our service to run locally for development. Each *pipeline* can have multiple *services* and *steps* to get it up and running. For our example, we are using redis as the data store. Much like `docker-compose`, we simply tell wercker the name of the docker image we want the service to use, and it will run it.

### Boxes
Each wercker *pipeline* can use a specific docker image to run inside of, or it can use a globally defined *box*. For our example we are going to use a global *box* definition. [`chiefy/alpine-nodejs`](https://quay.io/repository/chiefy/alpine-nodejs) is just [Alpine Linux](http://alpinelinux.org/) with statically compiled `node` binary (`npm` included). This will be important in a later step. Because by default Alpine does not ship with `bash`, we override the default `cmd`. With any `bash` enabled image, this would not be needed.

### Linking Services
Unlike `docker-compose`, wercker does not have the concept of linking containers using their `/etc/hosts`. Wercker exposes various environment variables that you can instead use to link services between running containers. The environment variables are set in the following format:

```
<container name>_PORT_<port>_<protocol>_ADDR
<container name>_PORT_<port>_<protocol>_PORT
<container name>_PORT_<port>_<protocol>_PROTO

// any other env vars exposed from within the container
// will be exposed in this format
<name>_ENV_<env>
```

Note that we set our own environment variable `SVC_REDIS_HOST` in the second `script` *step* in order to provide our app configuration for redis. The node app uses [`node-config`](https://www.npmjs.com/package/config) for configuration and opening `config/custom-environment-variables.yml`, you will see this is where our app picks up the value set in `SVC_REDIS_HOST` and passes it along.

## Developing Locally
Once you have installed the `wercker-cli` and the above required software, you can start the app locally:

```bash
$ npm install && wercker dev --publish 3000
```
After `npm` installs modules (you only need to do this the first time), you should see the following output when the app is ready:

```
--> Running step: watch
--> Reloading on file changes
--> Reloading
--> Forwarding 192.168.99.100:3000 to 3000 on the container.
2016-02-15T15:24:08.776Z hzkou4u4otct/1455549848718/35/- INFO hello Seneca/1.1.0/hzkou4u4otct/1455549848718/35/-
App listening on port 3000
```

Verify everything is working:

```
$ curl -XGET http://192.168.99.100:3000/Blue%20Velvet
{"entity$":"-/-/movie","title":"Blue Velvet","year":1989,"director":"David Lynch","id":"d03b4790-a12a-4ef3-8f37-771cbe428066"}
```
The service simply looks up a movie by title and outputs the Seneca entity JSON. If you change a file, Wercker's `internal/watch` step will automagically reload the application on file change, which is handy when developing locally.

# What's Next?
In the next part of this tutorial, we will cover Wercker's `build` *pipeline*.
