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
data "aws_subnet" "my_subnet_ids" {
   vpc_id = data.aws_vpc.existing_vpc.id
   cidr_block = "172.31.32.0/20"
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
resource "aws_ecs_task_definition" "my_first_task" {
  family                   = "my-ecs-task"
  container_definitions = <<DEFINITION
 [
  {
    "name": "my-container",
    "image": "${data.aws_ecr_repository.my_repository.repository_url}:latest",
    
    "portMappings": [
      {
        "containerPort": 3000,
        "protocol": "tcp"
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
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1 vCPU"
  memory                   = "2048"
  execution_role_arn       = "arn:aws:iam::168933414344:role/ecsTaskExecutionRole"
  
[
  {
    "name": "my-ecs-task",
    "image": "${data.aws_ecr_repository.my_repository.repository_url}:latest",
    
    "portMappings": [
      {
        "containerPort": 3000,
        "protocol": "tcp"
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
resource "aws_ecs_service" "my_service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  deployment_controller {
    type = "ECS"
  }
  
  resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}
  data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
  resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

  network_configuration {
    security_groups = [aws_security_group.ecs_security_group.id]
    subnets         = [data.aws_subnet.my_subnet_ids.id]

   
  }
}

