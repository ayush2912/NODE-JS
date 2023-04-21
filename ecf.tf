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
name_prefix = "ayush-new"
 vpc_id      = data.aws_vpc.existing_vpc.id
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    security_groups = ["sg-04c53a4831e9f6ff8"]
  }
#some
 egress {
   from_port   = 0
   to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
data "aws_ecr_repository" "my_repository" {
  name = "my-repository"
  
}
data "aws_ecr_image" "service_image" {
  repository_name = "my-repository"
  most_recent       = true
  
}

# Define the ECS task definition
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "my-ecs-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "2 vCPU"
  memory                   = "4096"
  execution_role_arn       = "arn:aws:iam::168933414344:role/ecsTaskExecutionRole"
  container_definitions = <<DEFINITION
[
  {
    "name": "my-container",
    "image": "${data.aws_ecr_repository.my_repository.repository_url}",
    "portMappings": [
      {
        "containerPort": 8080,
        "protocol": "tcp"
      }
   ],
    "environment": [
        {
          "name": "SOCKETIO_MONGO_ADAPTER_URI",
          "value": "mongodb+srv://atlasAdmin:m9yrCL1hikEj8BUU@offsetmaxcluster0.6zak4.mongodb.net/offsetmaxsandbox"
        },
       {
          "name": "SOCKETIO_MONGO_ADAPTER_DB" ,
          "value": "offsetmaxsandbox"
        },
        {
          "name": "SOCKETIO_MONGO_ADAPTER_COLLECTION",
          "value": "SocketIoAdapterEvents"
        },
        {
          "name": "GQL_API" ,
          "value": "https://dev-orm.offsetmax.digital/"
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
  launch_type     = "FARGATE"
  desired_count   = 1
  deployment_controller {
    type = "ECS"
  }
  network_configuration {
    security_groups = [aws_security_group.ecs_security_group.id]
    subnets         = [data.aws_subnet.my_subnet_ids.id]
    assign_public_ip = true
  }
load_balancer {
    target_group_arn = "arn:aws:elasticloadbalancing:ap-south-1:168933414344:targetgroup/my-ecs-tg/0aabec2861010b51"
    container_name   = "my-container"
    container_port   = 8080
  }
}
