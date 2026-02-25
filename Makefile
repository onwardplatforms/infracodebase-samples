AWS_BOOTSTRAP_DIR   = samples/aws-remote-state-bootstrap
AWS_VPC_DIR         = samples/aws-vpc-stack
AZURE_BOOTSTRAP_DIR = samples/azure-bootstrap
AZURE_WEBAPP_DIR    = samples/azure-webapp-stack

# Terraform service principal app (client) ID
TF_SP_CLIENT_ID    ?= d6d0a83f-024b-4958-9765-b026321dcdfa

.PHONY: aws-bootstrap aws-bootstrap-destroy \
        aws-vpc aws-vpc-destroy \
        aws-up aws-down \
        azure-bootstrap azure-bootstrap-destroy \
        azure-webapp azure-webapp-destroy \
        azure-up azure-down \
        all-up all-down

# --- AWS ---

aws-bootstrap:
	cd $(AWS_BOOTSTRAP_DIR) && terraform init && terraform apply -auto-approve

aws-bootstrap-destroy:
	cd $(AWS_BOOTSTRAP_DIR) && terraform destroy -auto-approve

aws-vpc:
	cd $(AWS_VPC_DIR) && terraform init && terraform apply -auto-approve

aws-vpc-destroy:
	cd $(AWS_VPC_DIR) && terraform destroy -auto-approve

aws-up: aws-bootstrap aws-vpc

aws-down: aws-vpc-destroy aws-bootstrap-destroy

# --- Azure ---

azure-bootstrap:
	cd $(AZURE_BOOTSTRAP_DIR) && terraform init && terraform apply -auto-approve \
		-var="terraform_sp_client_id=$(TF_SP_CLIENT_ID)"

azure-bootstrap-destroy:
	cd $(AZURE_BOOTSTRAP_DIR) && terraform destroy -auto-approve \
		-var="terraform_sp_client_id=$(TF_SP_CLIENT_ID)"

azure-webapp:
	cd $(AZURE_WEBAPP_DIR) && terraform init && terraform apply -auto-approve \
		-var="bootstrap_key_vault_id=$$(cd ../azure-bootstrap && terraform output -raw key_vault_id)" \
		-var="terraform_sp_client_id=$(TF_SP_CLIENT_ID)"

azure-webapp-destroy:
	cd $(AZURE_WEBAPP_DIR) && terraform destroy -auto-approve \
		-var="bootstrap_key_vault_id=$$(cd ../azure-bootstrap && terraform output -raw key_vault_id)" \
		-var="terraform_sp_client_id=$(TF_SP_CLIENT_ID)"

azure-up: azure-bootstrap azure-webapp

azure-down: azure-webapp-destroy azure-bootstrap-destroy

# --- All ---

all-up: aws-up azure-up

all-down: azure-down aws-down
