# Terraform AWS Database Executor

This module runs one or more database queries against an AWS database (MySQL or PostgreSQL) that is private and not accessible from the machine running Terraform. It externally uses the [Kalepa/lambda-shell/aws](https://registry.terraform.io/modules/Kalepa/lambda-shell/aws/latest) module to create the Lambda, and internally uses the [Kalepa/lambda-shell-data/aws](https://registry.terraform.io/modules/Kalepa/lambda-shell-data/aws/latest) and [Kalepa/lambda-shell-resource/aws](https://registry.terraform.io/modules/Kalepa/lambda-shell-resource/aws/latest) modules to execute a custom Python wrapper script.

This module currently supports MySQL and PostgreSQL, although only PostgreSQL has been tested and debugged currently.

Usage example is a work-in-progress and will be added soon.
