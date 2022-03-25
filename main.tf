module "statements_json" {
  source  = "Invicton-Labs/jsonencode-no-replacements/null"
  version = "~>0.1.1"
  object = var.statements
}

module "run_sql" {
  source  = "Invicton-Labs/lambda-shell-resource/aws"
  version = "~> 0.2.0"

  // Pass in the Lambda Shell module
  lambda_shell_module = var.lambda_shell

  // Run the command using the Python interpreter
  interpreter = ["python3"]

  // Load the command/script from a file
  command = file("${path.module}/execute.py")
  
  environment = merge(
    var.db_host == null ? {} : {DB_HOST = var.db_host},
    var.db_port == null ? {} : {DB_PORT = var.db_port},
    var.db_user == null ? {} : {DB_USER = var.db_user},
    var.db_password == null ? {} : {DB_PASSWORD = var.db_password},
    var.db_name == null ? {} : {DB_NAME = var.db_name},
    {
      DB_COMMIT_INDEPENDENTLY = jsonencode(var.commit_independently)
      DB_STATEMENTS = module.statements_json.encoded
      DB_DICTIONARY_RESULT = jsonencode(var.dictionary_result)
    }
  )
  sensitive_environment = var.db_secret_arn == null ? {} : {DB_SECRET_ARN = var.db_secret_arn}

  timeout = var.timeout

  // Cause Terraform to fail if the function throws an error when creating the resource
  fail_on_nonzero_exit_code = true
  fail_on_stderr = true
  fail_on_timeout = true
}
