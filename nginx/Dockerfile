# Use the official Nginx image as the base image
FROM nginx:latest

# Remove the default Nginx configuration file
RUN rm /etc/nginx/conf.d/default.conf

# Copy your custom nginx.conf into the container
COPY nginx.conf /etc/nginx/nginx.conf

# Copy your site content (e.g., HTML files) into the container
COPY files/smap.png /usr/share/nginx/html/smap.png
COPY files/ks_logo.png /usr/share/nginx/html/ks_logo.png

# Copy the generated certificates into the container
COPY certs/dev-kubeshark-io.pem /etc/nginx/certs/dev-kubeshark-io.crt
COPY certs/dev-kubeshark-io-key.pem /etc/nginx/certs/dev-kubeshark-io.key

# Expose HTTP and HTTPS ports
EXPOSE 80 443