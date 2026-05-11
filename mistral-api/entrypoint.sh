#!/bin/bash

# Set error handling and logging
set -e  # Exit on error
trap 'echo "Error occurred in $0 on line $LINENO"; exit 1' ERR

# Log the environment
echo "Environment variables:"
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"

# Ensure LD_LIBRARY_PATH is set correctly before using it
export LD_LIBRARY_PATH="/app/llama:$LD_LIBRARY_PATH"

# Check if the model file exists
MODEL_PATH="/app/models/mistral-7b-instruct-v0.2.Q4_K_M.gguf"
if [ ! -f "$MODEL_PATH" ]; then
  echo "❌ Error: Model file not found at $MODEL_PATH"
  exit 1
fi

# Start the llama server with logging
echo "⚡ Starting llama server with model: $MODEL_PATH"
/app/llama/llama-server -m "$MODEL_PATH" --host 0.0.0.0 --port 8080 &

# Capture the process ID of the llama-server
LLAMA_PID=$!

# Check if llama-server started successfully
if ! ps -p $LLAMA_PID > /dev/null; then
  echo "❌ Error: llama-server failed to start"
  exit 1
fi

# Start FastAPI app and log output
echo "⚡ Starting FastAPI app"
uvicorn app.main:app --host 0.0.0.0 --port 8000

# Ensure both servers are running
wait $LLAMA_PID
