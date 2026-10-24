resource "aws_lb" "web" {
  name               = "shop-web"
  load_balancer_type = "application"
  subnets            = [for s in aws_subnet.public : s.id]
  security_groups    = [aws_security_group.web.id]
}

resource "aws_lb_target_group" "web" {
  name        = "shop-web"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.web.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.web.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_acm_certificate" "web" {
  domain_name       = "shop.example.com"
  validation_method = "DNS"
}

resource "aws_security_group" "web" {
  name   = "shop-web"
  vpc_id = aws_vpc.main.id
}

resource "aws_ecs_cluster" "main" {
  name = "shop"
}

resource "aws_ecs_task_definition" "api" {
  family                   = "shop-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  container_definitions = jsonencode([{
    name  = "api"
    image = "${aws_ecr_repository.api.repository_url}:latest"
    environment = [
      { name = "DATABASE_HOST", value = aws_db_instance.main.address },
      { name = "QUEUE_URL", value = aws_sqs_queue.orders.url },
    ]
  }])
}

resource "aws_ecs_service" "api" {
  name            = "shop-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [for s in aws_subnet.private : s.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "api"
    container_port   = 8080
  }
}

resource "aws_ecr_repository" "api" {
  name = "shop-api"
}

resource "aws_sqs_queue" "orders" {
  name = "shop-orders"
}

resource "aws_lambda_function" "fulfilment" {
  function_name = "shop-fulfilment"
  runtime       = "nodejs22.x"
  handler       = "index.handler"
  role          = "arn:aws:iam::123456789012:role/shop-fulfilment"
  filename      = "fulfilment.zip"
}

resource "aws_lambda_event_source_mapping" "orders" {
  event_source_arn = aws_sqs_queue.orders.arn
  function_name    = aws_lambda_function.fulfilment.arn
}
