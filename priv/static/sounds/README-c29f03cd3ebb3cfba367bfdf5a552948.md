# Notification Sounds

This directory contains audio files for the River Side Food Court notification system.

## Current Sounds

### Order Notification
The vendor dashboard plays a notification sound when new orders arrive. Currently, we use an inline base64-encoded sound in the JavaScript code for instant loading.

## Adding Custom Sounds

To add a custom notification sound:

1. Place your audio file in this directory (preferably .mp3 or .wav format)
2. Keep files small (< 100KB) for fast loading
3. Update the JavaScript in `assets/js/app.js` to reference your sound file:

```javascript
// Instead of the base64 sound, use:
this.audio = new Audio("/sounds/your-notification.mp3");
```

## Recommended Sound Specifications

- **Format**: MP3 or WAV
- **Duration**: 0.5 - 2 seconds
- **Volume**: Normalized to -12dB
- **Sample Rate**: 44.1kHz or 48kHz
- **Bit Rate**: 128kbps (for MP3)

## Browser Compatibility

Modern browsers require user interaction before playing sounds. The notification system handles this by:
- Only playing sounds after the vendor has interacted with the page
- Catching and logging autoplay errors gracefully

## Testing Sounds

You can test notification sounds by:
1. Opening the vendor dashboard
2. Having another browser/user place an order
3. The sound should play when the new order appears

## License

Ensure any custom sounds added are either:
- Created by you
- Licensed for commercial use
- In the public domain