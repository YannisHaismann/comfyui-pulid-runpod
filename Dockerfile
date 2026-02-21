# ==============================================================================
# Custom ComfyUI Worker with PuLID-Flux
#
# Based on the official RunPod ComfyUI worker with:
# - FLUX.1-dev model
# - ComfyUI_PuLID_Flux_ll custom nodes
# - InsightFace for face detection
# - EVA CLIP for encoding
#
# Build: docker build -t your-username/comfyui-pulid-flux .
# Push:  docker push your-username/comfyui-pulid-flux
# ==============================================================================

# Use the official RunPod ComfyUI base image with FLUX.1-dev
FROM runpod/worker-comfyui:5.7.1-flux1-dev

# Install required system tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install PuLID-Flux custom nodes
# Using lldacing's version which has no model pollution issues
RUN comfy-node-install comfyui_pulid_flux_ll

# Download PuLID model
# From: https://huggingface.co/guozinan/PuLID/tree/main
RUN comfy model download \
    --url "https://huggingface.co/guozinan/PuLID/resolve/main/pulid_flux_v0.9.1.safetensors" \
    --relative-path "models/pulid" \
    --filename "pulid_flux_v0.9.1.safetensors"

# Download InsightFace models (antelopev2)
# Required for face detection in PuLID
RUN mkdir -p /comfyui/models/insightface/models/antelopev2 && \
    curl -L "https://huggingface.co/MonsterMMORPG/tools/resolve/main/antelopev2.zip" -o /tmp/antelopev2.zip && \
    unzip /tmp/antelopev2.zip -d /comfyui/models/insightface/models/antelopev2/ && \
    rm /tmp/antelopev2.zip

# EVA CLIP models will be downloaded automatically by the node on first use
# but we can pre-download for faster cold starts
RUN comfy model download \
    --url "https://huggingface.co/QuanSun/EVA-CLIP/resolve/main/EVA02_CLIP_L_336_psz14_s6B.pt" \
    --relative-path "models/clip" \
    --filename "EVA02_CLIP_L_336_psz14_s6B.pt"

# Set default execution provider for InsightFace
ENV INSIGHTFACE_PROVIDER=CUDA

# The base image already handles the entrypoint
