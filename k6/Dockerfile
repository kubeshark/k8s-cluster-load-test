FROM loadimpact/k6:latest

COPY loadtest.js /loadtest.js

ENTRYPOINT ["k6", "run", "/loadtest.js"]

# docker buildx build --platform linux/amd64 -t alongir/k6-loadtest:latest . --push 