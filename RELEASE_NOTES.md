# Veltrix Security v1.0.0 - Release Notes

**Date:** October 11, 2026  
**Status:** ✅ Release Ready

---

## What's New

### 🎯 Core Features
- **Real Scheduled Cleanup:** Automated cleaning runs on your schedule
- **Expanded Privacy Scanner:** Tracks cookies across 6+ browsers (Safari, Chrome, Firefox, Brave, Edge, Arc)
- **Defensive Threat Analysis:** Audits startup items and persistence mechanisms
- **Performance Monitoring:** Real-time CPU and memory insights
- **App Intents & Shortcuts:** Control cleaning directly from Siri

### 🔧 Under the Hood
- Swift 6 with complete concurrency safety
- 30+ automated tests ensuring reliability
- Hardened Runtime for enhanced security
- Optimized polling (5-second intervals)
- Zero artificial delays—true operation reporting

---

## Installation

1. **Download:** VeltrixSecurity-1.0.0.dmg (4.8 MB)
2. **Mount:** Open the DMG file
3. **Install:** Drag VeltrixSecurity.app to /Applications
4. **Run:** Launch from /Applications or Spotlight

### System Requirements
- macOS 14.0 or later
- Apple Silicon (arm64) or Intel (x86_64)
- 50 MB free disk space

---

## Verification

### Check Installation
```bash
# Verify the app is accepted by Gatekeeper
spctl -a -v /Applications/VeltrixSecurity.app

# Should show: accepted, source=Developer ID
```

### Checksum Verification
```bash
# SHA256: 52e74323e4d8022f9eb8c49c6a21c66f43ccbc4845263bfc15ca39cdebb797ae
shasum -a 256 VeltrixSecurity-1.0.0.dmg
```

---

## Known Limitations

1. **Localization:** Currently ~33% localized (English, Spanish primary)
2. **Apple Intelligence:** Heuristic-based analysis (local, no external calls)
3. **Browser Support:** Limited to major browsers (not all browser extensions detectable)
4. **Sandbox:** Not currently sandboxed (full filesystem access for analysis)

---

## Troubleshooting

### App Won't Open
1. Verify Gatekeeper accepts it:
   ```bash
   spctl -a -v /Applications/VeltrixSecurity.app
   ```
2. Check Console.app for error messages
3. Verify macOS version is 14.0 or later

### Scheduled Cleanup Not Working
1. Verify app has Full Disk Access:
   System Settings > Privacy & Security > Full Disk Access
2. Check logs: `~/Library/Logs/MacGuardian_cleanup.log`
3. Ensure scheduled cleanup is enabled in settings

### High CPU Usage
1. This is normal during initial scans
2. Background polling uses ~2% CPU
3. Monitor processes in Activity Monitor

---

## Support & Feedback

- **Issues:** Report via GitHub Issues
- **Feature Requests:** GitHub Discussions
- **Security:** Send security concerns to security@example.com

---

## Version History

### v1.0.0 (October 11, 2026)
- ✅ Initial release
- ✅ All core features implemented
- ✅ 30+ tests passing
- ✅ Swift 6 compliance
- ✅ Zero critical warnings

---

## Legal

Veltrix Security is provided as-is. We recommend testing on non-critical systems before using in production environments.

---

**Download:** [VeltrixSecurity-1.0.0.dmg](https://github.com/cynaxia/veltrix-security/releases/download/v1.0.0/VeltrixSecurity-1.0.0.dmg)

