/*NETWORK*/

#Host-Network
resource "google_compute_network" "net-1" {
  name                    = "griffin-school-network"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  mtu                     = 1500
}
#>>>

#Subnet-1
resource "google_compute_subnetwork" "sub-1" {
  name          = "kaer-seren-main"#
  ip_cidr_range = "10.132.0.0/20"#
  region        = "europe-west10"#
  network       = google_compute_network.net-1.id
  private_ip_google_access = "true"
#>>>

#Secondary Ranges --> For Kubernetes
  secondary_ip_range {
    range_name    = "pod-axii" #Ranges for Pod addressing
    ip_cidr_range = "10.4.0.0/14"#
  }
  #>>>
  secondary_ip_range {
    range_name    = "service-vesimir" #Ranges for Service addressing
    ip_cidr_range = "10.8.0.0/20"#
  }  
}
#>>>>>

/*FIREWALL RULES*/

#Ingress-rule
resource "google_compute_firewall" "http-ingress" {
  name        = "public-transit"
  network     = google_compute_network.net-1.id
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}
#>>>

#Health-Check
resource "google_compute_firewall" "health" {
  name        = "sook-doctor"
  network     = google_compute_network.net-1.id
  allow {
    protocol = "tcp"
    ports    = ["10256"]
  }

  source_ranges = ["130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22", "35.191.0.0/16"]
}
#>>>

#Allow IAP Access For Instance Management
resource "google_compute_firewall" "allow_iap" {
  name    = "secret-service"
  network = google_compute_network.net-1.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = data.google_netblock_ip_ranges.iap_forwarders.cidr_blocks_ipv4
  target_tags   = ["allow-iap"]
}
#>>>
#IAP-CONFIGURATION
data "google_netblock_ip_ranges" "iap_forwarders" {
  range_type = "iap-forwarders"
}
#>>>>>



