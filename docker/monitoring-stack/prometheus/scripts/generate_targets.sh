#!/bin/bash

# Output file for Prometheus
TARGET_FILE="/opt/monitoring/prometheus/targets/lan_targets.yml"

# Create directory if it doesn't exist
mkdir -p "$(dirname "$TARGET_FILE")"

# Start YAML array
echo "- targets:" > "$TARGET_FILE"

# Loop over your IP ranges
for net in {1..60}; do
  for host in {1..254}; do
    IP="10.1.$net.$host"
    # Assuming node_exporter runs on port 9100
    echo "  - \"$IP:9100\"" >> "$TARGET_FILE"
  done
done

echo "Targets file generated at $TARGET_FILE"
