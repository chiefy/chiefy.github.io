---
layout: post.swig
title: Easily Deploy A Seneca Microservice to ECS with Wercker and Terraform Part III
date: 2016-03-06 12:00:00
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

> Build apps faster. Release often. Automate all the things.

The following is the third of a three-part tutorial on how to use Wercker along with Hashicorp's Terraform and AWS Elastic Container Service (ECS) to easily deploy minimal docker services. If you haven't, please start with [the first installment](/easily-deploy-a-seneca-microservice-to-ecs-with-wercker-and-terraform-part-i/) and then continue here.

This is the final step in our deployment chain. In the previous parts of this tutorial, we have learned how to use Wercker's `yaml` configuration to orchestrate a local development environment, create a build artifact with the *build* pipeline and push our artifact as a docker image to DockerHub.

# Creating an ECS Cluster With Terraform
As previously stated, we will be creating real, live, money-costing AWS infrastructure. You will need a valid AWS keypair which has "PowerUser" rights. Once again, unless you want to be charged hourly fees, you must destroy any resources you create with this tutorial. Fortunately [Terraform](https://www.terraform.io/) from [Hashicorp](https://www.hashicorp.com/) makes this all very, very easy.

In order to deploy docker containers to AWS with Wercker, we need to stand up and provision an AWS ECS cluster. The cloned project contains a submodule `terraform/ecs` which is a [fork of terraform-amazon-ecs](https://github.com/Capgemini/terraform-amazon-ecs).

If you don't already, make sure to setup an `awscli` profile with your credentials:

```
$ aws configure --profile my_personal_profile
AWS Access Key ID [None]: ABCDEFGH1234567
AWS Secret Access Key [None]: ABCDEFGH1234567ABCDEFGH1234567
Default region name [None]: us-east-1
Default output format [None]: json
```

Open and edit `terraform/ecs/terraform.tfvars` this file is a simple key-value file for setting terraform variables. You will need to provide a public key, you should have the private key for SSH access to any EC2 resources created. You will also provide your DockerHub credentials in order for ECS to pull private docker images.

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

As you can see from the last line of output, Terraform is planning on creating 10 resources. Later if you need to modify any of your AWS infrastructure, you can change your templates, and once again `npm run ecs-plan` and `npm run ecs-apply` and Terraform will magically manage the changes for you. Next, apply the plan and actually create the infrastructure. You should only have to perform this once unless you plan on creating an ECS cluster per-environment (dev/stage/prod).

```
$ npm run apply-ecs
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

You can check the status of your cluster using the `aws` cli:

```
❯ aws ecs describe-clusters --clusters wercker-demo --profile personal
{
    "clusters": [
        {
            "status": "ACTIVE",
            "clusterName": "wercker-demo",
            "registeredContainerInstancesCount": 2,
            "pendingTasksCount": 0,
            "runningTasksCount": 0,
            "activeServicesCount": 0,
            "clusterArn": "arn:aws:ecs:us-east-1:1234456789:cluster/wercker-demo"
        }
    ],
    "failures": []
}
```

There are two `registeredContainerInstancesCount` which is what was specified with our Terraform script, and the cluster is `ACTIVE` so everything looks good!

# Adding the ECS Deploy Target

Up until now, there has only been one deploy target, the `dockerhub` target which pushes the build artifact as a docker image to DockerHub and tags it with the commit hash. Now that the ECS cluster is ready for services, we can use a custom Wercker step in the *deploy* pipeline to run Terraform which will build out and deploy ECS services and tasks relating to the simple Seneca microservice we've created.

## Add A New Deploy Target

On the Wercker website, in the `wercker-node-ecs-demo` application settings, we'll need to add a new deploy target. The new target is simply called `ecs`, and it's important that we inject certain environment vars to the deploy. 

Use the settings cog to go into the application's settings, and then create a new deploy target `ecs`. Next, click "Add new variable" and enter the following: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION`. These vars will be used by Terraform's AWS provisioner. 

These credentials must have `"ecs:*"`, `s3:*` and `ec2:elb:*` rights in order to create the AWS infrastructure required. I am using the built-in "arn:aws:iam::aws:policy/PowerUserAccess" which include 

Also add `AWS_ACCOUNT_ID` will be used to costruct some Terraform vars that our ECS templates need. 

<div class="centered">
![add environment variables](/assets/img/wercker-ecs-demo-9.png)
</div>


## The Terraform Templates

In order to deploy our service to ECS, we need a few simple Terraform templates along with some JSON to define the ECS tasks. 

```
resource "aws_ecs_service" "movie_api" {
	depends_on = ["aws_ecs_task_definition.movie_api"]

	name = "${concat("movie_api-",var.env)}"
	cluster = "${var.ecs_cluster_id}"
	task_definition = "${aws_ecs_task_definition.movie_api.arn}"
	desired_count = 2
	iam_role = "${var.iam_role_arn}"

	load_balancer {
		elb_name = "${aws_elb.movie_api_elb.id}"
		container_name = "movie-api"
		container_port = 3000
	}
}

resource "aws_ecs_task_definition" "movie_api" {
	family = "${concat("movie-api-",var.env)}"
	container_definitions = "${file("movie-api-task.json")}"
}
```
In ECS-land, a `service` consists of a `task-definition` which is a JSON-representation of orchestrated containers. ECS allows you to attach an ELB to a `service` along with specifying the number of task instances to spawn (this includes any containers in the task definition). For further details on ECS terminology and options, [check the documentation](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html)!

There are two Terraform outputs from the ECS cluster template (at the very beginning of this post) that we must reference here: `${var.ecs_cluster_id}`, which is just the full ARN of the `wercker-demo` ECS cluster which was created in the previous step, and `${var.iam_role_arn}`, which is the IAM role also created in the previous step. These two values will be injected into Terraform by using environment variables set in a `wercker.yml` step, which will be covered next.

Here is the template for the ELB. There is nothing very special about this ELB other than the fact that it will listen on `http:80` and forward to our ECS cluster instances at `http:3000`. 

```
# Create a new load balancer
resource "aws_elb" "movie_api_elb" {
	name = "${concat("movie-api-",var.env)}"

	availability_zones = ["us-east-1a", "us-east-1c", "us-east-1d"]

	listener {
		instance_port = 3000
		instance_protocol = "http"
		lb_port = 80
		lb_protocol = "http"
	}

	health_check {
		healthy_threshold = 3
		unhealthy_threshold = 3
		timeout = 3
		target = "tcp:3000"
		interval = 30
	}

	cross_zone_load_balancing = true
	idle_timeout = 400
	connection_draining = true
	connection_draining_timeout = 400

	tags {
		Name = "${concat("Movie API - ",var.env)}"
		Env = "${var.env}"
	}
}
```

### ECS Task Definition JSON

To orchestrate our movie service which utilizes redis, we will create an ECS task definition for it:

```json
[
	{
		"environment": [
			{
				"name": "NODE_ENV",
				"value": "production"
			},
			{
				"name": "SVC_REDIS_HOST",
				"value": "redis"
			}
		],
		"essential": true,
		"image": "chiefy/wercker-ecs-demo:${WERCKER_GIT_COMMIT}",
		"logConfiguration": {
			"logDriver": "json-file"
		},
		"links": [
			"redis"
		],
		"memory": 128,
		"cpu": 256,
		"mountPoints": [],
		"name": "movie-api",
		"portMappings": [
			{
				"containerPort": 3000,
				"hostPort": 3000,
				"protocol": "tcp"
			}
		]
	},
	{
		"image": "redis",
		"name": "redis",
		"memory": 256,
		"cpu": 256,
		"essential": true,
		"logConfiguration": {
			"logDriver": "json-file"
		}
	}
]
```

There are some important things to note here. In the first container definition, it's important to reference the docker image we built with wercker and pushed to DockerHub. Since it is tagged with the commit hash, we need to inject this value into the JSON somehow. Luckily there is a wercker step that can easily inject environment variables into a file: `appnific/expandenv@0.1.3`. This step will substitute the build hash for `${WERCKER_GIT_COMMIT}` before running Terraform. 

If you have used `docker-compose`, you are likely aware of how to link two containers together using `links`. For ECS, it is very similar, in the container definition for `movie-api` there is a property called `links` which references the container definition later defined for the `redis` instance. We can then use the hostname `redis` and use it by setting the `SVC_REDIS_HOST` environment variable in our service container's defintion.

## Update `wercker.yml` With New Deploy Target

Now that the Terraform template has been created that will deploy our microservice and redis to ECS, it's time to update the `wercker.yml` to reference our new deploy target.

```
...
deploy:

  box: nodesource/trusty:4.3.0

  ecs:
    - script:
        name: set ENV vars
        code: |
          export TF_VAR_iam_role_arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecs_role
          export TF_VAR_ecs_cluster_id=arn:aws:ecs:us-east-1:${AWS_ACCOUNT_ID}:cluster/wercker-demo

    - appnific/expandenv@0.1.3:
        input_file: movie-api-task-template.json
        output_file: movie-api-task.json

    - releasequeue/run-terraform@0.0.17:
        action: apply
        state_stor_bucket: tf_state_bucket
        state_stor_bucket_region: us-east-1
        state_stor_key: movie_api_ecs

```

The first step of the `ecs` deploy sets some environment vars that Terraform will need to complete. Note that these must be prefixed with `TF_VAR_`. Next, as has been explained above, we inject the commit hash of the build into the ECS task definition JSON and output a new JSON file by using the `appnific/expandenv` step. Finally the Terraform step will install and apply templates also storing the `.tfstate` file in the s3 bucket `tf_state_bucket` with the key `movie_api_ecs`.

Since `releasequeue/run-terraform` will try to pull and install Terraform, we must use a custom `box` in our deploy step with a few more built-in tools than the Alpine based image. In this instance, `nodesource/trusty:4.3.0` will work just fine.

There is one last tweak that needs to be made. In order to have the `releasequeue/run-terraform` step run, the ECS task Terraform template files need to be copied to the root of our build's output directory. This can be accomplished by adding one more line to the last step of our *build* pipeline where files are copied to `$WERCKER_OUTPUT_DIR`.

```
...
    - script:
        name: copy files
        code: |
          cp $(which node) "$WERCKER_OUTPUT_DIR"
          cp -RL node_modules config data api index.js package.json "$WERCKER_OUTPUT_DIR"
          cp terraform/*.tf terraform/*.json "$WERCKER_OUTPUT_DIR"
...
```

# The Moment of Truth
Once then new Terraform templates and `wercker.yml` modifications have been pushed, and a new build is succesfully pushed to DockerHub, we can try out the deploy to ECS on wercker's site.

<div class="centered">
![run ecs deploy target](/assets/img/wercker-ecs-demo-10.png)
</div>


```
Initialized blank state with remote state enabled!
Remote state configured and pulled.
aws_ecs_task_definition.movie_api: Creating...
  arn:                   "" => "<computed>"
  container_definitions: "" => "d424e20a71795b57c92918a63be4e64a616d1294"
  family:                "" => "movie-api-production"
  revision:              "" => "<computed>"
aws_elb.movie_api_elb: Creating...
  availability_zones.#:                       "" => "3"
  availability_zones.1532376300:              "" => "us-east-1d"
  availability_zones.725401701:               "" => "us-east-1a"
  availability_zones.986537655:               "" => "us-east-1c"
  connection_draining:                        "" => "1"
  connection_draining_timeout:                "" => "400"
  cross_zone_load_balancing:                  "" => "1"
  dns_name:                                   "" => "<computed>"
  health_check.#:                             "" => "1"
  health_check.434606976.healthy_threshold:   "" => "3"
  health_check.434606976.interval:            "" => "30"
  health_check.434606976.target:              "" => "HTTP:3000/"
  health_check.434606976.timeout:             "" => "3"
  health_check.434606976.unhealthy_threshold: "" => "3"
  idle_timeout:                               "" => "400"
  instances.#:                                "" => "<computed>"
  internal:                                   "" => "<computed>"
  listener.#:                                 "" => "1"
  listener.1497737023.instance_port:          "" => "3000"
  listener.1497737023.instance_protocol:      "" => "http"
  listener.1497737023.lb_port:                "" => "80"
  listener.1497737023.lb_protocol:            "" => "http"
  listener.1497737023.ssl_certificate_id:     "" => ""
  name:                                       "" => "movie-api-production"
  security_groups.#:                          "" => "<computed>"
  source_security_group:                      "" => "<computed>"
  source_security_group_id:                   "" => "<computed>"
  subnets.#:                                  "" => "<computed>"
  tags.#:                                     "" => "2"
  tags.Env:                                   "" => "production"
  tags.Name:                                  "" => "Movie API - production"
  zone_id:                                    "" => "<computed>"
aws_ecs_task_definition.movie_api: Creation complete
aws_elb.movie_api_elb: Creation complete
aws_ecs_service.movie_api: Creating...
  cluster:                                 "" => "arn:aws:ecs:us-east-1:710390882138:cluster/wercker-demo"
  desired_count:                           "" => "2"
  iam_role:                                "" => "arn:aws:iam::710390882138:role/ecs_role"
  load_balancer.#:                         "" => "1"
  load_balancer.1255725728.container_name: "" => "movie-api"
  load_balancer.1255725728.container_port: "" => "3000"
  load_balancer.1255725728.elb_name:       "" => "movie-api-production"
  name:                                    "" => "movie_api-production"
  task_definition:                         "" => "arn:aws:ecs:us-east-1:12340394059:task-definition/movie-api-production:1"
aws_ecs_service.movie_api: Creation complete

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: .terraform/terraform.tfstate
State successfully pushed!
```

<div class="centered">
![success](http://i.giphy.com/aWRWTF27ilPzy.gif)
</div>

Now to try out the service, we need our ELB's host name:

```
❯ aws elb describe-load-balancers --load-balancer-name movie-api-production --profile personal | grep DNSName
"DNSName": "movie-api-production-482728403.us-east-1.elb.amazonaws.com",
```

```
❯ curl -XGET http://movie-api-production-482728403.us-east-1.elb.amazonaws.com/Blue%20Velvet
{"entity$":"-/-/movie","title":"Blue Velvet","year":1989,"director":"David Lynch","id":"53d7857c-4cbf-4125-9ce8-59dc86f9160a"}
```

<div class="centered">
![yes](http://i.giphy.com/msKNSs8rmJ5m.gif)
</div>

# In Summation
Over the three parts of this blog post, I've looked at how to use [Wercker](https://wercker.com) in conjuction with [Hashicorp's Terraform](https://www.terraform.io/) as a complete CI/CD solution for building and deploying a [SenecaJS](senecajs.org) microservice to [Amazon ECS](https://aws.amazon.com/ecs/). Terraform makes creating and provisioning AWS infrastructure a breeze. And with it's powerful pipeline concept and composable steps, Wercker has made it relatively easy to manage your microservice's build & deploy process. With these tools we can create slim and simple Seneca microservices container images which are continiously deployed. I hope these posts are helpful to anyone trying to get into using these wonderful tools to simplify developer's lives.

  * [Wercker-ECS-Seneca Demo Project Source](https://github.com/chiefy/wercker-node-ecs-demo)
  * [Application on Wercker](https://app.wercker.com/#applications/56ca181c7beb00ce4022f8cc)