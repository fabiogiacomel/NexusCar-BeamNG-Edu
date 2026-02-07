#define _WIN32_WINNT 0x0501 // Target Windows XP or later
#include <winsock2.h>
#include <windows.h>
#include <stdio.h>
#include <string.h>

#pragma comment(lib, "ws2_32.lib") // Link with ws2_32.lib

#define PORT 65432
#define BUFFER_SIZE 32
#define WATCHDOG_MS 500

// Usage:
// Arrow Keys need KEYEVENTF_EXTENDEDKEY
// Scan codes:
// Up: 0x48, Left: 0x4B, Right: 0x4D, Down: 0x50
// Space: 0x39 (Not extended)

#define SCAN_UP    0x48
#define SCAN_DOWN  0x50
#define SCAN_LEFT  0x4B
#define SCAN_RIGHT 0x4D
#define SCAN_SPACE 0x39

// Global state tracking
bool up_down = false;
bool down_down = false;
bool left_down = false;
bool right_down = false;
bool space_down = false;

void send_input(WORD scanCode, bool keyUp, bool isExtended) {
    INPUT inputs[1] = {};
    inputs[0].type = INPUT_KEYBOARD;
    inputs[0].ki.wScan = scanCode;
    inputs[0].ki.dwFlags = KEYEVENTF_SCANCODE;
    
    if (isExtended) {
        inputs[0].ki.dwFlags |= KEYEVENTF_EXTENDEDKEY;
    }
    
    if (keyUp) {
        inputs[0].ki.dwFlags |= KEYEVENTF_KEYUP;
    }
    
    SendInput(1, inputs, sizeof(INPUT));
}

void release_all_keys() {
    printf("[FAILSAFE] Releasing all keys!\n");
    if (up_down) { send_input(SCAN_UP, true, true); up_down = false; }
    if (down_down) { send_input(SCAN_DOWN, true, true); down_down = false; }
    if (left_down) { send_input(SCAN_LEFT, true, true); left_down = false; }
    if (right_down) { send_input(SCAN_RIGHT, true, true); right_down = false; }
    if (space_down) { send_input(SCAN_SPACE, true, false); space_down = false; }
}

void handle_command(char* cmd) {
    // Trim newline
    cmd[strcspn(cmd, "\r\n")] = 0;
    
    // FWD -> Arrow Up
    if (strcmp(cmd, "FWD_DN") == 0) {
        if (!up_down) { send_input(SCAN_UP, false, true); up_down = true; }
    } else if (strcmp(cmd, "FWD_UP") == 0) {
        if (up_down) { send_input(SCAN_UP, true, true); up_down = false; }
        
    // LFT -> Arrow Left
    } else if (strcmp(cmd, "LFT_DN") == 0) {
        if (!left_down) { send_input(SCAN_LEFT, false, true); left_down = true; }
    } else if (strcmp(cmd, "LFT_UP") == 0) {
        if (left_down) { send_input(SCAN_LEFT, true, true); left_down = false; }
        
    // RGT -> Arrow Right
    } else if (strcmp(cmd, "RGT_DN") == 0) {
        if (!right_down) { send_input(SCAN_RIGHT, false, true); right_down = true; }
    } else if (strcmp(cmd, "RGT_UP") == 0) {
        if (right_down) { send_input(SCAN_RIGHT, true, true); right_down = false; }
        
    // BCK -> Arrow Down (Brake/Reverse)
    } else if (strcmp(cmd, "BCK_DN") == 0) { 
        if (!down_down) { send_input(SCAN_DOWN, false, true); down_down = true; }
    } else if (strcmp(cmd, "BCK_UP") == 0) {
        if (down_down) { send_input(SCAN_DOWN, true, true); down_down = false; }
        
    // BRK -> Legacy mapping to Arrow Down (just in case)
    } else if (strcmp(cmd, "BRK_DN") == 0) { 
        if (!down_down) { send_input(SCAN_DOWN, false, true); down_down = true; }
    } else if (strcmp(cmd, "BRK_UP") == 0) {
        if (down_down) { send_input(SCAN_DOWN, true, true); down_down = false; }
        
    // HND -> Spacebar (Handbrake)
    } else if (strcmp(cmd, "HND_DN") == 0) {
        if (!space_down) { send_input(SCAN_SPACE, false, false); space_down = true; }
    } else if (strcmp(cmd, "HND_UP") == 0) {
        if (space_down) { send_input(SCAN_SPACE, true, false); space_down = false; }
        
    } else {
        // Unknown or empty
    }
}

int main() {
    WSADATA wsaData;
    int iResult;

    // Initialize Winsock
    iResult = WSAStartup(MAKEWORD(2, 2), &wsaData);
    if (iResult != 0) {
        printf("WSAStartup failed: %d\n", iResult);
        return 1;
    }

    struct sockaddr_in server_addr, client_addr;
    int server_fd, client_fd;
    int addr_len = sizeof(client_addr);

    // Create socket
    server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd == INVALID_SOCKET) {
        printf("Socket creation failed: %d\n", WSAGetLastError());
        WSACleanup();
        return 1;
    }

    // Bind
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    // server_addr.sin_addr.s_addr = inet_addr("0.0.0.0"); // Explicitly any
    server_addr.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr *)&server_addr, sizeof(server_addr)) == SOCKET_ERROR) {
        printf("Bind failed: %d\n", WSAGetLastError());
        closesocket(server_fd);
        WSACleanup();
        return 1;
    }

    // Listen
    if (listen(server_fd, 1) == SOCKET_ERROR) {
        printf("Listen failed: %d\n", WSAGetLastError());
        closesocket(server_fd);
        WSACleanup();
        return 1;
    }

    printf("Server listening on port %d (Arrow Keys Mode)...\n", PORT);

    while (1) {
        printf("Waiting for connection...\n");
        client_fd = accept(server_fd, (struct sockaddr *)&client_addr, &addr_len);
        if (client_fd == INVALID_SOCKET) {
            printf("Accept failed: %d\n", WSAGetLastError());
            continue;
        }

        printf("Client connected.\n");

        // Set Receive Timeout for Failsafe
        DWORD timeout = WATCHDOG_MS;
        if (setsockopt(client_fd, SOL_SOCKET, SO_RCVTIMEO, (const char*)&timeout, sizeof(timeout)) < 0) {
            printf("Error setting socket timeout\n");
        }

        char buffer[BUFFER_SIZE];
        while (1) {
            int bytes_received = recv(client_fd, buffer, BUFFER_SIZE - 1, 0);
            
            if (bytes_received > 0) {
                buffer[bytes_received] = '\0';
                
                // Handle split packets
                char *token = strtok(buffer, "\n");
                while (token != NULL) {
                    handle_command(token);
                    token = strtok(NULL, "\n");
                }
                
            } else {
                if (bytes_received == 0) {
                    printf("Client disconnected.\n");
                } else {
                    int err = WSAGetLastError();
                    if (err == WSAETIMEDOUT) {
                        printf("Watchdog timeout (%dms) - No data received.\n", WATCHDOG_MS);
                    } else {
                        printf("Recv failed: %d\n", err);
                    }
                }
                
                // FAILSAFE
                release_all_keys();
                closesocket(client_fd);
                break;
            }
        }
    }

    closesocket(server_fd);
    WSACleanup();
    return 0;
}
