### Usage Example

```hcl
# main.tf
module "automation_runbook" {
  source = "./modules/automation_runbook"

  runbook_name            = "RB001"
  resource_group_name     = "rg001"
  automation_account_name = "aaa001"
  script_file_path        = "./psscriptfile.ps1"
  location                = "westeurope"
  description             = "My PowerShell Runbook"
  log_verbose             = true
  log_progress            = true
  hybrid_worker_group     = "aahwg001"
  
  # Parameters to be passed to the runbook
  rg_name_param  = "rg001"
  kv_name_param  = "kv001"
  key_name_param = "key001"

  tags = {
    Environment = "Production"
    CreatedBy   = "Terraform"
  }
}
```
