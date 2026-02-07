Write-Host "🛑 Killing any stuck server.exe processes..." -ForegroundColor Yellow
Stop-Process -Name "server" -Force -ErrorAction SilentlyContinue

Write-Host "🛑 Stopping Web IDE Container..." -ForegroundColor Yellow
docker stop beamng-web-ide
docker rm beamng-web-ide

Write-Host "⏳ Waiting 2 seconds for ports to clear..." -ForegroundColor Cyan
Start-Sleep -Seconds 2

Write-Host "🚀 Starting server.exe (TCP Server)..." -ForegroundColor Green
# Start server in a new minimized window so it persists
Start-Process -FilePath ".\server.exe" -WindowStyle Minimized

Write-Host "🚀 Starting Web IDE Container..." -ForegroundColor Green
docker run -d -p 8001:8000 --add-host host.docker.internal:host-gateway --name beamng-web-ide beamng-web

Write-Host "`n✅ SYSTEM RESTARTED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "1. TCP Server is running (check minimized window)."
Write-Host "2. Web IDE is at http://localhost:8001"
Write-Host "3. Projector View is at http://localhost:8001/projector"
