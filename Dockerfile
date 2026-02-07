FROM debian:bullseye-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    mingw-w64 \
    make \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /src

# Copy source code (assuming the context will be mounted or copied)
# We can't copy here if we want the user to mount it, but we can provide instructions.
# However, usually a Dockerfile expects COPY.
# Since the user wants "Build-in-Docker", likely they will mount their source to /src.
# But to be safe and usable, I will assume the source is mounted.

# Command to compile statically
# usage: docker run -v $(pwd):/src <image_name> sh -c "x86_64-w64-mingw32-g++ -o server.exe server.cpp -static -lws2_32"
CMD ["x86_64-w64-mingw32-g++", "-o", "server.exe", "server.cpp", "-static", "-lws2_32"]
