# Use the official httpd image as the base image
FROM httpd:latest

# Install wget
RUN apt-get update && \
    apt-get install -y wget && \
    rm -rf /var/lib/apt/lists/*

# Copy the HTML files into the default directory served by httpd
COPY files/smap.png /usr/local/apache2/htdocs/
COPY files/ks_logo.png /usr/local/apache2/htdocs/
COPY files/httpd-conf.conf /usr/local/apache2/conf/httpd.conf

# Expose port 80
EXPOSE 80

# docker buildx build --platform linux/amd64 -t alongir/ks-load-httpd:latest . --push
