---
layout: post.swig
title: Decoupling nodejs runtime from your app with docker-compose
date: 2015-01-19 16:59:27
gist: chiefy/c914b3d8f94ce08a01b2:.dockerignore chiefy/c914b3d8f94ce08a01b2:Dockerfile chiefy/c914b3d8f94ce08a01b2:docker-compose.yml chiefy/c914b3d8f94ce08a01b2:index.js
tags:
  - docker,
  - docker-compose,
  - orchestration
  - node
  - decoupling
---
The situation is this: you have a nodejs app, it's deployed in various environments (private and public), and you read something like this on twitter:

<blockquote class="twitter-tweet" data-align="center" lang="en"><p lang="en" dir="ltr">Get ready to patch Dec 2nd&#10;&#10;CVE-2015-8027 Denial of Service &amp; CVE-2015-6764 V8 Out-of-bounds Access Vulnerabilities&#10;&#10;<a href="https://t.co/tuhG004XJF">https://t.co/tuhG004XJF</a></p>&mdash; Node.js Security (@nodesecurity) <a href="https://twitter.com/nodesecurity/status/669913772488724481">November 26, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

# Decoupling Node Apps From the Runtime
If you are creating build artifacts that include the nodejs binary, you are going to have to re-build, re-tag, bump-version etc. Here's something you could potentially do instead to save yourself from having to create a new build artifact.

# Code Only Docker Image
The idea here is to decouple the nodejs application code from the nodejs runtime. With orchestration tools like `docker-compose` you can then orchestrate a volume container that will mount the code, then in another container re-install `node_modules` and then run the application. 

Make sure you create a `.dockerignore` so that the docker context doesn't pick up large directories like `node_modules` or `.git`.
gist:chiefy/c914b3d8f94ce08a01b2:.dockerignore

Next, all you need are your source files and any assets. Since we're just using this as a data volume, we'll use `tinan/true` to immediately exit but keep the data volume exposed to other containers who want to mount it.
gist:chiefy/c914b3d8f94ce08a01b2:Dockerfile

For this example we'll create a super simple `expressjs` app that prints out the node version:
gist:chiefy/c914b3d8f94ce08a01b2:index.js

