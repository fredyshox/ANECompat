# ANECompat

A tool to check if your CoreML model is running on AppleNeuralEngine (and if it runs end-to-end or only specific segments). Useful during the process of designing/choosing neural network architecture.

Note that this tool check compatibility against neural engine of the host and each generation of Apple SoC's have different ANE with varying feature sets and performance. Checkout this [document](https://github.com/hollance/neural-engine/blob/master/docs/supported-devices.md) to see which chips have ANE.

Currenly only compatible with AppleSilicon macs - M1 series is equivalent to A14 Bionic ANE-wise.

## How does it work?

`ANECompat` works by swizzling inference methods in `AppleNeuralEngine` private framework, which is used internally by CoreML (Espresso to be more specific).

CoreML runtime partitions neural network computation graph based on operations and complexity with focus on performance. Segments of a model with operations which are not supported by the neural engine will be assigned to be run on other compute unit. Switching between compute units can be expensive, that's why tuning a model to be fully ane-friendly is one of ways to maximize performance.  

## Usage

### Python API

[anecompat.py](./python/anecompat.py) contains Python bindings which is single function:

```python
def test_ane_compatibility_coreml_model(mlmodel_path)
```

**Parameters**

`mlmodel_path: str` 
* Path to mlmodel/mlpackage or compiled mlmodelc bundle

**Returns**

`status: int`
* integer status: 0 - fully compatible, 1 - partially compatible, 2 - not compatible

### Command-line tool

MLModel can be evaluated from command-line using `anecompat` tool on macs with neural engine (AppleSilicon macs).

```
anecompat MODELPATH [LOGDIR]
```

`MODELPATH` path to `mlmodel`/`mlpackage` or compiled `mlmodelc` file

`LOGDIR` optional path to directory where additional logs and file dumps will be stored

## Build

### Requirements:
* Xcode command-line tools
* macOS 12 Monterey (previous not tested)

### Building from source

Clone repository, then from project directory execute:

```
make
```

`build/` directory will be created with artifacts: `anecompat` executable and `libANECompat.dylib` shared library.