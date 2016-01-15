---
layout: post.swig
title: Decoupling nodejs runtime from your app code with docker-compose
date: 2015-01-19 16:59:27
gist: chiefy/da720fb3ec5d8e7f20e2:.dockerignore
tags:
  - docker,
  - docker-compose,
  - orchestration
  - node
  - decoupling
---
Recently there were a series of CVEs that affected the LTS version of node. If your docker artifacts are built along with the node binary, you are going to have to redeploy. Here's a relatively easy way to decouple the node runtime from your application code with `docker-compose`.

## Part I: Your App
Your app's docker image only needs to contain application code and the `package.json` which will be used later.

Make sure you create a `.dockerignore` so that the docker context doesn't pick up large directories like `node_modules` or `.git`.
gist:chiefy/da720fb3ec5d8e7f20e2:.dockerignore

Next, all you need are your source files and any assets, so why not use `FROM scratch`?

```bash
$ cd myapp && docker build -t jerkyrater:1.0.0 .
```


