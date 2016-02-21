---
layout: post.swig
title: Easily Deploy A Seneca Microservice to ECS with Wercker and Terraform Part II
date: 2016-02-16 12:00:00
draft: true
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

The following is the second of a two-part tutorial on how to use Wercker along with Hashicorp's Terraform and AWS Elastic Container Service (ECS) to easily deploy minimal docker services. If you haven't, please start with [the first installment]() and then continue here.


# Creating an ECS Cluster With Terraform
As previously stated, we will be creating real, live, money-costing AWS infrastructure. You will need a valid AWS keypair which has "PowerUser" rights. Once again, unless you want to be charged hourly fees, you must destroy any resources you create with this tutorial. Fortunately [Terraform](https://www.terraform.io/) from [Hashicorp](https://www.hashicorp.com/) makes this all very, very easy.

In order to deploy docker containers to AWS with Wercker, we eed to standup and provision an AWS ECS cluster. The cloned project contains a submodule `terraform/ecs` which is a [fork of terraform-amazon-ecs](https://github.com/Capgemini/terraform-amazon-ecs).

If you don't already, make sure to setup an `awscli` profile with your credentials:

```
$ aws configure --profile my_personal_profile
AWS Access Key ID [None]: ABCDEFGH1234567
AWS Secret Access Key [None]: ABCDEFGH1234567ABCDEFGH1234567
Default region name [None]: us-east-1
Default output format [None]: json
```

Open and edit `terraform/ecs/terraform.tfvars` this file is a simple key-value store for setting terraform variables. You will need to provide a public key, you should have the private key for SSH access to any EC2 resources created. You will also provide your dockerhub credentials in order for ECS to pull private docker images.

```
# The AWS region you are deploying to
region="us-east-1"

# The AWS profile you created above with your "PowerUser" keys
aws_profile_name="personal"

# Absolute path of AWS creds file, defaults to ~/.aws/credentials
aws_creds_file="/Users/chief/.aws/credentials"

# DockerHub auth which can be found at ~/.docker/config.json
dockerhub_auth="YLDOkjd2lad0lkeenkeo$#23=="
dockerhub_email="chief@beefdisciple.com"

# Public SSH key
public_key="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAqtYxLvMCPCujceL9GeR7SHHtHODKh+WLt5jPXcaIAnXGO0OlQAaZEHIVlHvytxRvg/cgqS6r3i/pnz8thLrpLFjBdYW0LtMK1z2U8s3qXxszksf6McJa4ffedWj6N6B1fziP4DL4KwjhoslcHyfhbhWITF0g5J7ce4CGweWk7xOZ5D8UGVqynUWQ6zCGzMqYGhABP7cOY/FHMSkQ6q4Hlk/coOAjJLkgxU64asfGMUJJlwOW3yRwfiv66t2qKXoYBWF35rMM8BJCTbAmXt/SAvEY+y8Qw1SiuErqEk6MS3sWHe0aX/k8/jReO8EAV1mHI3mrc0qGuf444Ofow== chief_ecs"

# Key name as it will be stored in EC2
key_name="chief_ecs"

# Name of ECS cluster
ecs_cluster_name="wercker-demo"
```

Next, let's use the `plan` terraform subcommand to make sure everything is kosher. I have included some `npm` scripts to simplify it:

```
$ npm run plan-ecs
```

You should get a nice summary of what Terraform is planning on creating based on your `ecs.tfstate` file (which shouldn't exist yet):

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
    key_name:    "" => "chief_ecs"
    public_key:  "" => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAqtYxLvMCPCujceL9GeR7SHHtHODKh+WLt5jPXcaIAnXGO0OlQAaZEHIVlHvytxRvg/cgqS6r3i/pnz8thLrpLFjBdYW0LtMK1z2U8s3qXxszksf6McJj64khk4kjs7esWj6N6B1fziP4DL4KwjhoslcHyfhbhWITF0g5J7ce4CGweWk7xOZ5D8UGVqynUWQ6zCGzMqYGhABP7cOY/FHMSkQ6q4Hlk/coOAjJLkgxU6krQ8GMUJJlwOW3yRwfiv66t2qKXoYBWF35rMM8BJCTbAmXt/SAvEY+y8Qw1SiuErqEk6MS3sWHe0aX/k8/jReO8EAV1mHI3mrc0qGu5DZCOfow== chief_ecs"

+ aws_launch_configuration.ecs
    associate_public_ip_address: "" => "0"
    ebs_block_device.#:          "" => "<computed>"
    ebs_optimized:               "" => "<computed>"
    enable_monitoring:           "" => "1"
    iam_instance_profile:        "" => "ecs-instance-profile"
    image_id:                    "" => "ami-9886a0f2"
    instance_type:               "" => "t2.micro"
    key_name:                    "" => "chief_ecs"
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
    vars.cluster_name:    "" => "wercker-demo"
    vars.dockerhub_auth:  "" => "J032kdjfd$(sk$Jlkj=="
    vars.dockerhub_email: "" => "chief@beefdisciple.com"


Plan: 10 to add, 0 to change, 0 to destroy.
```

As you can see from the last line of output, Terraform is planning on creating 10 resources. Later if you need to modify any of your AWS infrastructure, you can change your templates, and once again `plan` and `apply` and Terraform will magically manage the changes for you. Next, apply the plan and actually create the infrastructure. You should only have to perform this once unless you plan on creating an ECS cluster per-environment (dev/stage/prod).

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

State path: ../../ecs.tfstate
```

You can open up AWS console UI and verify that your ECS cluster has been created:

[!

# The *Build* Pipeline
In the first part of this tutorial, we learned about Wercker's *dev* pipeline and how to use it to orchestrate a development environment locally. When you are done coding and testing and want to push some new feature or bug-fix, the *build* pipeline controls your build on [wercker.com](https://wercker.com).

To get started, create an account at [wercker.com](https://wercker.com), next [create a new *application* by linking GitHub to our Wercker account](https://app.wercker.com/#applications/create). The Wercker quickstart for nodejs has a good walkthrough on how to setup and link your GitHub project.
  
  * [Wercker quickstart for nodejs](http://devcenter.wercker.com/quickstarts/building/javascript.html#adding-your-app-to-wercker)

> Build pipelines have an end result called an artifact which is the result of your pipeline. Wercker stores this artifact on its infrastructure such that it can be used in deploy pipelines. The artifact is stored both as a container and a tarball of just the source files.

Here's our *build* pipeline definition in `wercker.yml`:

```
...
build:
  steps:
    - script:
      name: set env vars
      code: export NODE_ENV=test

    - npm-install

    - npm-test

    - script:
        name: copy files
        code: |
          cp $(which node) "$WERCKER_OUTPUT_DIR"
          cp -RL node_modules config data api index.js package.json "$WERCKER_OUTPUT_DIR"
...
```

Since `node_modules` is not commited to the repo, we'll use the `npm-install` step, and then run our tests with the `npm-test` step. That way we can hook up notifications to blame the poor sap who broke the build.

If the tests pass, we just need to copy any files needed for the build artifact. In this case, since I've statically compiled node, the node binary is copied to `$WERCKER_OUTPUT_DIR` and then any files we need to run the microservice, such as: `node_modules`, `config`, etc. Let's push our new code (with a few tests) and see if the build process works.

![yay!, our build passed](/public/img/wercker-ecs-demo-3.png)

Yay! Our build ran and passed. If you had issues, you could inspect each step that Wercker takes though the web UI, or you can run build locally to debug.

# The *Deploy* Pipeline
Now that the *build* pipeline is succesful, there's a healthy artifact out there, just waiting to be lovingly deployed, somewhere... Our goal is to deploy to the ECS cluster we stood up above, but the first part of our deploy chain is pushing our artifact to DockerHub as a tagged docker image.

Here's our new section of `wercker.yml`:

```
...
deploy:
  dockerhub:
    - internal/docker-scratch-push:
        username: $DOCKER_USERNAME
        password: $DOCKER_PASSWORD
        cmd: ./node ./index.js
        tag: $WERCKER_GIT_COMMIT
        ports: "3000"
        repository: chiefy/wercker-ecs-demo
        registry: https://registry.hub.docker.com
...
```

For each deploy, you need to provide a name that distinguishes it so you can later reference it on the website. Our first *deploy* will be pushing a docker image to DockerHub, so `dockerhub` it is! As with all the other Wercker pipelines, you use steps to run the deploy. Here the `internal/docker-scratch-push` step is used. This is a handy step that simply uses whatever you copied into your `$WERCKER_OUTPUT_DIR` and places it inside a `FROM SCRATCH` docker image. The main benefits of slim docker images are: fast pulls and decreased attack vectors. If you are using Go, this is a great option as well.

## Injecting Secrets Into Your Deploy

Of note are the two environment vars `$DOCKER_USERNAME` and `$DOCKER_PASSWORD`. These get injected by Wercker at deploy time. You manage these secrets in the web UI by clicking on the settings cog inside your application and then "Environment variables."

![set your env vars on the site](/public/img/wercker-ecs-demo-4.png)

Let's push the new *deploy* pipeline to create a new build.

## Adding a Deploy Target
Unfortunately, Wercker can't currently detect your *deploy* pipeline settings, so you must register it by using the web UI: click the cog icon in the upper right of your application's page. Go to "Targets," and add a new "custom deploy" target with `dockerhub` as the name and check "auto-deploy" and make sure to enter "master" on the whitelist below.

![add deploy target](/public/img/wercker-ecs-demo-5.png)

## Push To DockerHub
To test our newly added deploy target, go to the latest successful build and click the "Deploy to" dropdown and select "dockerhub."
