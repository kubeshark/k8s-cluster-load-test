# Step 1: Build the Go application in a builder image
FROM golang:1.20-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy go.mod and go.sum files first (if they exist)
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the rest of the application source code
COPY . .

# Build the Go application
RUN go build -o app main.go

# Step 2: Create a minimal image to run the application
FROM alpine:latest

# Install CA certificates to enable HTTPS calls
RUN apk --no-cache add ca-certificates

# Set the working directory inside the final container
WORKDIR /root/

# Copy the compiled Go binary from the builder stage
COPY --from=builder /app/app .

# Expose port 8080 (optional, only if your app serves HTTP on this port)
# EXPOSE 8080

# Command to run the executable, expecting URL and N as environment variables
CMD ["sh", "-c", "./app $URL $N $V"]
