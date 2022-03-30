module "statements_json" {
  source  = "Invicton-Labs/jsonencode-no-replacements/null"
  version = "~>0.1.1"
  object  = var.statements
}

module "run_sql_resource" {
  source  = "Invicton-Labs/lambda-shell-resource/aws"
  version = "~> 0.3.0"

  count = var.is_resource ? 1 : 0

  // Pass in the Lambda Shell module
  lambda_shell_module = var.lambda_shell

  // Run the command using the Python interpreter
  interpreter = ["python3"]

  // Load the command/script from a file
  command = file("${path.module}/execute.py")

  environment = merge(
    var.db_host == null ? {} : { DB_HOST = var.db_host },
    var.db_port == null ? {} : { DB_PORT = var.db_port },
    var.db_user == null ? {} : { DB_USER = var.db_user },
    var.db_name == null ? {} : { DB_NAME = var.db_name },
    var.db_secret_arn == null ? {} : { DB_SECRET_ARN = var.db_secret_arn },
    {
      DB_COMMIT_INDEPENDENTLY = jsonencode(var.commit_independently)
      DB_STATEMENTS           = module.statements_json.encoded
      DB_DICTIONARY_RESULT    = jsonencode(var.dictionary_result)
      DB_TYPE                 = var.db_type
    }
  )
  sensitive_environment = var.db_password == null ? {} : { DB_PASSWORD = var.db_password }

  timeout = var.timeout

  suppress_console = var.suppress_console

  triggers = var.triggers

  log_event = var.log_event

  // Cause Terraform to fail if the function throws an error when creating the resource
  fail_on_nonzero_exit_code = true
  fail_on_stderr            = true
  fail_on_timeout           = true
}

module "run_sql_data" {
  source  = "Invicton-Labs/lambda-shell-data/aws"
  version = "~> 0.2.2"

  count = var.is_resource ? 0 : 1

  // Pass in the Lambda Shell module
  lambda_shell_module = var.lambda_shell

  // Run the command using the Python interpreter
  interpreter = ["python3"]

  // Load the command/script from a file
  command = file("${path.module}/execute.py")

  environment = merge(
    var.db_host == null ? {} : { DB_HOST = var.db_host },
    var.db_port == null ? {} : { DB_PORT = var.db_port },
    var.db_user == null ? {} : { DB_USER = var.db_user },
    var.db_name == null ? {} : { DB_NAME = var.db_name },
    var.db_secret_arn == null ? {} : { DB_SECRET_ARN = var.db_secret_arn },
    {
      DB_COMMIT_INDEPENDENTLY = jsonencode(var.commit_independently)
      DB_STATEMENTS           = module.statements_json.encoded
      DB_DICTIONARY_RESULT    = jsonencode(var.dictionary_result)
      DB_TYPE                 = var.db_type
    }
  )
  sensitive_environment = var.db_password == null ? {} : { DB_PASSWORD = var.db_password }

  timeout = var.timeout

  suppress_console = var.suppress_console

  log_event = var.log_event

  // Cause Terraform to fail if the function throws an error when creating the resource
  fail_on_nonzero_exit_code = true
  fail_on_stderr            = true
  fail_on_timeout           = true
}
