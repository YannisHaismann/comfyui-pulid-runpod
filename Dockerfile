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
WORKDIR /comfyui/custom_nodes
RUN git clone https://github.com/lldacing/ComfyUI_PuLID_Flux_ll.git

# Install Python dependencies with FIXED insightface version (0.7.3 is compatible with PuLID)
WORKDIR /comfyui/custom_nodes/ComfyUI_PuLID_Flux_ll
RUN /opt/venv/bin/pip install insightface==0.7.3 && \
    /opt/venv/bin/pip install -r requirements.txt --no-deps && \
    /opt/venv/bin/pip install cython facexlib onnxruntime onnxruntime-gpu ftfy timm

# Create model directories
RUN mkdir -p /comfyui/models/pulid \
    /comfyui/models/insightface/models \
    /comfyui/models/clip \
    /comfyui/models/eva_clip

# Download PuLID model
RUN curl -L "https://huggingface.co/guozinan/PuLID/resolve/main/pulid_flux_v0.9.1.safetensors" \
    -o /comfyui/models/pulid/pulid_flux_v0.9.1.safetensors

# Download InsightFace models (antelopev2)
# The zip contains an 'antelopev2' folder, so extract to parent directory
RUN curl -L "https://huggingface.co/MonsterMMORPG/tools/resolve/main/antelopev2.zip" \
    -o /tmp/antelopev2.zip && \
    unzip /tmp/antelopev2.zip -d /comfyui/models/insightface/models/ && \
    rm /tmp/antelopev2.zip && \
    ls -la /comfyui/models/insightface/models/ && \
    ls -la /comfyui/models/insightface/models/antelopev2/

# Download EVA CLIP model
RUN curl -L "https://huggingface.co/QuanSun/EVA-CLIP/resolve/main/EVA02_CLIP_L_336_psz14_s6B.pt" \
    -o /comfyui/models/clip/EVA02_CLIP_L_336_psz14_s6B.pt && \
    cp /comfyui/models/clip/EVA02_CLIP_L_336_psz14_s6B.pt /comfyui/models/eva_clip/

# Verify custom nodes installation
RUN echo "=== Custom nodes ===" && \
    ls -la /comfyui/custom_nodes/ && \
    echo "=== PuLID files ===" && \
    ls -la /comfyui/custom_nodes/ComfyUI_PuLID_Flux_ll/

# Test Python imports to catch errors at build time
RUN cd /comfyui && \
    /opt/venv/bin/python -c "\
import sys; \
sys.path.insert(0, '/comfyui'); \
sys.path.insert(0, '/comfyui/custom_nodes/ComfyUI_PuLID_Flux_ll'); \
print('Testing imports...'); \
from pulidflux import NODE_CLASS_MAPPINGS; \
print('SUCCESS: Loaded', len(NODE_CLASS_MAPPINGS), 'nodes:', list(NODE_CLASS_MAPPINGS.keys())); \
"

# Verify all models are present
RUN echo "=== Model verification ===" && \
    ls -la /comfyui/models/pulid/ && \
    ls -la /comfyui/models/clip/ && \
    ls -la /comfyui/models/insightface/models/antelopev2/

# Set environment
ENV INSIGHTFACE_PROVIDER=CUDA
WORKDIR /comfyui
