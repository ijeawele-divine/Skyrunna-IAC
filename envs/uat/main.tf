module "network" {
  source   = "../../modules/network"
  env      = "uat"
  vpc_cidr = "10.0.0.0/16"
  az_count = 2
}

module "ecr" {
  source = "../../modules/ecr"
  env    = "uat"
  services = [
    "config-server",
    "api-gateway-service",
    "user-service",
    "cloud-resilience-service",
    "report-service",
    "notification-service",
    "frontend-app"
  ]
}

module "ssm_secrets" {
  source = "../../modules/ssm-secrets"
  env    = "uat"
  secrets = {
    JWT_SECRET                        = var.jwt_secret
    ENCRYPTION_KEY                    = var.encryption_key
    POSTGRES_PASSWORD                 = var.postgres_password
    APP_SEED_SUPER_ADMIN_PASSWORD_HASH = var.super_admin_password_hash
    RESILIENCE_SERVICE_API_KEY        = var.resilience_service_api_key
    NOTIFICATION_SERVICE_API_KEY      = var.notification_service_api_key
    REPORT_SERVICE_API_KEY            = var.report_service_api_key
    SENDGRID_API_KEY                  = var.sendgrid_api_key
    SPRING_MAIL_PASSWORD              = var.sendgrid_api_key
    FLUTTERWAVE_SECRET_KEY            = var.flutterwave_secret_key
    FLUTTERWAVE_PUBLIC_KEY            = var.flutterwave_public_key
    FLUTTERWAVE_ENCRYPTION_KEY        = var.flutterwave_encryption_key
  }
}

module "redis" {
  source = "../../modules/redis"
  env    = "uat"

  subnet_ids        = module.network.private_data_subnet_ids
  security_group_id = module.network.redis_sg_id
  node_type         = "cache.t3.micro"
}

module "rds" {
  source = "../../modules/rds"
  env    = "uat"

  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.private_data_subnet_ids
  security_group_id = module.network.rds_sg_id

  db_name           = "sknett_db"
  db_username       = "skyrunna_app"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
}

module "ecs_cluster" {
  source = "../../modules/ecs-cluster"
  env    = "uat"
}

module "alb" {
  source = "../../modules/alb"
  env    = "uat"

  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  security_group_id = module.network.alb_sg_id
}

