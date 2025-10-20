# MLPerf

MLPerf is an open, industry-standard benchmark suite for measuring machine learning performance.
It’s maintained by the MLCommons consortium (which includes NVIDIA, Google, Intel, and others). MLPerf is primarily categorized by two major types of ML processes: training and inference. There are also specialized benchmarks for specific hardware and workloads. Original documents describing MLPerf can be found here: [MLPerf Training](https://arxiv.org/pdf/1910.01500) and [MLPerf Inference](https://arxiv.org/pdf/1911.02549). Those are interesting to understand some of the key motivations behind these benchmarks, including the uniqueness of ML/DL workloads w.r.t. benchmarking.


MLPerf evaluates systems on standardized ML workloads across multiple domains,
including:

- Image classification (e.g., ResNet-50)
- Object detection (e.g., SSD, Mask R-CNN)
- Language modeling (e.g., BERT)
- Recommendation systems (e.g., DLRM)
- Speech recognition (e.g., RNN-T)


Full list for training can be found [here](https://mlcommons.org/benchmarks/training/) and inference can be found [here](https://mlcommons.org/benchmarks/inference-datacenter/).

One can use MLPerf results to: (i) Compare hardware (e.g., GPU vs CPU); (ii) Tune software stacks (CUDA, PyTorch, TensorFlow); and (iii) Validate scaling behavior or deployment efficiency.


## Testing on a single VM

### Training

Example: Single Stage Detector.

In this example we assume we have a VM in azure with SKU `Standard_NC40ads_H100_v5` and image `almalinux:almalinux-hpc:8_10-hpc-gen2:latest`. Once machine is provisioned, check if gpus+cuda is detected via: `nvidia-smi`.

```bash title="prepmlperf"
--8<-- "docs/misc/mlperf/single_stage_detector.sh"
```

Once run script is started, output should be:

```
Epoch: [0]  [    0/36571]  eta: 1 day, 20:19:44  lr: 0.000000  loss: 2.2699 (2.2699)  classification: 1.5590 (1.5590)  bbox_reg
ression: 0.7109 (0.7109)  time: 4.3637  data: 2.2989  max mem: 51676
Epoch: [0]  [   20/36571]  eta: 6:17:02  lr: 0.000000  loss: 2.1944 (2.2521)  classification: 1.4886 (1.5371)  bbox_regression:
 0.7036 (0.7150)  time: 0.4317  data: 0.0003  max mem: 52125
Epoch: [0]  [   40/36571]  eta: 5:20:59  lr: 0.000000  loss: 2.1934 (2.2440)  classification: 1.4949 (1.5292)  bbox_regression:
 0.6956 (0.7148)  time: 0.4309  data: 0.0003  max mem: 52125
Epoch: [0]  [   60/36571]  eta: 5:03:05  lr: 0.000000  loss: 2.2322 (2.2630)  classification: 1.5102 (1.5478)  bbox_regression:
 0.7024 (0.7151)  time: 0.4384  data: 0.0004  max mem: 52125
.
.
.
```


## Multiple VMs

Similar to single VM but a cluster needs to be provision and parameters related
to SLURM need to be adjusted. See details
[HERE](https://github.com/mlcommons/training/tree/master/single_stage_detector).




