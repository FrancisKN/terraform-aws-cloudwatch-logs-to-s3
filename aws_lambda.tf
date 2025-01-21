data "archive_file" "lambda_function_subscription_filter_processor" {
  type        = "zip"
  source_dir  = "${var.src_dir}/kinesis-firehose-cloudwatch-logs-processor"
  output_path = "./${var.src_dir}/uploads/${var.prefix}subscription-filter-processor.zip"
  
  output_file_mode = "0666"
  
  excludes = [
    ".DS_Store",
    "__pycache__",
    "*.pyc",
  ]

  triggers = {
    src_dir_hash = sha256(join("", [for f in fileset("${var.src_dir}/kinesis-firehose-cloudwatch-logs-processor", "**") : filesha256("${var.src_dir}/kinesis-firehose-cloudwatch-logs-processor/${f}")]))
  }
}

resource "aws_lambda_function" "subscription_filter_processor" {
  filename         = data.archive_file.lambda_function_subscription_filter_processor.output_path
  function_name    = "${local.name}-subscription-filter-processor"
  role             = aws_iam_role.subscription_filter_processor.arn
  handler          = "lambda_function.handler"
  source_code_hash = data.archive_file.lambda_function_subscription_filter_processor.output_base64sha256
  runtime          = "python3.9"
  timeout          = var.subscription_filter_processor_timeout
  memory_size      = var.subscription_filter_processor_memory_size
  publish          = true

  tags = merge(
    var.tags,
    {
      Name = "${local.name}-subscription-filter-processor"
    }
  )
}

resource "aws_lambda_alias" "subscription_filter_processor" {
  name             = "subscription_filter_processor_latest"
  description      = "latest package"
  function_name    = aws_lambda_function.subscription_filter_processor.arn
  function_version = "$LATEST"
}

resource "aws_cloudwatch_log_group" "subscription_filter_processor" {
  name              = "/aws/lambda/${aws_lambda_function.subscription_filter_processor.function_name}"
  retention_in_days = var.subscription_filter_processor_log_group_retention_in_days
  kms_key_id        = aws_kms_key.this.arn
}
