output "results" {
  description = "The output of the commands, as returned by the `fetchall` function. The order matches the order of the statements."
  value       = jsondecode(trimspace(length(module.run_sql_resource) > 0 ? module.run_sql_resource[0].stdout : module.run_sql_data[0].stdout))
}
