#!/bin/bash

# Activate the conda environment
source $HOME/miniconda/etc/profile.d/conda.sh
conda activate bitmind

# Regenerate the coldkeypub for the wallet
btcli wallet regen_coldkeypub \
  --wallet.name "$WALLET_NAME" \
  --ss58_address "$COLDKEY_ADDRESS" \
  --overwrite_coldkey \
  --no_prompt

# Regenerate the hotkey for the wallet using mnemonic
btcli wallet regen_hotkey \
  --mnemonic "$HOTKEY_MNEMONIC" \
  --wallet.name "$WALLET_NAME" \
  --wallet.hotkey "$WALLET_HOTKEY" \
  --no_password \
  --overwrite_hotkey \
  --no_prompt

# Cd into the bitmind-subnet directory
cd $HOME/bitmind-subnet

# Login to Weights & Biases
if ! wandb login $WANDB_API_KEY; then
  echo "Failed to login to Weights & Biases with the provided API key."
  exit 1
fi

# Login to Hugging Face
if ! huggingface-cli login --token $HUGGING_FACE_TOKEN; then
  echo "Failed to login to Hugging Face with the provided token."
  exit 1
fi

# Verify access to synthetic image generation models
echo "Verifying access to synthetic image generation models. This may take a few minutes."
if ! python3 bitmind/validator/verify_models.py; then
  echo "Failed to verify diffusion models. Please check the configurations or model access permissions."
  exit 1
fi

# Run validator
python neurons/validator.py \
  --netuid $NETUID \
  --subtensor.network $SUBTENSOR_NETWORK \
  --subtensor.chain_endpoint $SUBTENSOR_CHAIN_ENDPOINT \
  --wallet.name $WALLET_NAME \
  --wallet.hotkey $WALLET_HOTKEY \
  --axon.port $VALIDATOR_AXON_PORT