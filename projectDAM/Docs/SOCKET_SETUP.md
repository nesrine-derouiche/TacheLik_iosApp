# Socket.IO Setup Guide

## Installation Steps

### 1. Add Socket.IO Package to Xcode

1. Open Xcode: `open projectDAM.xcodeproj`
2. Go to **File** → **Add Package Dependencies**
3. Enter URL: `https://github.com/socketio/socket.io-client-swift`
4. Version: **16.1.0** or latest
5. Select **SocketIO** library and add

### 2. Add Files to Project

Add these files to Xcode:
- `projectDAM/Models/SocketModels.swift`
- `projectDAM/Services/SocketService.swift`

Right-click on folders → Add Files → Select the files

### 3. Update LoginViewModel

The socket will auto-connect after login. Token is automatically used for authentication.

## Usage Example

```swift
// Access socket service
let socketService = DIContainer.shared.socketService

// Monitor connection state
socketService.connectionState
    .sink { state in
        print("Socket state: \(state.description)")
    }

// Check if connected
if socketService.isAuthenticated {
    print("Socket is authenticated")
}
```

## Events Handled

- ✅ Authentication
- ✅ Heartbeat (auto every 30s)
- ✅ Token expiration warnings
- ✅ Session termination
- ✅ User connect/disconnect
- ✅ Auto-reconnection

## Configuration

Socket URL is automatically derived from API base URL in `Config.xcconfig`:
- API: `http://127.0.0.1:3001/api`
- Socket: `http://127.0.0.1:3001`

For physical device, update IP in `Config.local.xcconfig`
