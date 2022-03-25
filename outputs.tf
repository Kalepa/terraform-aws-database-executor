output "result" {
    description = "The output of the commands, as returned by the `fetchall` function."
    value = jsondecode(module.run_sql.stdout)
}
