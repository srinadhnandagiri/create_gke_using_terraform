variable "project" { }

variable "credentials_file" { }

variable "vpc_name" {
 default = "srinadh-gke-test"
 }
variable "subnet_name" {
 default = "srinadh-subnet"
 }
variable "cidr_range" { }
variable "master_cidr_range" { }
variable "region" {
  default = "asia-south1"
}

variable "zone" {
  default = "asia-south1-c"
}
variable "gke_cluster_name" {
  default = "srinadh-test-cluster"
 }
variable "machine_type" {
  default = "n1-standard-1"
}
variable "disk_size" {
  default = 10
}
variable "image_type" {
  default = "UBUNTU_CONTAINERD"
}
variable "cloud_router_name" {
  default = "srinadh-cloud-router"
 }
variable "nat_gateway_name" {
  default = "srinadh-nat-gateway"
 }
variable "bastion_host_name" {
  default = "srinadh-bastion-host"
 }
variable "bastion_host_machine_type" {
  default = "e2-micro"
}
variable "bastion_host_image" {
  default = "debian-cloud/debian-11"
}
variable "iap_firewall_name" {
  default = "srinadh-iap-ssh"
 }
variable "bastion_host_service_account" { }
variable "iap_ssh_port" {
  default = 22
}
variable "iap_ssh_cidr" {
  default = "35.235.240.0/20"
}
variable "iap_ssh_tag" {
  default = "iap"
}
