/*KUBERNETES-INFASTRUCTURE*/

#Kubernetes-Provider
provider "kubernetes" {
  config_path = "~/.kube/config"
}
#>>>

#Service-Layer-Controls
resource "google_container_cluster" "fleet-1" {
  name     = "atreides-war-fleet"#
  location = google_compute_subnetwork.sub-1.region

  networking_mode = "VPC_NATIVE" #Specifies the default networking mode for the cluster
    network       = google_compute_network.net-1.id
    subnetwork    = google_compute_subnetwork.sub-1.id

  remove_default_node_pool = true
    initial_node_count = 1

  release_channel {
    channel = "REGULAR" # (RAPID,REGULAR,STABLE) specifies how Frequently the cluster will be updated
  }
#>>>
  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-axii"
    services_secondary_range_name = "service-vesimir"
  }
#>>>  
  network_policy {
    provider = "PROVIDER_UNSPECIFIED"
    enabled  = true
  }
#>>>
  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28"#
  }
  deletion_protection = false #Don't Forget this so you can tear down.

    workload_identity_config {
    workload_pool = "pooper-scooper.svc.id.goog"
  }
}
#>>>>>

#I AM WORKLOAD IDENTITY
resource "google_service_account_iam_member" "bucket-head" {
  service_account_id = "projects/pooper-scooper/serviceAccounts/876288284083-compute@developer.gserviceaccount.com"
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:pooper-scooper.svc.id.goog[staging/bucket-head]"
}
#>>>>>

#Node-Pools
resource "google_container_node_pool" "node-pool-1" {
  name       = "sardaukar"#
  location   = google_compute_subnetwork.sub-1.region
  cluster    = google_container_cluster.fleet-1.name
  node_count = 1

  autoscaling {
    min_node_count = 1#
    max_node_count = 3#
  }
  management {
    auto_repair  = true#
    auto_upgrade = true#
  }
  #>>>>>
    node_config {     
    machine_type    = "e2-medium"#  
    labels = {
      role = "sardaukar"
    }
    service_account = "876288284083-compute@developer.gserviceaccount.com"#
    oauth_scopes    = [ # Defines outside services which can help manage cluster at extra cost:
      /*"https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",*/
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
#>>>>>

/*
Refer to the below diagram  for an intuitive Visulization of the Kubernetes Cluster. 
 
1. The Control plane is the master node that manages and administer's settings and configurations for the worker nodes.
- Note --> Issuing commandds in kubectl communicates with the API server, which in turn communicates with the control plane.

2. The Service Layer acts as an endpoint and a load balancer for the worker nodes, and directs inbound client traffic based on the configured labels, and cluster IP.

3. The kube-proxy: Maintains network rules on nodes, allowing network communication to pods from inside or outside the cluster.

+----------------------------------------------------------+
|                   Kubernetes Cluster                     |
|                                                          |
|  +------------------------+     +---------------------+  |
|  |   Control Plane Node   |     |     Worker Node     |  |
|  |                        |     |                     |  |
|  |  +------------------+  +-----+  +---------------+  |  |
|  |  |    API Server    |  >>>>>>>  |    kubelet    |  |  |
|  |  +------------------+  +-----+  +---------------+  |  |
|  |  |    Controller    |  |     |  |   kube-proxy  |  |  |
|  |  |      Manager     |  |     |  +---------------+  |  |
|  |  +------------------+  |     |  |      Pods     |  |  |
|  |  |     Scheduler    |  |     |  |               |  |  |
|  |  +------------------+  |     |  |  +----------+ |  |  |
|  |  |       etcd       |  |     |  |  | Pod A1   | |  |  |
|  |  +------------------+  |     |  |  | IP:      | |  |  |
|  |                        |     |  |  | 10.1.1.1 | |  |  |
|  +----------|v|-----------+     |  |  | label:   | |  |  |
|             |v|                 |  |  | app=a    | |  |  |
|  +--------- |v|-----------+     |  |  +----------+ |  |  |
|  |      Worker Node       |     |  |  +----------+ |  |  |
|  |                        |     |  |  | Pod A2   | |  |  |
|  |  +---------------+     |     |  |  | IP:      | |  |  |
|  |  |    kubelet    |     |     |  |  | 10.1.1.2 | |  |  |
|  |  +---------------+     |     |  |  | label:   | |  |  |
|  |  |   kube-proxy  |     |     |  |  | app=a    | |  |  |
|  |  +---------------+     |     |  |  +----------+ |  |  |
|  |  |      Pods     |     |     |  |               |  |  |
|  |  |               |     |     |  +---------------+  |  |
|  |  |  +----------+ |     |     |                     |  |
|  |  |  | Pod B1   | |     |     +----------^----------+  |
|  |  |  | IP:      | |     |                |             |
|  |  |  | 10.1.2.1 | |     |                |             |
|  |  |  | label:   | |     |                |             |
|  |  |  | app=b    | |     |                *             |
|  |  |  +----------+ |     |                |             |
|  |  +---------------+     |                |             |
|  +----------^-------------+                |             |
|  +----------|------------------------------v----------+  |
|  |          v         Service Layer                   |  |
|  |  +----------------------------------------------+  |  |
|  |  |   Service A (10.96.0.1)                      |  |  |
|  |  |   Cluster IP: 10.96.0.1                      |  |  |
|  |  |   Selects Pods: label: app=a                 |  |  |
|  |  +----------------------------------------------+  |  |
|  |  +----------------------------------------------+  |  |
|  |  |   Service B (10.96.0.2)                      |  |  |
|  |  |   Cluster IP: 10.96.0.2                      |  |  |
|  |  |   Selects Pods: label: app=b                 |  |  |
|  |  +----------------------------------------------+  |  |
|  +----------------------------------------------------+  |
+----------------------------------------------------------+

SEE BELOW FOR LIFECYCLE OF ISSUING COMMANDS THROUGH KUBECTL

+-----------------------------+
|       kubectl command       |
|     (e.g., kubectl get pods)|
+-------------+---------------+
              |
              v
+-------------+---------------+
|        kubeconfig file       |
|  (authentication details)    |
+-------------+---------------+
              |
              v
+-------------+---------------+
|       Kubernetes API Server  |
|  (validates authentication)  |
+-------------+---------------+
              |
              v
+-------------+---------------+
|     Authentication Mechanism |
|  (e.g., certs, tokens, etc.) |
+-------------+---------------+
              |
              v
+-------------+---------------+
| Authorization Mechanism (RBAC)|
|  (checks permissions)         |
+-------------+---------------+
              |
              v
+-------------+---------------+
|        Cluster Operations    |
|  (e.g., list pods, deploy)   |
+-----------------------------+
*/


