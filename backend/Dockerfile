# Dockerfile — builds the Flask backend into a container image.
#
# HOW IT WORKS:
# 1. Start from an official Python image (the "base image")
# 2. Copy our source code into the image
# 3. Install dependencies
# 4. Tell Docker how to start the app
#
# To build: docker build -t smartfinance-backend .
# To run:   docker-compose up  (use docker-compose.yml instead of this directly)

# --- Stage 1: Base image ---
# python:3.11-slim is an official Python image with only the essentials.
# 'slim' means no extra OS packages — keeps the image small (~150MB vs ~900MB).
FROM python:3.11-slim

# Set the working directory inside the container.
# All subsequent commands run from /app.
WORKDIR /app

# --- Install system dependencies ---
# gcc and default-libmysqlclient-dev are needed to compile PyMySQL's C extensions.
# --no-install-recommends keeps the image small by skipping optional packages.
# rm -rf /var/lib/apt/lists/* cleans up the apt cache afterward.
RUN apt-get update && apt-get install -y \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# --- Copy and install Python dependencies ---
# Copy requirements.txt FIRST (before the rest of the code).
# Docker caches each step — if requirements.txt hasn't changed, this layer
# is reused and pip install is skipped, making rebuilds much faster.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Add pytest for running tests inside the container
RUN pip install --no-cache-dir pytest pytest-flask

# --- Copy the rest of the source code ---
COPY . .

# Expose port 5000 — this is the port Flask listens on inside the container.
# The docker-compose.yml maps this to a port on your host machine.
EXPOSE 5000

# --- Start command ---
# python run.py starts the Flask development server.
# For production, replace this with: gunicorn -w 4 -b 0.0.0.0:5000 run:app
CMD ["python", "run.py"]
