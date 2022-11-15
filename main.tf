###############################
# Function & Subscription
###############################
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${var.function_name}.zip"
}

resource "aws_lambda_function" "function" {
  provider         = aws.us_east_1
  function_name    = var.function_name
  filename         = "${var.function_name}.zip"
  role             = var.iam_role_arn
  handler          = var.function_handler
  source_code_hash = data.archive_file.function_zip.output_base64sha256
  runtime          = var.function_runtime
  publish          = true
}

resource "aws_lambda_alias" "function_alias" {
  provider         = aws.us_east_1
  name             = var.alias_name
  function_name    = aws_lambda_function.function.function_name
  function_version = aws_lambda_function.function.version
}

###############################
# Trigger Permission
###############################
resource "aws_lambda_permission" "lambda_from_cloudfront" {
  provider      = aws.us_east_1
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.arn
  principal     = "cloudfront.amazonaws.com"
}

###############################
# Logging
###############################
resource "aws_cloudwatch_log_group" "function_log_group" {
  provider          = aws.us_east_1
  name              = "/aws/lambda/${aws_lambda_function.function.function_name}"
  retention_in_days = 14
}

# !!! - It's unclear how the lambda function knows to log to the correct log group

###############################
# Module outputs
###############################

output "function_arn" {
  value = aws_lambda_function.function.arn
}

output "qualified_arn" {
  value = aws_lambda_function.function.qualified_arn
}
