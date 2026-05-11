# Stage 1: Build llama.cpp
FROM debian:bookworm AS builder

RUN apt-get update && apt-get install -y \
    git build-essential cmake curl \
    libcurl4-openssl-dev python3 python3-pip \
    && git config --global http.postBuffer 524288000 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /llama

# Use shallow clone for reliability
RUN git clone --depth 1 https://github.com/ggerganov/llama.cpp.git . \
    && mkdir build \
    && cd build \
    # Build with server support
    && cmake .. -DLLAMA_SERVER=ON \
    && make -j


# Stage 2: Runtime
FROM debian:bookworm AS runtime

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    python3 python3-pip curl \
    libcurl4 libstdc++6 libgcc1 libgomp1 \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy application files
COPY app/ /app/app/
COPY models/ /app/models/
COPY requirements.txt /app/requirements.txt
COPY entrypoint.sh /app/entrypoint.sh

# Copy built binaries and shared libs from builder stage
COPY --from=builder /llama/build/bin/llama-server /app/llama/llama-server
COPY --from=builder /llama/build/bin/ /app/llama/

# Set execution permissions for entrypoint
RUN chmod +x /app/entrypoint.sh

# Install Python dependencies
RUN pip3 install --no-cache-dir --break-system-packages -r /app/requirements.txt

# Set environment variable for shared libraries
ENV LD_LIBRARY_PATH=/app/llama:${LD_LIBRARY_PATH:-""}

# Expose ports
EXPOSE 8000
EXPOSE 8080

# Health check to ensure llama-server is running
HEALTHCHECK CMD curl --silent --fail http://localhost:8080/ || exit 1

CMD ["/app/entrypoint.sh"]