locals {
  ecr_base    = "228228360738.dkr.ecr.eu-west-2.amazonaws.com"
  region      = "eu-west-2"
  namespace   = module.ecs_cluster.service_connect_namespace
  rds_host    = split(":", module.rds.endpoint)[0]
  rds_port    = split(":", module.rds.endpoint)[1]

  common_env = {
    SPRING_PROFILES_ACTIVE              = "uat"
    CONFIG_SERVER_URL                   = "http://config-server:8888"
    LOG_PATH                            = "/logs"
    KAFKA_BOOTSTRAP                     = "kafka:9092"
    REDIS_HOST                          = module.redis.endpoint
    REDIS_PORT                          = "6379"
    PLATFORM_SCHEME                     = "http"
    PLATFORM_WS_SCHEME                  = "ws"
    USER_SERVICE_HOST                   = "user-service"
    CLOUD_RESILIENCE_SERVICE_HOST       = "cloud-resilience-service"
    REPORT_SERVICE_HOST                 = "report-service"
    NOTIFICATION_SERVICE_HOST           = "notification-service"
    FRONTEND_URL                        = "http://${module.alb.alb_dns_name}"
    CORS_ALLOWED_ORIGINS                = "http://${module.alb.alb_dns_name}"
    CORS_ALLOWED_METHODS                = "GET,POST,PUT,PATCH,DELETE,OPTIONS"
    CORS_ALLOWED_HEADERS                = "Authorization,Content-Type,Accept,X-Requested-With,X-API-KEY"
    CORS_EXPOSED_HEADERS                = "Authorization,Location,X-Total-Count"
    CORS_ALLOW_CREDENTIALS              = "true"
    SPRING_DATASOURCE_URL               = "jdbc:postgresql://${local.rds_host}:${local.rds_port}/${module.rds.db_name}"
    SPRING_DATASOURCE_USERNAME          = module.rds.db_username
    AZURE_OPENAI_ENDPOINT               = "https://replace-me.openai.azure.com/"
    AZURE_OPENAI_DEPLOYMENT_NAME        = "resilience-recommender"
    EMAIL_FROM_ADDRESS                  = "noreply@skyrunna.tech"
    EMAIL_FROM_NAME                     = "Sky Runna"
    EMAIL_SUPPORT_ADDRESS               = "support@skyrunna.com"
    EMAIL_BRAND_APP_URL                 = "http://${module.alb.alb_dns_name}"
  }

  common_secrets = {
    JWT_SECRET                         = module.ssm_secrets.parameter_arns["JWT_SECRET"]
    ENCRYPTION_KEY                     = module.ssm_secrets.parameter_arns["ENCRYPTION_KEY"]
    SPRING_DATASOURCE_PASSWORD         = module.ssm_secrets.parameter_arns["POSTGRES_PASSWORD"]
    APP_SEED_SUPER_ADMIN_PASSWORD_HASH = module.ssm_secrets.parameter_arns["APP_SEED_SUPER_ADMIN_PASSWORD_HASH"]
    RESILIENCE_SERVICE_API_KEY         = module.ssm_secrets.parameter_arns["RESILIENCE_SERVICE_API_KEY"]
    NOTIFICATION_SERVICE_API_KEY       = module.ssm_secrets.parameter_arns["NOTIFICATION_SERVICE_API_KEY"]
    REPORT_SERVICE_API_KEY             = module.ssm_secrets.parameter_arns["REPORT_SERVICE_API_KEY"]
    SENDGRID_API_KEY                   = module.ssm_secrets.parameter_arns["SENDGRID_API_KEY"]
    SPRING_MAIL_PASSWORD               = module.ssm_secrets.parameter_arns["SPRING_MAIL_PASSWORD"]
    FLUTTERWAVE_SECRET_KEY             = module.ssm_secrets.parameter_arns["FLUTTERWAVE_SECRET_KEY"]
    FLUTTERWAVE_PUBLIC_KEY             = module.ssm_secrets.parameter_arns["FLUTTERWAVE_PUBLIC_KEY"]
    FLUTTERWAVE_ENCRYPTION_KEY         = module.ssm_secrets.parameter_arns["FLUTTERWAVE_ENCRYPTION_KEY"]
  }
}

module "zookeeper" {
  source         = "../../modules/ecs-service"
  env            = "uat"
  cluster_id     = module.ecs_cluster.cluster_id
  service_name   = "zookeeper"
  image_url      = "confluentinc/cp-zookeeper:7.6.1"
  container_port = 2181
  cpu            = 512
  memory         = 1024
  region         = local.region

  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.ecs_sg_id]

  task_execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn           = module.ecs_cluster.task_role_arn
  log_group_name          = "/skyrunna/uat/zookeeper"

  service_connect_enabled   = true
  service_connect_namespace = local.namespace

  health_check_command = ["CMD-SHELL", "echo srvr | nc localhost 2181 | grep -q 'Zookeeper version' || exit 1"]

  environment_variables = {
    ZOOKEEPER_CLIENT_PORT = "2181"
    ZOOKEEPER_TICK_TIME   = "2000"
    ZOOKEEPER_4LW_COMMANDS_WHITELIST = "ruok,srvr,stat,mntr,conf,isro"
  }
}

module "kafka" {
  source         = "../../modules/ecs-service"
  env            = "uat"
  cluster_id     = module.ecs_cluster.cluster_id
  service_name   = "kafka"
  image_url      = "confluentinc/cp-kafka:7.6.1"
  container_port = 9092
  cpu            = 1024
  memory         = 2048
  region         = local.region

  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.ecs_sg_id]

  task_execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn           = module.ecs_cluster.task_role_arn
  log_group_name          = "/skyrunna/uat/kafka"

  service_connect_enabled   = true
  service_connect_namespace = local.namespace

  health_check_command = ["CMD-SHELL", "kafka-broker-api-versions --bootstrap-server localhost:9092 > /dev/null 2>&1 || exit 1"]

  environment_variables = {
    KAFKA_BROKER_ID                                = "1"
    KAFKA_ZOOKEEPER_CONNECT                        = "zookeeper:2181"
    KAFKA_LISTENERS                                = "PLAINTEXT://0.0.0.0:9092"
    KAFKA_ADVERTISED_LISTENERS                     = "PLAINTEXT://kafka:9092"
    KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR         = "1"
    KAFKA_TRANSACTION_STATE_LOG_MIN_ISR            = "1"
    KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR = "1"
    KAFKA_DEFAULT_REPLICATION_FACTOR               = "1"
    KAFKA_MIN_INSYNC_REPLICAS                      = "1"
  }
}

