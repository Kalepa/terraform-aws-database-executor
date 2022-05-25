variable "lambda_shell" {
  description = "The Lambda Shell module to use for running the command."
  type        = any
}

variable "is_resource" {
  description = "Whether to do the execution as a resource. If `false`, it will be done as a data source instead (re-runs on every plan/apply)."
  type        = bool
}

variable "db_type" {
  description = "The type of database (postgresql, mysql, etc.)."
  type        = string
  validation {
    condition     = contains(["postgresql", "mysql"], var.db_type)
    error_message = "The `db_type` variable must be either `postgresql` or `mysql`."
  }
}

variable "db_secret_arn" {
  description = "The ARN of the Secrets Manager secret that holds the credentials for connecting to the database."
  type        = string
  default     = null
}

variable "db_host" {
  description = "The database endpoint to connect to. If no value is provided, it will look for a `host` field in the database secret."
  type        = string
  default     = null
}

variable "db_port" {
  description = "The database port to connect to. If no value is provided, it will look for a `port` field in the database secret."
  type        = number
  default     = null
}

variable "db_user" {
  description = "The database user to connect with. If no value is provided, it will look for a `username` field in the database secret."
  type        = string
  default     = null
}

variable "db_password" {
  description = "The database password to connect with. If no value is provided, it will look for a `password` field in the database secret."
  type        = number
  default     = null
}

variable "db_name" {
  description = "The database name (schema) to connect to. If no value is provided, it will look for a `dbname` field in the database secret."
  type        = string
  default     = null
}

variable "statements" {
  description = "The statements that should be executed. Each one consists of an SQL query (which can optionally contain placeholders), a data list or map (which contains the values for those placeholders), and an optional list of exception names that will be caught and ignored (e.g. \"DuplicateDatabase\" to catch and ignore the `psycopg2.errors.DuplicateDatabase` exception)."
  type = list(object({
    sql                  = string
    data                 = any
    permitted_exceptions = optional(list(string))
  }))
  default = []
  validation {
    condition     = var.statements != null
    error_message = "The `statements` variable must not be `null`."
  }
}

variable "timeout" {
  description = "An optional timeout to apply to the statements. Note that this timeout is for all statements, not each statement individually. If not specified, no timeout will be applied (but it will still be subject to the timeout of the Lambda shell function)."
  type        = number
  default     = null
}

variable "commit_independently" {
  description = "Whether each individual statement should be committed immediately after completion, or whether they should all be committed at once if they all succeed."
  type        = bool
  default     = false
  validation {
    condition     = var.commit_independently != null
    error_message = "The `commit_independently` variable must not be `null`."
  }
}

variable "dictionary_result" {
  description = "Whether results should be provided in dictionary format (column_name => value) instead of the default tuple format."
  type        = bool
  default     = false
  validation {
    condition     = var.dictionary_result != null
    error_message = "The `dictionary_result` variable must not be `null`."
  }
}

variable "triggers" {
  description = "A map of arbitrary keys and values that, when changed, will trigger the statements to be re-run."
  type        = any
  default     = null
}

variable "suppress_console" {
  type        = bool
  default     = true
  description = "Whether to suppress the Terraform console output (including plan content and shell execution status messages) for this module. If enabled, much of the content will be hidden by marking it as \"sensitive\"."
}

variable "log_event" {
  type        = bool
  default     = false
  description = "Whether to log input events in CloudWatch logs. `false` by default to reduce risk of secrets being exposed in logs."
  validation {
    condition     = var.log_event != null
    error_message = "The `log_event` variable must not be `null`."
  }
}
