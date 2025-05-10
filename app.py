from webscout import formats
from webscout.Local.model import Model
from webscout.Local.thread import Thread
from webscout.Local.server import serve
from webscout.Local.samplers import SamplerSettings

model_path = "D:/Projects/models/mistral-7b-instruct-v0.2.Q4_K_M.gguf"  # Make sure this is correct

# Load the model using llama.cpp backend
model = Model(model_path, n_gpu_layers=0)  # Set to >0 if you want to offload layers to GPU

# Customize prompt format (ChatML style)
system_prompt = "You are an emotionally intelligent assistant. Respond with empathy and understanding."
chatml = formats.chatml.copy()
chatml["system_content"] = system_prompt

# Sampling behavior (temperature, top-p etc.)
sampler = SamplerSettings(temp=0.7, top_p=0.9)

# Create the chat thread logic
thread = Thread(model, chatml, sampler=sampler)

# Start the WebSocket server
serve(thread, host="0.0.0.0", port=8000)