module "config_server" {
  source         = "../../modules/ecs-service"
  env            = "uat"
  cluster_id     = module.ecs_cluster.cluster_id
  service_name   = "config-server"
  image_url      = "${local.ecr_base}/skyrunna/config-server:latest"
  container_port = 8888
  cpu            = 512
  memory         = 1024
  region         = local.region

  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.ecs_sg_id]

  task_execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn           = module.ecs_cluster.task_role_arn
  log_group_name          = "/skyrunna/uat/config-server"

  service_connect_enabled   = true
  service_connect_namespace = local.namespace

  health_check_command = ["CMD-SHELL", "nc -z localhost 8888 || exit 1"]

  environment_variables = {
    CONFIG_REPO_LOCATION = "file:/config-repo"
    SERVER_PORT          = "8888"
    CONFIG_SERVER_PORT   = "8888"
  }
}

module "user_service" {
  source         = "../../modules/ecs-service"
  env            = "uat"
  cluster_id     = module.ecs_cluster.cluster_id
  service_name   = "user-service"
  image_url      = "${local.ecr_base}/skyrunna/user-service:latest"
  container_port = 8082
  cpu            = 512
  memory         = 1024
  region         = local.region

  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.ecs_sg_id]

  task_execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn           = module.ecs_cluster.task_role_arn
  log_group_name          = "/skyrunna/uat/user-service"

  service_connect_enabled   = true
  service_connect_namespace = local.namespace

  environment_variables = merge(local.common_env, {
    SERVER_PORT       = "8082"
    USER_SERVICE_PORT = "8082"
    LOGGING_LEVEL_ROOT = "DEBUG"
    LOGGING_LEVEL_COM_SKY_GUARD = "DEBUG"
    LOGGING_LEVEL_COM_SKY_GUARD_USER_SERVICE_SERVICE_AUTHENTICATIONSERVICE = "DEBUG"
    LOGGING_LEVEL_COM_SKY_GUARD_USER_SERVICE_CACHE_TOKENCACHE = "DEBUG"
    LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_DATA_REDIS = "DEBUG"
  })

  secrets = local.common_secrets
}

module "cloud_resilience_service" {
  source         = "../../modules/ecs-service"
  env            = "uat"
  cluster_id     = module.ecs_cluster.cluster_id
  service_name   = "cloud-resilience-service"
  image_url      = "${local.ecr_base}/skyrunna/cloud-resilience-service:latest"
  container_port = 8083
  cpu            = 512
  memory         = 1024
  region         = local.region

  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.ecs_sg_id]

  task_execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn           = module.ecs_cluster.task_role_arn
  log_group_name          = "/skyrunna/uat/cloud-resilience-service"

  service_connect_enabled   = true
  service_connect_namespace = local.namespace

  environment_variables = merge(local.common_env, {
    SERVER_PORT                    = "8083"
    CLOUD_RESILIENCE_SERVICE_PORT  = "8083"
    JAVA_OPTS                     = "-Dio.netty.handler.ssl.noOpenSsl=true"
  })

  secrets = local.common_secrets
}

module "report_service" {
  source         = "../../modules/ecs-service"
  env            = "uat"
  cluster_id     = module.ecs_cluster.cluster_id
  service_name   = "report-service"
  image_url      = "${local.ecr_base}/skyrunna/report-service:latest"
  container_port = 8084
  cpu            = 512
  memory         = 1024
  region         = local.region

  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.ecs_sg_id]

  task_execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn           = module.ecs_cluster.task_role_arn
  log_group_name          = "/skyrunna/uat/report-service"

  service_connect_enabled   = true
  service_connect_namespace = local.namespace

  environment_variables = merge(local.common_env, {
    SERVER_PORT          = "8084"
    REPORT_SERVICE_PORT  = "8084"
  })

  secrets = local.common_secrets
}

