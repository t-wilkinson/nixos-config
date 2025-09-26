# Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir \
  flask==3.0.0 \
  boto3==1.34.0 \
  requests==2.31.0 \
  schedule==1.2.0

# Copy application
ADD https://raw.githubusercontent.com/t-wilkinson/zortex.nvim/refs/heads/main/deployment/server.py /app/server.py

# Create data directory
RUN mkdir -p /data

# Expose port
EXPOSE 80

# Run application
CMD ["python", "server.py"]
