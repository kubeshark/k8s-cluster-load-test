# Use the official Caddy image as the base image
FROM caddy:latest

# Copy your site content (e.g., HTML files) into the container
COPY files/smap.png /usr/share/caddy/smap.png
COPY files/ks_logo.png /usr/share/caddy/ks_logo.png

# Copy the generated certificates into the container
COPY certs/dev-kubeshark-io.pem /etc/caddy/certs/dev-kubeshark-io.crt
COPY certs/dev-kubeshark-io-key.pem /etc/caddy/certs/dev-kubeshark-io.key
COPY files/Caddyfile /etc/caddy/Caddyfile

# Expose HTTP and HTTPS ports
EXPOSE 80 443