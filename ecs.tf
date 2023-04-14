# Define the provider for AWS
provider "aws" {
  region = "ap-south-1"
}


# Define the ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "my-ecs-cluster"
}

# Define VPC and subnet IDs
data "aws_vpc" "existing_vpc" {
  id = "vpc-011f1b733d94aa911" # Change to your existing VPC ID
}

data "aws_subnet_ids" "existing_subnets" {
  vpc_id = data.aws_vpc.existing_vpc.id

  # Change these IDs to your existing subnet IDs
  ids = [
    "subnet-0c44f87e69bedf89e",
    "subnet-09a8e0d6667281cd8",
    "subnet-004bbaa97d6950904"
  ]
}

data "aws_ecr_repository" "my_repository" {
  name = "my-repository"
}
# Define the ECS task definition
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "my-ecs-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1 vCPU"
  memory                   = "2048"
  

  container_definitions = <<DEFINITION
[
  {
    "name": "my-container",
    "image": "${data.aws_ecr_repository.my_repository.repository_url}:${data.aws_ecr_repository.my_repository.image_tag}",
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 80
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/my-ecs-task",
        "awslogs-region": "ap-south-1",
        "awslogs-stream-prefix": "my-container"
      }
    }
  }
]
DEFINITION
}