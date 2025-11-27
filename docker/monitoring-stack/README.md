# Monitoring Stack: Prometheus, Grafana, and Unpoller

This repository contains a **containerized observability stack** for monitoring infrastructure and network devices using **Prometheus**, **Grafana**, and **Unpoller**, running on Docker. It is designed to be deployed on a **Linux VM** with `/opt/monitoring` as the working directory.

---

## Stack Overview

- **Prometheus**  
  Collects and stores time-series metrics from your host and network devices. Default scrape jobs configured in `prometheus/prometheus.yml`

- **Grafana**  
  Visualises metrics collected by Prometheus. Provides dashboards, panels, and alerting.

- **Unpoller**  
  Integrates with your UniFi controller (or other supported devices) to expose network and device metrics to Prometheus.

## Directory Structure

```text
.
├── docker-compose.yml         # Docker Compose stack configuration
├── grafana                    # Grafana persistent storage
├── prometheus                 # Prometheus configuration and scripts
│   ├── prometheus.yml         # Prometheus main config
│   ├── scripts                # Utility scripts
│   │   └── generate_targets.sh  # Script to generate Prometheus target files
│   └── targets                # Prometheus static targets
│       └── linux_targets.yml    # Can be targeted in prometheus/prometheus.yml as additional scrape targets
├── prometheus-data            # Prometheus data persistence
└── unpoller                   # Unpoller configuration
    └── up.conf

```
---

