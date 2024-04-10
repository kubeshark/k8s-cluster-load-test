FROM grafana/k6:latest

COPY loadtest.js /loadtest.js
COPY certs/ca.pem /usr/local/share/ca-certificates/ks-ca.crt
USER root
RUN cat /usr/local/share/ca-certificates/ks-ca.crt >> /etc/ssl/certs/ca-certificates.crt && \
    apk add --no-cache ca-certificates && \
    update-ca-certificates

ENTRYPOINT ["k6", "run", "/loadtest.js"]
