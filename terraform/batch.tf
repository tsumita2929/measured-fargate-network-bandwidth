#############################################################################
# AWS Batch Compute Environment
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/batch_compute_environment.html
#############################################################################
resource "aws_iam_role" "aws_batch_service_role" {
  name = "aws_batch_service_role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
        "Service": "batch.amazonaws.com"
        }
    }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "aws_batch_service_role" {
  role       = aws_iam_role.aws_batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_batch_compute_environment" "BatchComputeEnvironment" {
  compute_environment_name = "measured-fargate-network-bandwidth-compute-env"
  type                     = "MANAGED"
  state                    = "ENABLED"
  service_role             = aws_iam_role.aws_batch_service_role.arn
  compute_resources {
    type      = "FARGATE_SPOT"
    max_vcpus = 256
    subnets = [
      module.vpc.public_subnets[0]
    ]
    security_group_ids = [
      aws_security_group.EC2SecurityGroup.id
    ]
  }
  depends_on = [aws_iam_role_policy_attachment.aws_batch_service_role]
}

#############################################################################
# AWS Batch Job definitnion
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/batch_job_definition.html
#############################################################################
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "tf_batch_exec_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
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

# For container pull from ECR public
data "aws_iam_policy" "AmazonEC2ContainerRegistryReadOnly" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy1" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy2" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = data.aws_iam_policy.AmazonEC2ContainerRegistryReadOnly.arn
}

resource "aws_batch_job_definition" "BatchJobDefinition" {
  name = "measured-fargate-network-bandwidth-job-definition"
  type = "container"
  platform_capabilities = [
    "FARGATE",
  ]
  container_properties = <<CONTAINER_PROPERTIES
{
  "image": "${var.iperf3_container_image_url}",
  "command": ["-c", "10.0.10.100", "-t", "30", "-V"],
  "resourceRequirements": [
    {
      "value": "1.0",
      "type": "VCPU"
    },
    {
      "value": "2048",
      "type": "MEMORY"
    }
  ],
  "logConfiguration": {
    "logDriver": "awslogs"
  },
  "networkConfiguration": {
    "assignPublicIp": "ENABLED"
  },
  "fargatePlatformConfiguration": {
    "platformVersion": "LATEST"
  },
  "executionRoleArn": "${aws_iam_role.ecs_task_execution_role.arn}"
}
CONTAINER_PROPERTIES
}

#############################################################################
# AWS Batch Job Queue
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/batch_job_queue.html
#############################################################################

resource "aws_batch_job_queue" "BatchJobQueue" {
  compute_environments = [aws_batch_compute_environment.BatchComputeEnvironment.arn]
  priority             = 1
  state                = "ENABLED"
  name                 = "measured-fargate-network-bandwidth-job-queue"
}
