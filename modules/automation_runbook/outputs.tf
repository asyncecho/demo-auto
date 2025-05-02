# modules/automation_runbook/outputs.tf
output "runbook_id" {
  description = "The ID of the Automation Runbook"
  value       = azurerm_automation_runbook.runbook.id
}

output "runbook_name" {
  description = "The name of the Automation Runbook"
  value       = azurerm_automation_runbook.runbook.name
}

output "schedule_id" {
  description = "The ID of the Automation Schedule"
  value       = azurerm_automation_schedule.schedule.id
}

output "job_schedule_id" {
  description = "The ID of the Job Schedule linking the runbook and schedule"
  value       = azurerm_automation_job_schedule.job_schedule.id
}