---
layout: post.swig
title: Easily Deploy A Seneca Microservice to ECS with Wercker and Terraform
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
Among the many players in the continious integration SaaS providers, I recently discovered Wercker:

| Build apps faster. Release often. Automate all the things.

Wercker's docker stack and *pipeline* concept are not dissimilar to CodeShip's own docker offering, however Wercker provides a free level of usage for public repositories to use their docker stack (CodeShip's is still in closed beta). Further, Wercker users can create and share their own *steps* that help you create a CI/CD pipeline.

The following tutorial will show you how easy it is to create various Wercker pipelines to develop, test, build and deploy a simple SenecaJS-based microservice to Amazon's Elastic Container Service (ECS) using Hashicorp's Terraform for dynamically creating infrastructure required (IaaS).

# Preface
To complete this tutorial, you will need to provision Amazon Web Services infrastructure and you will need to create an account. Please make sure to destroy any resources you create during this as you will be charge real money if you forget to leave up any of what follows, and I wouldn't want you to receive a surprise bill from Amazon at the end of the month for hundreds or thousands of dollars.

For the sake of simplicity, I will be using MacOS related tooling below. If you are on Windows or Linux things may be easier or more difficult depending on the task at hand. If you are having issues, feel free to hit me up on twitter for any help I might be able to provide.

# Setup
Getting started with Wercker you will need some things to start:

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

# Check Out Project
To get started, you will need to clone the demo project:

```
$ git clone --recursive git@github.com:/chiefy/wercker-node-ecs-demo
```

# Provisioning ECS Cluster
As stated above, we will be creating real, live, money-costing AWS infrastructure. You will need a valid "PowerUser" keypair. Once again, unless you want to be charged hourly fees, you must destroy any resources you create with this tutorial. Fortunately [Terraform](https://www.terraform.io/) from [Hashicorp](https://www.hashicorp.com/) makes this all very, very easy.

In order to deploy docker containers to AWS with Wercker, we are going to need to setup an AWS ECS cluster. The cloned project contains a submodule `terraform/ecs` which is a [fork of terraform-amazon-ecs](https://github.com/Capgemini/terraform-amazon-ecs). 

If you don't already, make sure to setup an `awscli` profile with your credentials:

```
$ aws configure --profile my_personal_profile
AWS Access Key ID [None]: ABCDEFGH1234567
AWS Secret Access Key [None]: ABCDEFGH1234567ABCDEFGH1234567
Default region name [None]: us-east-1
Default output format [None]: json
```

Open and edit `terraform/ecs/terraform.tfvars` this file is a simple key-value store for setting terraform variables. You will need to provide a public key, you should have the private key for SSH access to any EC2 resources created.

Next, let's use the `plan` terraform subcommand to make sure everything is kosher:

```
$ cd terraform/ecs && terraform plan
```

You should get a nice summary of what Terraform is planning on creating based on your `.tfstate` file (which shouldn't exist yet):

```
Refreshing Terraform state prior to plan...


The Terraform execution plan has been generated and is shown below.
Resources are shown in alphabetical order for quick scanning. Green resources
will be created (or destroyed and then created if an existing resource
exists), yellow resources are being changed in-place, and red resources
will be destroyed.

Note: You didn't specify an "-out" parameter to save this plan, so when
"apply" is called, Terraform can't guarantee this is what will execute.

+ aws_autoscaling_group.ecs
    availability_zones.#:          "" => "3"
    availability_zones.2762590996: "" => "us-east-1d"
    availability_zones.3569565595: "" => "us-east-1a"
    availability_zones.986537655:  "" => "us-east-1c"
    default_cooldown:              "" => "<computed>"
    desired_capacity:              "" => "2"
    force_delete:                  "" => "0"
    health_check_grace_period:     "" => "<computed>"
    health_check_type:             "" => "<computed>"
    launch_configuration:          "" => "ecs"
    max_size:                      "" => "10"
    min_size:                      "" => "1"
    name:                          "" => "ecs-asg"
    vpc_zone_identifier.#:         "" => "<computed>"
    wait_for_capacity_timeout:     "" => "10m"

+ aws_ecs_cluster.default
    name: "" => "default"

+ aws_iam_instance_profile.ecs
    arn:             "" => "<computed>"
    create_date:     "" => "<computed>"
    name:            "" => "ecs-instance-profile"
    path:            "" => "/"
    roles.#:         "" => "1"
    roles.112154061: "" => "ecs_role"
    unique_id:       "" => "<computed>"

+ aws_iam_role.ecs_role
    arn:                "" => "<computed>"
    assume_role_policy: "" => "{\n  \"Version\": \"2008-10-17\",\n  \"Statement\": [\n    {\n      \"Action\": \"sts:AssumeRole\",\n      \"Principal\": {\n        \"Service\": [\"ecs.amazonaws.com\", \"ec2.amazonaws.com\"]\n      },\n      \"Effect\": \"Allow\"\n    }\n  ]\n}\n"
    name:               "" => "ecs_role"
    path:               "" => "/"
    unique_id:          "" => "<computed>"

+ aws_iam_role_policy.ecs_instance_role_policy
    name:   "" => "ecs_instance_role_policy"
    policy: "" => "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\n        \"ecs:CreateCluster\",\n        \"ecs:DeregisterContainerInstance\",\n        \"ecs:DiscoverPollEndpoint\",\n        \"ecs:Poll\",\n        \"ecs:RegisterContainerInstance\",\n        \"ecs:StartTelemetrySession\",\n        \"ecs:Submit*\",\n        \"ecs:StartTask\"\n      ],\n      \"Resource\": \"*\"\n    }\n  ]\n}\n"
    role:   "" => "${aws_iam_role.ecs_role.id}"

+ aws_iam_role_policy.ecs_service_role_policy
    name:   "" => "ecs_service_role_policy"
    policy: "" => "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\n        \"elasticloadbalancing:Describe*\",\n        \"elasticloadbalancing:DeregisterInstancesFromLoadBalancer\",\n        \"elasticloadbalancing:RegisterInstancesWithLoadBalancer\",\n        \"ec2:Describe*\",\n        \"ec2:AuthorizeSecurityGroupIngress\"\n      ],\n      \"Resource\": [\n        \"*\"\n      ]\n    }\n  ]\n}\n"
    role:   "" => "${aws_iam_role.ecs_role.id}"

+ aws_key_pair.ecs
    fingerprint: "" => "<computed>"
    key_name:    "" => "chief"
    public_key:  "" => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAqtYxLvMCPCujceL9GeR7SHHtHODKh+WLt5jPXcaIAnXGO0OlQAaZEHIVlHvytxRvg/cgqS6r3i/pnz8thLrpLFjBdYW0LtMK1z2U8s3qXxszksf6McJj6RlSBsb7esWj6N6B1fziP4DL4KwjhoslcHyfhbhWITF0g5J7ce4CGweWk7xOZ5D8UGVqynUWQ6zCGzMqYGhABP7cOY/FHMSkQ6q4Hlk/coOAjJLkgxU6krQ8GMUJJlwOW3yRwfiv66t2qKXoYBWF35rMM8BJCTbAmXt/SAvEY+y8Qw1SiuErqEk6MS3sWHe0aX/k8/jReO8EAV1mHI3mrc0qGu5DZCOfow== chief@chief.local"

+ aws_launch_configuration.ecs
    associate_public_ip_address: "" => "0"
    ebs_block_device.#:          "" => "<computed>"
    ebs_optimized:               "" => "<computed>"
    enable_monitoring:           "" => "1"
    iam_instance_profile:        "" => "ecs-instance-profile"
    image_id:                    "" => "ami-9886a0f2"
    instance_type:               "" => "t2.micro"
    key_name:                    "" => "chief"
    name:                        "" => "ecs"
    root_block_device.#:         "" => "<computed>"
    security_groups.#:           "" => "<computed>"
    user_data:                   "" => "cbde5513a6f551821684610116982ef8dda16445"

+ aws_security_group.ecs
    description:                          "" => "Container Instance Allowed Ports"
    egress.#:                             "" => "1"
    egress.482069346.cidr_blocks.#:       "" => "1"
    egress.482069346.cidr_blocks.0:       "" => "0.0.0.0/0"
    egress.482069346.from_port:           "" => "0"
    egress.482069346.protocol:            "" => "-1"
    egress.482069346.security_groups.#:   "" => "0"
    egress.482069346.self:                "" => "0"
    egress.482069346.to_port:             "" => "0"
    ingress.#:                            "" => "1"
    ingress.1377569725.cidr_blocks.#:     "" => "1"
    ingress.1377569725.cidr_blocks.0:     "" => "0.0.0.0/0"
    ingress.1377569725.from_port:         "" => "1"
    ingress.1377569725.protocol:          "" => "tcp"
    ingress.1377569725.security_groups.#: "" => "0"
    ingress.1377569725.self:              "" => "0"
    ingress.1377569725.to_port:           "" => "65535"
    name:                                 "" => "ecs-sg"
    owner_id:                             "" => "<computed>"
    tags.#:                               "" => "1"
    tags.Name:                            "" => "ecs-sg"
    vpc_id:                               "" => "<computed>"

+ template_file.user_data
    rendered:             "" => "<computed>"
    template:             "" => "#!/bin/bash\n\nconfig_file=/etc/ecs/ecs.config\n\necho \"ECS_CLUSTER=${cluster_name}\" > $config_file\necho \"ECS_ENGINE_AUTH_TYPE=dockercfg\" >> $config_file\necho \"ECS_ENGINE_AUTH_DATA={\\\"https://index.docker.io/v1/\\\":{\\\"auth\\\":\\\"${dockerhub_auth}\\\",\\\"email\\\":\\\"${dockerhub_email}\\\"}}\" >> $config_file\n"
    vars.#:               "" => "3"
    vars.cluster_name:    "" => "default"
    vars.dockerhub_auth:  "" => "XXXXXXXXXXXXXXXXX=="
    vars.dockerhub_email: "" => "chief@beefdisciple.com"


Plan: 10 to add, 0 to change, 0 to destroy.

```

As you can see from the last line of output, Terraform is planning on creating 10 resources. Later if you need to modify any of your AWS infrastructure, you can change your templates, and once again plan and apply and Terraform will magically manage the changes for you. Next, apply the plan and actually create the infrastructure. You should only have to perform this once unless you plan on creating an ECS cluster per-environment (dev/stage/prod). 

```
$ terrform apply
...
this will take 5-10 minutes
...

Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate
```

You can open up AWS console UI and verify that your ECS cluster has been created:

## Developing Locally w/ `wercker`
Our sample app here is a microservice written in node utilizing the great Seneca framework. I am not going to go into a lot of detail of what a microservice is, but for this example it is a simple web service that looks up a movie by title which is stored in redis.

### Navigating `wercker.yml`
`wercker` uses a YAML file for all of it's orchestration definition and config.

```yaml
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
Each wercker *pipeline* can use a specific docker image to run inside of, or it can use a globally defined *box*. For our example we are going to use a global *box* definition. `chiefy/alpine-nodejs` is just Alpine Linux with statically compiled `node` binary (`npm` included). This will be important in a later step. Because by default, Alpine does not ship with `bash`, you can see we have overriden the default `cmd`. With any `bash` enabled image, this would not be needed.

### Linking Services
Unlike `docker-compose`, wercker does not have the concept of linking containers using `/etc/hosts`. Wercker exposes various environment variables that you can instead use to link services between running containers. The environment variables are set in the following format:

```
<container name>_PORT_<port>_<protocol>_ADDR
<container name>_PORT_<port>_<protocol>_PORT
<container name>_PORT_<port>_<protocol>_PROTO

// any other env vars exposed from within the container 
// will be exposed in this format
<name>_ENV_<env>
```
Note that we set our own environment variable `SVC_REDIS_HOST` in the second `script` *step* in order to provide our app configuration for redis. The node app uses `node-config` for configuration and opening `config/custom-environment-variables.yml`, you will see this is where our app picks up the value set in `SVC_REDIS_HOST` and passes it along.
