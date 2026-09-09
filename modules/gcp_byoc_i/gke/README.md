# Initial node counts

Node-group `desired_size` and `min_size` are totals across all `gcp_zones`. GKE's `initial_node_count` is a count **per zone**. By default this module initializes `ceil(max(desired_size, min_size) / number_of_zones)` nodes per zone.

For a total of 3 nodes across 3 zones, initialization creates 1 node per zone (3 total), rather than 3 per zone (9 total). With a total of 3 across 2 zones, initialization creates 2 per zone (4 total). Non-divisible totals can exceed the requested total by up to `number_of_zones - 1`; GKE autoscaling subsequently adjusts capacity within the configured total limits. This change does not eliminate every startup scale-down, particularly when the requested total is smaller than the number of zones.

An explicit `node_initial_count` retains its existing per-zone semantics, including zero. Autoscaling total limits and node locations are unchanged. The existing lifecycle `ignore_changes = [initial_node_count]` remains in place, so this default change does not resize existing node pools.

Run the provider-mocked regression tests without cloud credentials:

```sh
terraform init -backend=false
terraform test
```
