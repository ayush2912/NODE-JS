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
# Define the existing subnets
data "aws_subnets" "my_subnet_ids" {
   id = [
          "subnet-0c44f87e69bedf89e",
          "subnet-09a8e0d6667281cd8"

}
resource "aws_security_group" "ecs_security_group" {
  name_prefix = "ecs-security-group"
  vpc_id      = data.aws_vpc.existing_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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
    "image": "${data.aws_ecr_repository.my_repository.repository_url}:latest",
    
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 0
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
resource "aws_ecs_service" "my_service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = 1

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    security_groups = [aws_security_group.ecs_security_group.id]
    subnets         = data.aws_subnets.my_subnet_ids.ids

    # Map container port 3000 to host port 3000
    # Change host_port to the port you want to map to on the host
    port_mappings = [{
      container_port = 3000
      host_port      = 80
    }]
  }
}

