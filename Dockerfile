FROM alpine:latest

# Build arguments - MUST be provided during build
ARG DASHBOARD_USERNAME
ARG DASHBOARD_PASSWORD

# Install dependencies
RUN apk add --no-cache \
    curl \
    bash \
    ca-certificates \
    dcron

# Install cronitor CLI
RUN curl -sL https://cronitor.io/dl/linux_amd64.tar.gz -o /tmp/cronitor.tar.gz && \
    tar -xzC /tmp/ -f /tmp/cronitor.tar.gz && \
    mv /tmp/cronitor /usr/local/bin/cronitor && \
    chmod +x /usr/local/bin/cronitor && \
    rm /tmp/cronitor.tar.gz

# Configure authentication
RUN cronitor configure --dash-username ${DASHBOARD_USERNAME} --dash-password ${DASHBOARD_PASSWORD}

# Expose dashboard port
EXPOSE 9000

# Run the dashboard
CMD ["cronitor", "dash", "--port", "9000"]
