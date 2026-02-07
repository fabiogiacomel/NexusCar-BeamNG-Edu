# Build the Docker Image for the Web IDE
Write-Host "🚧 Building Web IDE Container..." -ForegroundColor Cyan
docker build -f Dockerfile.web -t beamng-web .

if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker build failed."
    exit $LASTEXITCODE
}

# Run the Container
# We map internal port 8000 to host port 8001 (to avoid conflict with existing services on 8000)
# We add the host gateway to allow the container to talk to the Windows host on 'host.docker.internal'
# We expose UDP Port 4444 for OutGauge Telemetry
Write-Host "🚀 Starting Web IDE..." -ForegroundColor Green
docker run -d -p 8001:8000 -p 4444:4444/udp --add-host host.docker.internal:host-gateway --name beamng-web-ide beamng-web

Write-Host "`n✅ Web IDE is running!" -ForegroundColor Yellow
Write-Host "   -> Access locally: http://localhost:8001"
Write-Host "   -> Student Access: http://<YOUR_LAN_IP>:8001"

Write-Host "TELEMETRY CONFIGURATION:" -ForegroundColor Cyan
Write-Host "   1. Open BeamNG.drive"
Write-Host "   2. Go to Options > Others"
Write-Host "   3. Enable 'OutGauge Support'"
Write-Host "   4. Set IP: 127.0.0.1"
Write-Host "   5. Set Port: 4444"
Write-Host "   6. Check 'Use UDP'"

Write-Host "To stop: docker stop beamng-web-ide; docker rm beamng-web-ide"
