resource "aws_dynamodb_table" "default" {
  name         = "web-app-UserData"
  hash_key     = "userId"
  billing_mode = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "name"
    type = "S"
  }

  global_secondary_index {
    name            = "email-index"
    hash_key        = "email"
    projection_type = "ALL"
    read_capacity   = 1
    write_capacity  = 1
  }

  global_secondary_index {
    name            = "name-index"
    hash_key        = "name"
    projection_type = "ALL"
    read_capacity   = 1
    write_capacity  = 1
  }
}

resource "aws_dynamodb_table_item" "default" {
    table_name = aws_dynamodb_table.default.name
    hash_key   = "userId"
    item = <<ITEM
    {
        "userId": {"S": "1"},
        "email": {"S": "user@example.com"},
        "name": {"S": "John Doe"}
    }
    ITEM
}

