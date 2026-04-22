#!/bin/bash

# MacMind Backend Startup Script for macOS/Linux
# This script sets up and runs the Flask server

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║  MacMind Medical Calculator - Backend      ║"
echo "║       macOS/Linux Startup Script           ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed"
    echo "Please install Python from: https://www.python.org/downloads/"
    exit 1
fi

python3 --version
echo "✅ Python found"
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
    echo "✅ Virtual environment created"
    echo ""
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate
echo "✅ Virtual environment activated"
echo ""

# Check if requirements are installed
if ! pip show flask > /dev/null 2>&1; then
    echo "📥 Installing dependencies from requirements.txt..."
    pip install -r requirements.txt
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install dependencies"
        exit 1
    fi
    echo "✅ Dependencies installed"
    echo ""
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found!"
    echo "📋 Copying .env.example to .env..."
    cp .env.example .env
    echo "⚠️  Please update .env with your MongoDB connection string"
    echo ""
fi

# Start the Flask server
echo "🚀 Starting Flask server..."
echo ""
python run.py
