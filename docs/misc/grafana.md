# Grafana

[Grafana](https://grafana.com/) is a data visualization and monitoring tool. It connects to various data
sources (like Prometheus, InfluxDB, MySQL, etc.) and allows one to create
dashboards, graphs, and alerts to monitor metrics in real time.

Here is a quick example with grafana + prometheus + node exporter on localhost
(macos).



| Component     | Port | Purpose                                          |
| ------------- | ---- | ------------------------------------------------ |
| Node Exporter | 9100 | Exposes system metrics (CPU, memory, disk, etc.) |
| Prometheus    | 9090 | Collects metrics and stores them                 |
| Grafana       | 3000 | Visualizes metrics in dashboards                 |



Assuming Node Exporter and Prometheus are already running.


```
brew install grafana
brew services start grafana
```

Open browser(admin/admin): `http://localhost:3000/login`

Go to Settings → Data Sources → Add data source → Prometheus.  Then add `http://localhost:9090`.

To add node exporter; go to Dashboards, then import the dashboard using this ID: `1860`. This will import a pre-built dashboard for node exporter.


To stress cpu and see changes in the dashboard:

```
brew install stress
stress --cpu 4 --timeout 60
```




# 100 * (1 - avg(rate(node_cpu_seconds_total{mode="idle"}[2m])))

