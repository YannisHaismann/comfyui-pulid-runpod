# ==============================================================================
# Custom ComfyUI Worker with PuLID-Flux
#
# Based on the official RunPod ComfyUI worker with:
# - FLUX.1-dev model
# - ComfyUI_PuLID_Flux_ll custom nodes (installed via git)
# - InsightFace for face detection
# - EVA CLIP for encoding
# ==============================================================================

FROM runpod/worker-comfyui:5.7.1-flux1-dev

# Install required system tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install PuLID-Flux custom nodes manually via git clone
# This is more reliable than comfy-node-install
WORKDIR /comfyui/custom_nodes
RUN git clone https://github.com/lldacing/ComfyUI_PuLID_Flux_ll.git && \
    cd ComfyUI_PuLID_Flux_ll && \
    pip install -r requirements.txt || true

# Create model directories
RUN mkdir -p /comfyui/models/pulid \
    /comfyui/models/insightface/models/antelopev2 \
    /comfyui/models/clip

# Download PuLID model
RUN curl -L "https://huggingface.co/guozinan/PuLID/resolve/main/pulid_flux_v0.9.1.safetensors" \
    -o /comfyui/models/pulid/pulid_flux_v0.9.1.safetensors

# Download InsightFace models (antelopev2)
RUN curl -L "https://huggingface.co/MonsterMMORPG/tools/resolve/main/antelopev2.zip" \
    -o /tmp/antelopev2.zip && \
    unzip /tmp/antelopev2.zip -d /comfyui/models/insightface/models/antelopev2/ && \
    rm /tmp/antelopev2.zip

# Download EVA CLIP model
RUN curl -L "https://huggingface.co/QuanSun/EVA-CLIP/resolve/main/EVA02_CLIP_L_336_psz14_s6B.pt" \
    -o /comfyui/models/clip/EVA02_CLIP_L_336_psz14_s6B.pt

# Set environment
ENV INSIGHTFACE_PROVIDER=CUDA
WORKDIR /comfyui
