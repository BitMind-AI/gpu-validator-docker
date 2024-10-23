# BitMind Validator Setup

This guide explains how to set up and run the BitMind Validator Docker container on your machine.

## Step 1: Copy and Modify Environment Variables

Start by copying the provided `.env.example` file to `.env` and modify it according to your network and wallet configuration.

```bash
cp .env.example .env
```

Then, modify the `.env` file to include your network details, API keys, and wallet information. Here’s an example of what your `.env` file might look like:

```env
# Network Configuration:
NETUID=34                                      # Network User ID options: 34, 168
SUBTENSOR_NETWORK=finney                       # Networks: finney, test, local
SUBTENSOR_CHAIN_ENDPOINT=wss://entrypoint-finney.opentensor.ai:443
                                                # Endpoints:
                                                # - wss://entrypoint-finney.opentensor.ai:443
                                                # - wss://test.finney.opentensor.ai:443/

# Validator Port Setting:
VALIDATOR_AXON_PORT=8092

# API Keys:
WANDB_API_KEY=your_wandb_api_key_here
HUGGING_FACE_TOKEN=your_hugging_face_token_here

# Wallet names
WALLET_NAME=default
WALLET_HOTKEY=default

# Wallets
COLDKEY_ADDRESS=
HOTKEY_MNEMONIC=
```

### Explanation of Key Variables:
- **NETUID**: Your Network User ID, options are `34` (for mainnet) and `168`.
- **SUBTENSOR_NETWORK**: Network name, options include `finney` (mainnet), `test`, or `local`.
- **SUBTENSOR_CHAIN_ENDPOINT**: The WebSocket endpoint to connect to. Default is for the Finney mainnet.
- **VALIDATOR_AXON_PORT**: The port used by the validator service, default is `8092`.
- **WANDB_API_KEY**: Your Weights & Biases API key for experiment tracking.
- **HUGGING_FACE_TOKEN**: Your Hugging Face token for accessing model APIs.
- **COLDKEY_ADDRESS**: Your wallet coldkey address.
- **HOTKEY_MNEMONIC**: The mnemonic phrase for regenerating your wallet hotkey.

## Step 2: Modify Dockerfile to Fit Your Machine Setup

The base image in the Dockerfile can be changed depending on your host machine’s configuration. When choosing the base image, **make sure to use the one with the `cudnn-devel` tag** for proper cuDNN support in development. You can find appropriate CUDA base images from the [NVIDIA NGC Container Catalog](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/cuda/tags).

### Example Modification:

If your machine has a specific CUDA version installed, you can change the base image in the Dockerfile by modifying the `BASE_IMAGE` build argument.

```dockerfile
ARG BASE_IMAGE=nvcr.io/nvidia/cuda:11.6.1-cudnn8-devel-ubuntu20.04
```

### Important: Use `cudnn-devel` Tag
Ensure that when selecting your base image, you include the `cudnn-devel` in the tag to support CUDA and cuDNN development environments.

## Step 3: Host Machine Prerequisites

Before running the Docker container, ensure that your host machine has the following software installed:

1. **CUDA Toolkit**: This is required to run CUDA applications on your GPU.
2. **NVIDIA Drivers**: Ensure the correct NVIDIA drivers are installed on your machine to support GPU acceleration.
3. **cuDNN**: NVIDIA's CUDA Deep Neural Network library for accelerating deep learning workloads.
4. **NVIDIA Container Toolkit**: This toolkit is required to run Docker containers with GPU support.

### Installing NVIDIA Drivers and Toolkit

Follow the official guides to install the necessary drivers and tools for GPU support:

- [Install NVIDIA Drivers](https://docs.nvidia.com/datacenter/tesla/tesla-installation-notes/index.html)
- [Install CUDA Toolkit](https://developer.nvidia.com/cuda-downloads)
- [Install cuDNN](https://developer.nvidia.com/cudnn)
- [Install NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)

## Step 4: Build and Run the Docker Container

Once you have your `.env` file configured and prerequisites installed, you can build and run the container:

```bash
docker compose up -d --build
```

### What Happens After Running `docker compose up -d --build`:

- The first time you run `docker compose`, a new Docker image is built. During this process, the `entrypoint.sh` script is used to regenerate the keys (coldkey and hotkey) inside the container based on the environment variables you have set.
- The `.bittensor` folder inside the container is mounted as a volume in your current directory under the path `./container-data/.bittensor`. This ensures that the generated keys and any other data remain persistent between container restarts.
- After the keys are regenerated, the following steps are executed:
  1. **Conda Environment Activation**: The `bitmind` Conda environment is activated to ensure that all required packages are available for the subsequent steps.
  2. **Coldkey and Hotkey Regeneration**: The coldkeypub and hotkey are regenerated using `btcli` based on the values from the environment variables.
  3. **Login to Weights & Biases**: The script attempts to log in to Weights & Biases using the provided API key. If the login fails, the process stops.
  4. **Login to Hugging Face**: The script logs in to Hugging Face with the provided token. If login fails, the process stops.
  5. **Verification of Access to Synthetic Image Generation Models**: The script verifies access to synthetic image generation models by running a Python script (`verify_models.py`). If verification fails, the process stops.
  6. **Run the Validator**: The validator is run using `neurons/validator.py` with the provided network, wallet, and axon port details.

This ensures the validator is correctly configured and ready.

## Step 5: Validate the Setup

To ensure everything is running properly, you can check the logs:

```bash
docker logs bitmind_validator --follow
```

If everything is set up correctly, you should see your validator logs.
