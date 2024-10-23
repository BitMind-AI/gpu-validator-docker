# Change base image based on your host machine setup: https://catalog.ngc.nvidia.com/orgs/nvidia/containers/cuda/tags
ARG BASE_IMAGE=nvcr.io/nvidia/cuda:11.6.1-cudnn8-devel-ubuntu20.04

# Use the BASE_IMAGE in the FROM directive
FROM ${BASE_IMAGE}

# Set the frontend to noninteractive to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies
RUN apt update && apt upgrade -y && \
    apt install -y sudo git curl wget bzip2 pkg-config libhdf5-dev build-essential cmake git libjson-c-dev libwebsockets-dev

USER root
ENV HOME="/root"
WORKDIR $HOME

# Determine architecture and download appropriate Miniconda installer
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ] || [ "$ARCH" = "x86_64" ]; then \
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"; \
    elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then \
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    wget -q $MINICONDA_URL -O /tmp/miniconda.sh

# Install Miniconda
RUN bash /tmp/miniconda.sh -b -p $HOME/miniconda && \
    rm /tmp/miniconda.sh

# Set PATH for Miniconda and initialize Conda
ENV PATH="$HOME/miniconda/bin:$PATH"
RUN conda init bash

# Create a new Conda environment using 'conda' directly
RUN conda create -n bitmind python=3.10 ipython jupyter ipykernel -y

# Add conda environment activation to .bashrc
RUN echo "conda activate bitmind" >> $HOME/.bashrc

# Clone the BitMind subnet repository and run setup in a single RUN block with the environment activated
RUN git clone https://github.com/BitMind-AI/bitmind-subnet && \
    cd bitmind-subnet && \
    $HOME/miniconda/bin/conda run -n bitmind --no-capture-output bash -c "chmod +x setup_validator_env.sh && \
    ./setup_validator_env.sh"

COPY entrypoint.sh $HOME