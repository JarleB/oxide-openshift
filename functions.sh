function fetch_master_backends {
  jq '.resources[].instances[].attributes|select(.host_name)|select(.host_name| startswith("boot"))| "server \(.name) \(.network_interfaces[0].ip_address):6443 check"' -r < terraform.tfstate
  jq '.resources[].instances[].attributes|select(.host_name)|select(.host_name| startswith("cp"))| "server \(.name) \(.network_interfaces[0].ip_address):6443 check"' -r < terraform.tfstate
}


function fetch_worker_backends {
  jq '.resources[].instances[].attributes|select(.host_name)|select(.host_name| startswith("work"))| "server \(.name) \(.network_interfaces[0].ip_address):443 check"' -r < terraform.tfstate
}
