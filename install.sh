#!/bin/bash

# Simple installation script for rotafile.sh

# Default installation directory
INSTALL_DIR="/usr/local/bin"

# Display header
echo "====================================="
echo "Rotafile Installation"
echo "====================================="

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Warning: Not running as root. May not have permission to install to $INSTALL_DIR"
    read -p "Continue anyway? (y/n): " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi
fi

# Check if the script exists
if [ ! -f "rotafile.sh" ]; then
    echo "Error: Cannot find rotafile.sh in the current directory."
    exit 1
fi

# Make sure the script is executable
chmod +x rotafile.sh

# Create directory if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Creating directory $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
fi

# Copy the script to the installation directory
echo "Installing to $INSTALL_DIR/rotafile..."
cp rotafile.sh "$INSTALL_DIR/rotafile"

# Check if installation was successful
if [ $? -eq 0 ]; then
    echo "Installation successful!"
    echo "You can now run the tool using 'rotafile'"
    
    # Check if the directory is in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo "Warning: $INSTALL_DIR is not in your PATH."
        echo "You may need to add it to your PATH or use the full path to run the tool."
    fi
else
    echo "Installation failed. Please check permissions and try again."
    exit 1
fi

echo "Done!"