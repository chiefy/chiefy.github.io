---
layout: post.swig
title: Avoid Using Gelf Docker Log Driver with AWS VPCs
date: 2016-01-30 12:00:00
draft: true
tags:
  - logging
  - logs
  - docker
  - gelf
  - aws
  - vpc
---
Somewhat recently, the fine folks at Docker introduced new logging drivers to allow for easy transport of logs from a docker container to an external service. Originally Docker provided support for three log drivers: `syslog`, `json-file` and `journald`. In version `1.8` they added support for `gelf`, `fluentd` and `awslogs` (AWS Cloudwatch Logs). I soon ran into some major gotchas with some of these drivers in the context of AWS VPC and using `docker-compose`.

## `docker-compose`, links and `log-driver` oh my.
One of the first things I thought to do was setup a simple orchestration to try out some of these log drivers. Here is one I setup with the `fleunt/fluentd` image:

```yaml
app:
	image: alpine:latest
	command: echo "{\"log\":\"I am a log message.\"}"
	links:
	  - fluent
	log_driver: "fluentd"
	log_opt:
	  fluentd-address: "fluent:24224"
fluent:
  image: fluent/fluentd:latest
  volumes:
    - "./logs:/fluentd/log"
```

Can you spot the error here? Unfortunately (as of this writing), you cannot use links inside any `log_opt`. When the container starts up, it will not yet have the `/etd/hosts` entry for `fluent` and it will die complaining it can't connect to the log driver.

## GELF, DNS and Microservice Logging inside an AWS VPC
Out of the box, Logstash, the "L" in "ELK," supports GELF as an input. If you already have an ELK stack setup and running, using this driver might seem like a good choice.

### You can't load balance UDP with AWS ELB
Amazon's Elastic Load Balancing service (ELB) only supports TCP. Yes, [there are ways to load balance UDP](http://www.linuxvirtualserver.org/), but if you're looking for something easy to get running, an ELB is not an option.

### Problem 2: DNS
Let's say you decide to just use round-robin DNS for pseudo load-balancing? This would probably work well except for one major issue: the GELF driver only does DNS lookup at container startup. This means that if you swap out a Logstash instance, and docker is sending UDP GELF messages to it, they will be lost forever, and until you restart the container, it will not do another DNS lookup for an active instance.


