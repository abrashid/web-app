resource "aws_lambda_function" "lambda_function" {
  filename      = data.archive_file.lambda.output_path
  function_name = "retrieve_user_data"
  description   = "Lambda function to retrieve data from DynamoDB"
  handler       = "index.mjs"
  runtime       = "nodejs22.x"
  role          = aws_iam_role.lambda_role.arn
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "index.mjs"
  output_path = "lambda_function_payload.zip"
}

resource "aws_iam_role" "lambda_role" {
  name               = "retrieve_data_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "dynamodb_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}