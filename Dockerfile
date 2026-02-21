# ==============================================================================
# Custom ComfyUI Worker with PuLID-Flux
# ==============================================================================

FROM runpod/worker-comfyui:5.7.1-flux1-dev

# Install required system tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install PuLID-Flux custom nodes
# Use the virtual environment that ComfyUI uses
WORKDIR /comfyui/custom_nodes
RUN git clone https://github.com/lldacing/ComfyUI_PuLID_Flux_ll.git

# Install Python dependencies in the correct venv
WORKDIR /comfyui/custom_nodes/ComfyUI_PuLID_Flux_ll
RUN /opt/venv/bin/pip install -r requirements.txt

# Create model directories
RUN mkdir -p /comfyui/models/pulid \
    /comfyui/models/insightface/models/antelopev2 \
    /comfyui/models/clip \
    /comfyui/models/eva_clip

# Download PuLID model
RUN curl -L "https://huggingface.co/guozinan/PuLID/resolve/main/pulid_flux_v0.9.1.safetensors" \
    -o /comfyui/models/pulid/pulid_flux_v0.9.1.safetensors

# Download InsightFace models (antelopev2)
RUN curl -L "https://huggingface.co/MonsterMMORPG/tools/resolve/main/antelopev2.zip" \
    -o /tmp/antelopev2.zip && \
    unzip /tmp/antelopev2.zip -d /comfyui/models/insightface/models/antelopev2/ && \
    rm /tmp/antelopev2.zip

# Download EVA CLIP model - try multiple possible locations
RUN curl -L "https://huggingface.co/QuanSun/EVA-CLIP/resolve/main/EVA02_CLIP_L_336_psz14_s6B.pt" \
    -o /comfyui/models/eva_clip/EVA02_CLIP_L_336_psz14_s6B.pt && \
    cp /comfyui/models/eva_clip/EVA02_CLIP_L_336_psz14_s6B.pt /comfyui/models/clip/

# Verify installation - list custom nodes
RUN ls -la /comfyui/custom_nodes/ && \
    ls -la /comfyui/custom_nodes/ComfyUI_PuLID_Flux_ll/

# Set environment
ENV INSIGHTFACE_PROVIDER=CUDA
WORKDIR /comfyui
