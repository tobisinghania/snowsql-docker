# Use a minimal base image
FROM debian:bookworm-slim AS builder

# Set environment variables for non-interactive installs
ENV DEBIAN_FRONTEND=noninteractive
ENV SNOWSQL_DOWNLOAD_DIR=/var/lib/snowsql

# Install dependencies required for SnowSQL
RUN apt-get update && \
    apt-get install -y \
    wget \
    ca-certificates \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Define SnowSQL version and download URL
ARG SNOWSQL_DOWNLOAD_URL="https://sfc-repo.snowflakecomputing.com/snowsql/bootstrap/1.3/linux_x86_64/snowsql-1.3.2-linux_x86_64.bash"

# Download and install SnowSQL
RUN wget "$SNOWSQL_DOWNLOAD_URL" -O /tmp/snowsql-install.bash && \
    chmod +x /tmp/snowsql-install.bash && \
     SNOWSQL_DEST=/usr/local/bin SNOWSQL_LOGIN_SHELL=~/.profile bash /tmp/snowsql-install.bash

# Use a minimal runtime base image
FROM debian:bookworm-slim AS runtime

# Install required runtime dependencies
RUN apt-get update && \
    apt-get install -y \
    ca-certificates curl telnet \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/lib/snowsql/home \
    && chmod a+rw /var/lib/snowsql/home

# Copy SnowSQL binary from builder
COPY --from=builder /usr/local/bin/snowsql /usr/local/bin/snowsql
COPY --from=builder /root/.snowsql/1.3.2 /var/lib/snowsql/1.3.2



ENV SNOWSQL_DOWNLOAD_DIR=/var/lib/snowsql
ENV HOME=/var/lib/snowsql/home

# Set default command for the container
ENTRYPOINT ["snowsql"]

# Provide a default SnowSQL help command
CMD ["--help"]

# Documentation for environment variables (optional)
LABEL maintainer="Tobias Singhania <tobias@synlynx.at>"
LABEL description="SnowSQL Docker image with latest binary."
