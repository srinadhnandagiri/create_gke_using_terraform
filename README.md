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

Also here i have used 3 secrets created in Secret Manager in GCP from which i am fetching creds like project id , Service Account 
and Image name which i pass in Start up script in bastion host .

By this way i can securely pass secrets .

At the end GCP Loadbalancer is created which we can hit with http://<lb-ip> to access nginx 
