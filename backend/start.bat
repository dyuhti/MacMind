@echo off
REM MacMind Backend Startup Script for Windows
REM This script sets up and runs the Flask server

echo.
echo ╔════════════════════════════════════════════╗
echo ║  MacMind Medical Calculator - Backend      ║
echo ║         Windows Startup Script             ║
echo ╚════════════════════════════════════════════╝
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python is not installed or not in PATH
    echo Please install Python from: https://www.python.org/downloads/
    pause
    exit /b 1
)

echo ✅ Python found
echo.

REM Check if virtual environment exists
if not exist "venv\" (
    echo 📦 Creating virtual environment...
    python -m venv venv
    echo ✅ Virtual environment created
    echo.
)

REM Activate virtual environment
echo 🔧 Activating virtual environment...
call venv\Scripts\activate.bat
echo ✅ Virtual environment activated
echo.

REM Check if requirements are installed
pip show flask >nul 2>&1
if errorlevel 1 (
    echo 📥 Installing dependencies from requirements.txt...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo ❌ Failed to install dependencies
        pause
        exit /b 1
    )
    echo ✅ Dependencies installed
    echo.
)

REM Check if .env file exists
if not exist ".env" (
    echo ⚠️  .env file not found!
    echo 📋 Copying .env.example to .env...
    copy .env.example .env
    echo ⚠️  Please update .env with your MongoDB connection string
    echo.
)

REM Start the Flask server
echo 🚀 Starting Flask server...
echo.
python run.py

REM Keep window open if there's an error
if errorlevel 1 (
    echo.
    echo ❌ Server failed to start
    pause
)
