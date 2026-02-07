
<#
.SYNOPSIS
    Orchestration script for Building and Running the BeamNG Game Server.

.DESCRIPTION
    This script manages the lifecycle of the C++ game server:
    1. Builds the Docker cross-compiler image.
    2. Compiles the C++ source code using the Docker container.
    3. Checks and configures Windows Firewall rules.
    4. Runs the compiled game server executable.

.NOTES
    Role: DevOps Engineer
    Task: Create a PowerShell orchestration script.
#>

$ImageName = "beamng-compiler"
$SourceFile = "server.cpp"
$ExeName = "game_server.exe"
$Port = 65432

function Show-Menu {
    Clear-Host
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host "   BeamNG Server Manager    " -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host "1. Build Docker Image"
    Write-Host "2. Compile Server (Cross-compile)"
    Write-Host "3. Check/Add Firewall Rule"
    Write-Host "4. Run Server"
    Write-Host "5. Exit"
    Write-Host "============================" -ForegroundColor Cyan
}

function Build-DockerImage {
    Write-Host "Building Docker image '$ImageName'..." -ForegroundColor Yellow
    docker build -t $ImageName .
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Docker image built successfully." -ForegroundColor Green
    } else {
        Write-Host "Docker build failed." -ForegroundColor Red
    }
    Pause
}

function Compile-Server {
    Write-Host "Compiling '$SourceFile' to '$ExeName'..." -ForegroundColor Yellow
    
    # Ensure current directory is mounted to /src
    # Using ${PWD} might need formatting for Docker on Windows, but standard PowerShell usually works.
    # We use -v "${PWD}:/src" and -w "/src" (WORKDIR is already /src in Dockerfile)
    
    $BuildCmd = "x86_64-w64-mingw32-g++ $SourceFile -o $ExeName -static -lws2_32"
    
    docker run --rm -v "${PWD}:/src" $ImageName sh -c $BuildCmd
    
    if ($LASTEXITCODE -eq 0) {
        if (Test-Path $ExeName) {
            Write-Host "Compilation successful. '$ExeName' created." -ForegroundColor Green
        } else {
            Write-Host "Compilation command finished but '$ExeName' not found." -ForegroundColor Red
        }
    } else {
        Write-Host "Compilation failed." -ForegroundColor Red
    }
    Pause
}

function Check-Firewall {
    Write-Host "Checking firewall for Port $Port..." -ForegroundColor Yellow
    
    $RuleName = "BeamNG_GameServer_TCP_$Port"
    $ExistingRule = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue

    if ($ExistingRule) {
        Write-Host "Firewall rule '$RuleName' already exists." -ForegroundColor Green
    } else {
        Write-Host "Firewall rule for port $Port NOT found." -ForegroundColor Red
        $confirmation = Read-Host "Do you want to create a firewall rule now? (Y/N)"
        if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
            try {
                New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -LocalPort $Port -Protocol TCP -Action Allow
                Write-Host "Firewall rule created successfully." -ForegroundColor Green
            } catch {
                Write-Host "Failed to create firewall rule. Ensure you run this script as Administrator." -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
        } else {
            Write-Host "Skipping firewall rule creation." -ForegroundColor Yellow
        }
    }
    Pause
}

function Run-Server {
    if (-not (Test-Path $ExeName)) {
        Write-Host "Executable '$ExeName' not found. Please compile first (Option 2)." -ForegroundColor Red
        Pause
        return
    }

    Write-Host "Starting '$ExeName'..." -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop the server." -ForegroundColor Yellow
    
    # Run in current window
    & ./$ExeName
    
    Pause
}

# Main Loop
do {
    Show-Menu
    $choice = Read-Host "Select an option"
    switch ($choice) {
        '1' { Build-DockerImage }
        '2' { Compile-Server }
        '3' { Check-Firewall }
        '4' { Run-Server }
        '5' { Write-Host "Exiting..."; exit }
        default { Write-Host "Invalid option. Please try again." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} until ($choice -eq '5')