module "notification_service" {
  source         = "../../modules/ecs-service"
  env            = "uat"
  cluster_id     = module.ecs_cluster.cluster_id
  service_name   = "notification-service"
  image_url      = "${local.ecr_base}/skyrunna/notification-service:latest"
  container_port = 8085
  cpu            = 512
  memory         = 1024
  region         = local.region

  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.ecs_sg_id]

  task_execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn           = module.ecs_cluster.task_role_arn
  log_group_name          = "/skyrunna/uat/notification-service"

  service_connect_enabled   = true
  service_connect_namespace = local.namespace

  environment_variables = merge(local.common_env, {
    SERVER_PORT                  = "8085"
    NOTIFICATION_SERVICE_PORT    = "8085"
    management_health_mail_enabled = "false"
  })

  secrets = local.common_secrets
}

module "api_gateway_service" {
  source         = "../../modules/ecs-service"
  env            = "uat"
  cluster_id     = module.ecs_cluster.cluster_id
  service_name   = "api-gateway-service"
  image_url      = "${local.ecr_base}/skyrunna/api-gateway-service:latest"
  container_port = 8081
  cpu            = 512
  memory         = 1024
  region         = local.region

  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.ecs_sg_id]

  task_execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn           = module.ecs_cluster.task_role_arn
  log_group_name          = "/skyrunna/uat/api-gateway-service"

  target_group_arn = module.alb.gateway_target_group_arn

  service_connect_enabled   = true
  service_connect_namespace = local.namespace

  environment_variables = merge(local.common_env, {
    SERVER_PORT              = "8081"
    API_GATEWAY_SERVICE_PORT = "8081"
    LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_CLOUD_GATEWAY = "DEBUG"
    LOGGING_LEVEL_REACTOR_NETTY                     = "DEBUG"
    LOGGING_LEVEL_ROOT                              = "DEBUG"
  })

  secrets = local.common_secrets
}

module "frontend_app" {
  source         = "../../modules/ecs-service"
  env            = "uat"
  cluster_id     = module.ecs_cluster.cluster_id
  service_name   = "frontend-app"
  image_url      = "${local.ecr_base}/skyrunna/frontend-app:latest"
  container_port = 80
  cpu            = 256
  memory         = 512
  region         = local.region

  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.network.ecs_sg_id]

  task_execution_role_arn = module.ecs_cluster.task_execution_role_arn
  task_role_arn           = module.ecs_cluster.task_role_arn
  log_group_name          = "/skyrunna/uat/frontend-app"

  target_group_arn = module.alb.frontend_target_group_arn

  service_connect_enabled   = true
  service_connect_namespace = local.namespace

  environment_variables = {}
}

module "github_oidc" {
  source     = "../../modules/github-oidc"
  env        = "uat"
  github_org = "vincentainatech"
  github_repos = [
    "Skyrunna-Backend",
    "Skyrunna-Frontend"
  ]
}

module "monitoring" {
  source = "../../modules/monitoring"
  env    = "uat"

  alarm_email = ["vincentainatech@gmail.com", "nkwochaijeawele@gmail.com"]

  alb_arn_suffix                   = module.alb.alb_arn_suffix
  gateway_target_group_arn_suffix  = module.alb.gateway_target_group_arn_suffix
  frontend_target_group_arn_suffix = module.alb.frontend_target_group_arn_suffix
  rds_instance_id                  = module.rds.instance_id
  ecs_cluster_name                 = module.ecs_cluster.cluster_name

  ecs_service_names = [
    "config-server",
    "user-service",
    "cloud-resilience-service",
    "report-service",
    "notification-service",
    "api-gateway-service",
    "frontend-app",
    "kafka",
    "zookeeper"
  ]
}

module "dns" {
  source      = "../../modules/dns"
  env         = "uat"
  domain_name = "skyrunna.tech"
  subdomain   = ""

  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}