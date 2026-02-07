# Stop existing server if running
Write-Host "🛑 Stopping server.exe..." -ForegroundColor Yellow
Stop-Process -Name "server" -ErrorAction SilentlyContinue

# Build Compiler Image
Write-Host "🏗️ Building Compiler Image..." -ForegroundColor Cyan
docker build -t beamng-compiler .

# Compile C++ Server
Write-Host "🔨 Compiling server.exe (Arrow Keys + Space)..." -ForegroundColor Cyan
# Using local volume mount to compile
docker run --rm -v ${PWD}:/src beamng-compiler x86_64-w64-mingw32-g++ server.cpp -o server.exe -static -lws2_32

if (-not (Test-Path "server.exe")) {
    Write-Error "Compilation failed! server.exe not found."
    exit 1
}

# Rebuild Web App (to update Python SDK)
Write-Host "🌐 Rebuilding Web App..." -ForegroundColor Cyan
docker build -f Dockerfile.web -t beamng-web .

# Restart Web Container
Write-Host "🔄 Restarting Web Container..." -ForegroundColor Cyan
docker rm -f beamng-web-ide
docker run -d -p 8001:8000 --add-host host.docker.internal:host-gateway --name beamng-web-ide beamng-web

Write-Host "✅ Update Complete!" -ForegroundColor Green
Write-Host "1. server.exe has been updated (Arrow Keys)."
Write-Host "2. Web App has been updated (Handbrake support)."
Write-Host "3. Please start server.exe manually if not started."

# Attempt to start server.exe (as background job or separate window? PowerShell Start-Process is good)
Write-Host "🚀 Starting server.exe..." -ForegroundColor Green
Start-Process -FilePath ".\server.exe" -WindowStyle Minimized

Write-Host "Car Server is running in background (Minimized)."
