# MLPerf (WIP)

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

Let's start with two benchmarks on a single VM:

- ResNet-50 (Image Classification) – CNN training on ImageNet
- BERT (Natural Language Processing) – Transformer training on SQuAD

In this example we assume we have a VM in azure with SKU `Standard_NC40ads_H100_v5` and image `almalinux:almalinux-hpc:8_10-hpc-gen2:latest`. Once machine is provisioned, check if gpus+cuda is detected via: `nvidia-smi`.

Clone mlperf training repo:

```
cd ~
git clone https://github.com/mlcommons/training.git mlperf-training
cd mlperf-training
```




### Inference
