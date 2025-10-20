# Prometheus

[Prometheus](https://prometheus.io/) is an open-source monitoring and alerting system. It collects metrics
from applications and systems, stores them in a time-series database, and lets
one query or visualize the data easily.



## Test locally (macos)

```
brew install prometheus
brew install node_exporter
```

Run node exporter and test it:

```
node_exporter
curl http://localhost:9100/metrics
```


Create `prometheus.yml`:

``` yaml
global:
  scrape_interval: 5s  # how often to collect metrics

scrape_configs:
  - job_name: "node"
    static_configs:
      - targets: ["localhost:9100"]

```

Run prometheus:


```
prometheus --config.file=prometheus.yml
```


Open browser: `localhost:9090/query`


In the expression enter this to see the overal system utilization)

```
100 * (1 - avg(rate(node_cpu_seconds_total{mode="idle"}[2m])))
```

One can also go to the settings menu to change to local time zone, as default is
UTC.


# Refereces

- <https://prometheus.io/docs/prometheus/latest/getting_started/>
