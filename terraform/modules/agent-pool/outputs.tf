# =============================================================================
# modules/agent-pool/outputs.tf
# =============================================================================

output "pool_id" {
  value       = azuredevops_agent_pool.this.id
  description = "Numeric Azure DevOps agent pool ID."
}

output "pool_name" {
  value       = azuredevops_agent_pool.this.name
  description = "Agent pool name (Pool-tee-{env}-eus-01). Must match the poolName variable in pipeline YAML."
}

output "queue_id" {
  value       = azuredevops_agent_queue.this.id
  description = "Agent queue ID within the target project."
}
