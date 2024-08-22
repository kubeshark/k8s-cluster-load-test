# Define variables
BINARY_NAME=app
SOURCE_FILES=main.go
VERSION=$(shell git describe --tags --always --dirty)

# Default target: build the binary
all: build

# Build the Go application
build:
	@echo "Building the Go application..."
	go build -o $(BINARY_NAME) $(SOURCE_FILES)

# Run tests
test:
	@echo "Running tests..."
	go test -v ./...

# Clean the build artifacts
clean:
	@echo "Cleaning up..."
	rm -f $(BINARY_NAME)

# Rebuild the application
rebuild: clean build

# Print the version
version:
	@echo $(VERSION)

# Help target
help:
	@echo "Makefile commands:"
	@echo "  all       - Build the Go application (default target)"
	@echo "  build     - Build the Go application"
	@echo "  test     
