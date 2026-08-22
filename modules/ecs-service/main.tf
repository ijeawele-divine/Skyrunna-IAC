resource "aws_ecs_task_definition" "main" {
  family                   = "skyrunna-${var.env}-${var.service_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([{
    name      = var.service_name
    image     = var.image_url
    essential = true

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
      name          = var.service_name
    }]

    environment = [
      for k, v in var.environment_variables : {
        name  = k
        value = v
      }
    ]

    secrets = [
      for k, v in var.secrets : {
        name      = k
        valueFrom = v
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.log_group_name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = var.service_name
      }
    }

    healthCheck = var.target_group_arn != null ? null : length(var.health_check_command) == 0 ? {
      command     = ["CMD-SHELL", "nc -z localhost ${var.container_port} || exit 1"]
      interval    = 30
      timeout     = 10
      retries     = 3
      startPeriod = 180
    } : length(var.health_check_command) > 0 ? {
      command     = var.health_check_command
      interval    = 30
      timeout     = 10
      retries     = 3
      startPeriod = 180
    } : null
  }])

  tags = {
    Environment = var.env
    Service     = var.service_name
  }
}

resource "aws_ecs_service" "main" {
  name                   = "skyrunna-${var.env}-${var.service_name}"
  cluster                = var.cluster_id
  task_definition        = aws_ecs_task_definition.main.arn
  desired_count          = var.desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = true
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }

  dynamic "service_connect_configuration" {
    for_each = var.service_connect_enabled && var.service_connect_namespace != "" ? [1] : []
    content {
      enabled   = true
      namespace = var.service_connect_namespace

      service {
        port_name      = var.service_name
        discovery_name = var.service_name

        client_alias {
          port     = var.container_port
          dns_name = var.service_name
        }
      }
    }
  }

  tags = {
    Environment = var.env
    Service     = var.service_name
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}