terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}

# create a vpc 
resource "google_compute_network" "vpc_network" {
  name = var.vpc_name
  auto_create_subnetworks = false
}
# Create a  subnet
resource "google_compute_subnetwork" "my_subnet" {
  name          = var.subnet_name
  network       = google_compute_network.vpc_network.self_link
  ip_cidr_range = var.cidr_range
  region        = var.region # Set your desired GCP region
}
# create firewall rule
resource "google_compute_firewall" "my_firewall" {
  name    = var.iap_firewall_name
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = [var.iap_ssh_port]
  }

  source_ranges = [var.iap_ssh_cidr]  # Allow traffic from any source IP (update as needed)

  target_tags = [var.iap_ssh_tag]
}

#creating gke cluster
resource "google_container_cluster" "gke_cluster" {
  name     = var.gke_cluster_name
  location = var.region
  
  remove_default_node_pool = true

  initial_node_count = 3
  node_locations     = ["asia-south1-a", "asia-south1-b"]

  logging_service   = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  network    = google_compute_network.vpc_network.self_link
  subnetwork = google_compute_subnetwork.my_subnet.self_link
  master_authorized_networks_config { 
   }
  ip_allocation_policy {
   }
  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = true
    master_ipv4_cidr_block = var.master_cidr_range
  }

  node_config {
    resource_labels   = {
             "env" = "experiment"
            }
    machine_type = var.machine_type
    disk_type    = "pd-balanced"
    disk_size_gb = var.disk_size
    image_type   = var.image_type

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }
}

resource "google_container_node_pool" "gke_node_pool" {
  name       = "srinadh-gke-test-nodepool"
  location   = google_container_cluster.gke_cluster.location
  cluster    = google_container_cluster.gke_cluster.name
  node_count = 1

  node_config {
    resource_labels   = {
              "env" = "experiment"
            }
    machine_type = var.machine_type
    disk_type    = "pd-balanced"
    disk_size_gb = var.disk_size
    image_type   = var.image_type
  }
}
# creating static ip for cloud nat 
resource "google_compute_address" "srinadh-cloud-nat" {
  name = "srinadh-cloud-nat"
  region = "asia-south1"
  description = "testing nat gateway ip "
  # Other configuration options as needed
}

#creating cloud router and nat 
resource "google_compute_router" "gke_cloud_router" {
  name    = var.cloud_router_name
  network = google_compute_network.vpc_network.self_link
  region  = var.region
}

#creating cloud nat 
resource "google_compute_router_nat" "gke_nat_gateway" {
  name    = var.nat_gateway_name
  router  = google_compute_router.gke_cloud_router.name
  region  = var.region
  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips = [google_compute_address.srinadh-cloud-nat.self_link] 
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Creating bastion host 
resource "google_compute_instance" "gke_bastion_host" {
  name         = var.bastion_host_name
  machine_type = var.bastion_host_machine_type
  zone         = var.zone
  labels = {
    "env" = "experiment"
        }

  boot_disk {
    initialize_params {
      image = var.bastion_host_image
    }
  }
  allow_stopping_for_update = true
  network_interface {
    network = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.my_subnet.name
    access_config {
      // Ephemeral IP
    }
  }
  service_account {
    email = var.bastion_host_service_account
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ] 
 }
  tags = [var.iap_ssh_tag]
  metadata = {
    startup-script = <<-EOF
      #!/bin/bash
      echo "Hello, World! This is a startup script running on the instance."
      sudo wget https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip
      sudo apt-get install -y unzip
      sudo unzip terraform_1.7.5_linux_amd64.zip
      sudo mv terraform /usr/local/bin/
      sudo terraform -version
      sudo apt-get install -y git
      sudo git clone https://github.com/srinadhnandagiri/deploy_gke_using_terraform.git /opt/terraform-repo
      cd /opt/terraform-repo
      sudo gcloud secrets versions access 1  --secret="srinadh-test-json" > sa.json
      project_id=$(sudo gcloud secrets versions access 1  --secret="project-id")
      image_name=$(sudo gcloud secrets versions access 1  --secret="image-name")
      sudo terraform init
      sudo terraform apply -auto-approve -var="project=$(sudo gcloud secrets versions access 1  --secret="project-id")" -var="path_to_json=sa.json" -var="image_name=$(sudo gcloud secrets versions access 1  --secret="image-name")"
    EOF
  }
}
