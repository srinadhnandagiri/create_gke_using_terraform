# create_gke_using_terraform
This repo contains terraform code to create gke resources and clones another repo which contains terraform code to 
deploy kubernetes objects to gke and apply that in start up script of the bastion host .
This repo contains main.tf and variables.tf file and you need to generate terraform.tfvars file before applying the configuration 
terraform.tfvars template 
project = "<your-gcp-project-id>"
credentials_file = "<path-to-creds-file-used-by-terraform>"
master_cidr_range = "<gke-cluster-master-cidr>"
cidr_range = "<subnet-cidr>"
bastion_host_service_account = "<service-account-of-bastion>"

Here Service acoount created by bastion is crucial because it should contain access to gke cluster for deploying objects to gke .
