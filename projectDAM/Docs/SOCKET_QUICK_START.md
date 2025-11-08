# Socket.IO Quick Start

## ⚡ Installation (Required)

### Add Socket.IO Package

1. Open Xcode: `open projectDAM.xcodeproj`
2. **File** → **Add Package Dependencies**
3. URL: `https://github.com/socketio/socket.io-client-swift`
4. Version: **16.1.0**
5. Add **SocketIO** library

### Add Files to Xcode

Drag these files into Xcode project:
- `projectDAM/Models/SocketModels.swift`
- `projectDAM/Services/SocketService.swift`

Make sure "Copy items if needed" is checked and target is selected.

## ✅ What's Already Configured

- ✅ Socket service created and configured
- ✅ Auto-connects after login
- ✅ Auto-authenticates with JWT token
- ✅ Heartbeat every 30 seconds
- ✅ Auto-reconnection on disconnect
- ✅ Token expiration warnings
- ✅ Session termination handling

## 🔧 Configuration

Socket URL is auto-configured from your API base URL:
- **Simulator**: `http://127.0.0.1:3001`
- **Physical Device**: Update IP in `Config.local.xcconfig`

## 📱 How It Works

1. User logs in → JWT token received
2. Socket connects to server
3. Socket authenticates with JWT token
4. Heartbeat starts (every 30s)
5. Real-time events are handled automatically

## 🎯 Events Handled

| Event | Description |
|-------|-------------|
| `authenticationSuccess` | Socket authenticated successfully |
| `sessionTerminated` | Session ended (logout or error) |
| `tokenExpirationWarning` | Token expiring soon |
| `heartbeatAck` | Heartbeat acknowledged |
| `userConnected` | Another user connected |
| `userDisconnected` | User disconnected |

## 🔍 Monitoring Socket State

```swift
// In any ViewModel
let socketService = DIContainer.shared.socketService

// Check connection
if socketService.isAuthenticated {
    print("Socket is connected and authenticated")
}

// Monitor state changes
socketService.connectionState
    .sink { state in
        print("Socket state: \(state.description)")
    }
    .store(in: &cancellables)
```

## 🚨 Troubleshooting

### Socket not connecting
1. Ensure backend is running: `npm run dev`
2. Check URL in console output
3. For physical device, use Mac's IP not 127.0.0.1

### Authentication failing
1. Check JWT token is valid
2. Verify backend socket server is running
3. Check console for error messages

### Package not found
1. Clean build: `Cmd + Shift + K`
2. Delete derived data
3. Restart Xcode
4. Re-add package

## 📝 Testing

1. Start backend server
2. Run iOS app
3. Login with credentials
4. Check Xcode console for socket logs:
   ```
   🔌 Connecting to socket server...
   ✅ Socket connected
   🔐 Authenticating with token...
   ✅ Authentication successful
   💓 Heartbeat started (interval: 30.0s)
   ```

## 🎉 Done!

Socket.IO is now integrated and will automatically handle real-time communication!
