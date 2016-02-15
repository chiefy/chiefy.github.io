---
layout: post.swig
title: Decoupling the Node Runtime From Your App with docker-compose
date: 2016-01-16 11:59:27
gist: chiefy/c914b3d8f94ce08a01b2:.dockerignore chiefy/c914b3d8f94ce08a01b2:Dockerfile chiefy/c914b3d8f94ce08a01b2:docker-compose.yml chiefy/c914b3d8f94ce08a01b2:index.js chiefy/c914b3d8f94ce08a01b2:docker-compose-patched.yml
tags:
  - docker
  - docker-compose
  - orchestration
  - node
  - decoupling
---
The situation is this: you have a nodejs app/service, it's deployed in various environments (private and public), and you read something like this on twitter:

<blockquote class="twitter-tweet" data-align="center" lang="en"><p lang="en" dir="ltr">Get ready to patch Dec 2nd&#10;&#10;CVE-2015-8027 Denial of Service &amp; CVE-2015-6764 V8 Out-of-bounds Access Vulnerabilities&#10;&#10;<a href="https://t.co/tuhG004XJF">https://t.co/tuhG004XJF</a></p>&mdash; Node.js Security (@nodesecurity) <a href="https://twitter.com/nodesecurity/status/669913772488724481">November 26, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

# Decoupling Node Application Code From the Runtime
If you are creating build artifacts that include the nodejs binary, you are going to have to re-build, re-tag, bump-version and re-release/deploy.

The idea here is to decouple the nodejs application code from the nodejs runtime. With orchestration tools like `docker-compose` you can then orchestrate a volume container that will mount the code, then in another container re-install or re-build `node_modules` dependencies and run the application.

# Use a Code-only Docker Image
Make sure you create a `.dockerignore` so that the docker context doesn't pick up large directories like `node_modules` or `.git`.
gist:chiefy/c914b3d8f94ce08a01b2:.dockerignore

Next, all you need are your source files and any assets. Since we're just using this as a data volume, we'll use `tinan/true` to immediately exit but keep the data volume exposed to other containers who want to mount it.
gist:chiefy/c914b3d8f94ce08a01b2:Dockerfile

For this example we'll create a super simple `expressjs` app that prints out the nodejs version:
gist:chiefy/c914b3d8f94ce08a01b2:index.js

# Orchestration
There's a few things to note here:

  * I'm using an [Alpine Linux](http://alpinelinux.org/) based nodejs image
  * Since we added `node_modules` to the `.dockerignore` we will need to make sure to `npm install --production` before we run the nodejs application
  * The nodejs image is built to be slim, so if your application has any node modules that need native compilation, you may need to install some packages before `npm install`

gist:chiefy/c914b3d8f94ce08a01b2:docker-compose.yml

Let's run this with `docker-compose up`:

```bash
Building code
Step 1 : FROM tianon/true
latest: Pulling from tianon/true
e3d3859e28f4: Pull complete
4da49b657714: Pull complete
Digest: sha256:0c678029118314264306b49c931d6dce678c8c88143252342a8614210bea4129
Status: Downloaded newer image for tianon/true:latest
 ---> 4da49b657714
Step 2 : ADD . /app
 ---> ae963587d4f7
Removing intermediate container 94aeb2da0e77
Step 3 : VOLUME /app
 ---> Running in f4915f2bb377
 ---> b9052ca7c135
Removing intermediate container f4915f2bb377
Successfully built b9052ca7c135
Creating tmp_code_1
Creating tmp_app_1
Attaching to tmp_code_1, tmp_app_1
tmp_code_1 exited with code 0
app_1  | sample@1.0.0 /app
app_1  | `-- express@4.13.3
app_1  |   +-- accepts@1.2.13
app_1  |   | +-- mime-types@2.1.9
app_1  |   | | `-- mime-db@1.21.0
app_1  |   | `-- negotiator@0.5.3
app_1  |   +-- array-flatten@1.1.1
app_1  |   +-- content-disposition@0.5.0
app_1  |   +-- content-type@1.0.1
app_1  |   +-- cookie@0.1.3
app_1  |   +-- cookie-signature@1.0.6
app_1  |   +-- debug@2.2.0
app_1  |   | `-- ms@0.7.1
app_1  |   +-- depd@1.0.1
app_1  |   +-- escape-html@1.0.2
app_1  |   +-- etag@1.7.0
app_1  |   +-- finalhandler@0.4.0
app_1  |   | `-- unpipe@1.0.0
app_1  |   +-- fresh@0.3.0
app_1  |   +-- merge-descriptors@1.0.0
app_1  |   +-- methods@1.1.1
app_1  |   +-- on-finished@2.3.0
app_1  |   | `-- ee-first@1.1.1
app_1  |   +-- parseurl@1.3.0
app_1  |   +-- path-to-regexp@0.1.7
app_1  |   +-- proxy-addr@1.0.10
app_1  |   | +-- forwarded@0.1.0
app_1  |   | `-- ipaddr.js@1.0.5
app_1  |   +-- qs@4.0.0
app_1  |   +-- range-parser@1.0.3
app_1  |   +-- send@0.13.0
app_1  |   | +-- destroy@1.0.3
app_1  |   | +-- http-errors@1.3.1
app_1  |   | | `-- inherits@2.0.1
app_1  |   | +-- mime@1.3.4
app_1  |   | `-- statuses@1.2.1
app_1  |   +-- serve-static@1.10.0
app_1  |   +-- type-is@1.6.10
app_1  |   | `-- media-typer@0.3.0
app_1  |   +-- utils-merge@1.0.0
app_1  |   `-- vary@1.0.1
app_1  |
app_1  | npm WARN EPACKAGEJSON sample@1.0.0 No repository field.
app_1  | npm WARN EPACKAGEJSON sample@1.0.0 No license field.
app_1  |
app_1  | > sample@1.0.0 start /app
app_1  | > node /app/index.js
app_1  |
app_1  | Example app listening on port 3000!
```

```
❯ curl -XGET http://docker.local:8080
I am running nodejs version: 4.2.2
```

To upgrade the nodejs version, all we need to do is create a new docker image with the patched node binary, update the `docker-compose.yml` accordingly and issue `docker-compose up` which should detect the changes and restart the `app` service. Note the new nodejs version `4.2.3` below:

gist:chiefy/c914b3d8f94ce08a01b2:docker-compose-patched.yml

```
❯ curl -XGET http://docker.local:8080
I am running nodejs version: 4.2.3
```

# So What's the Point?
Obviously you will need to test your code against the new version of nodejs in CI, and create a new release, but decoupling the code from the runtime prevents your build artifact from mutating between deploys / releases.

