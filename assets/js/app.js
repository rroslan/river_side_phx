/**
 * @fileoverview Main JavaScript entry point for River Side Food Court application.
 *
 * This file initializes Phoenix LiveView, sets up WebSocket connections,
 * configures hooks for interactive components, and manages client-side
 * features like modal handling and progress indicators.
 *
 * @module app
 */

// Phoenix Channels Configuration
// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// Dependency Management
// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";

/**
 * LiveView and WebSocket Configuration
 * Establishes real-time communication between client and server
 */
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { hooks as colocatedHooks } from "phoenix-colocated/river_side";
import topbar from "../vendor/topbar";
import ImageCropper from "./image_cropper";

/**
 * CSRF Token for Security
 * Extracted from meta tag to ensure secure form submissions
 */
const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

/**
 * LiveView Hooks Registry
 * Combines built-in hooks with custom components
 *
 * @property {Object} ImageCropper - Hook for handling image upload and cropping
 */
const Hooks = {
  ...colocatedHooks,
  ImageCropper: ImageCropper,
  VendorDashboard: {
    mounted() {
      console.log("VendorDashboard hook mounted");

      // Listen for debug updates
      this.handleEvent("debug-update", (data) => {
        console.log("VendorDashboard: Received real-time update!", data);
        console.log(`  - Order count: ${data.order_count}`);
        console.log(`  - Timestamp: ${data.timestamp}`);
        console.log(`  - This proves real-time updates are working!`);

        // Force a visual indicator that update was received
        const dashboard = document.getElementById("vendor-dashboard");
        if (dashboard) {
          // Flash green border to show update received
          dashboard.style.borderTop = "5px solid #00ff00";
          dashboard.style.transition = "border-top 0.3s ease";
          setTimeout(() => {
            dashboard.style.borderTop = "5px solid #ff9900";
            setTimeout(() => {
              dashboard.style.borderTop = "";
            }, 300);
          }, 300);
        }

        // Also update the debug info if visible
        const debugInfo = document.querySelector(".fixed.bottom-4.right-4");
        if (debugInfo) {
          debugInfo.style.backgroundColor = "#00ff00";
          setTimeout(() => {
            debugInfo.style.backgroundColor = "";
          }, 500);
        }
      });

      // Monitor WebSocket connection
      this.checkConnection = setInterval(() => {
        // Check actual LiveSocket connection status instead of data attribute
        const connected = window.liveSocket && window.liveSocket.isConnected();
        console.log(`VendorDashboard: WebSocket connected: ${connected}`);

        // Only log additional details if connected
        if (connected) {
          console.log(
            "VendorDashboard: LiveView is connected and ready for updates",
          );
        }
      }, 5000);

      // Log initial connection state
      console.log(
        "VendorDashboard: Initial connection state:",
        window.liveSocket?.isConnected() || false,
      );

      // Listen for Phoenix channel events to debug
      this.channel = window.liveSocket?.channel;
      if (this.channel) {
        console.log("VendorDashboard: Phoenix channel available");
      }
    },

    destroyed() {
      console.log("VendorDashboard hook destroyed");
      if (this.checkConnection) {
        clearInterval(this.checkConnection);
      }
    },
  },
  NotificationSound: {
    mounted() {
      console.log("NotificationSound hook mounted");
      console.log("NotificationSound: Current page:", window.location.pathname);
      console.log(
        "NotificationSound: LiveSocket connected:",
        window.liveSocket?.isConnected(),
      );

      // Create a function to play notification sound using Web Audio API
      this.playSound = () => {
        try {
          const audioContext = new (window.AudioContext ||
            window.webkitAudioContext)();

          // Create oscillator for the main tone
          const oscillator = audioContext.createOscillator();
          const gainNode = audioContext.createGain();

          oscillator.connect(gainNode);
          gainNode.connect(audioContext.destination);

          // Pleasant notification sound - two quick beeps
          oscillator.frequency.value = 880; // A5 note
          gainNode.gain.value = 0.3;

          // Fade in
          gainNode.gain.setValueAtTime(0, audioContext.currentTime);
          gainNode.gain.linearRampToValueAtTime(
            0.3,
            audioContext.currentTime + 0.01,
          );

          // First beep
          gainNode.gain.linearRampToValueAtTime(
            0.3,
            audioContext.currentTime + 0.1,
          );
          gainNode.gain.linearRampToValueAtTime(
            0,
            audioContext.currentTime + 0.15,
          );

          // Second beep
          gainNode.gain.linearRampToValueAtTime(
            0.3,
            audioContext.currentTime + 0.2,
          );
          gainNode.gain.linearRampToValueAtTime(
            0,
            audioContext.currentTime + 0.3,
          );

          oscillator.start(audioContext.currentTime);
          oscillator.stop(audioContext.currentTime + 0.35);

          return Promise.resolve();
        } catch (error) {
          console.error(
            "NotificationSound: Error creating Web Audio sound:",
            error,
          );
          return Promise.reject(error);
        }
      };

      console.log("NotificationSound: Web Audio API sound function created");

      // Track if sound is enabled - default to true
      this.soundEnabled = true;

      // Enable sound and unlock audio context
      this.enableSound = () => {
        console.log("Enabling sound notifications");
        this.soundEnabled = true;
        // Try to create audio context to unlock it
        try {
          const audioContext = new (window.AudioContext ||
            window.webkitAudioContext)();
          if (audioContext.state === "suspended") {
            audioContext.resume().then(() => {
              console.log("Audio context unlocked successfully");
            });
          }
        } catch (error) {
          console.error("Failed to unlock audio context:", error);
        }
      };

      // Try to enable sound immediately
      this.enableSound();

      // Add click listener to enable sound
      document.addEventListener("click", this.enableSound, { once: true });
      document.addEventListener("keydown", this.enableSound, { once: true });

      // Handle the custom event from LiveView
      this.handleEvent("play-notification-sound", (payload) => {
        console.log(
          "NotificationSound: Received play-notification-sound event",
          payload,
        );
        console.log("NotificationSound: Sound enabled?", this.soundEnabled);
        console.log("NotificationSound: Audio element exists?", !!this.audio);
        console.log(
          "NotificationSound: Audio source:",
          this.audio?.src?.substring(0, 50) + "...",
        );

        // Play the notification sound
        if (this.soundEnabled) {
          this.playSound()
            .then(() => {
              console.log("NotificationSound: Sound played successfully!");
            })
            .catch((error) => {
              console.error("NotificationSound: Failed to play sound:", error);
              console.error("NotificationSound: Error name:", error.name);
              console.error("NotificationSound: Error message:", error.message);
              // Browser might require user interaction first
              if (error.name === "NotAllowedError") {
                console.log(
                  "NotificationSound: Browser requires user interaction for sound. Will play on next interaction.",
                );
                this.soundEnabled = false;
              }
            });
        }
      });

      // Handle enable sound event
      this.handleEvent("enable-sound", (payload) => {
        console.log(
          "NotificationSound: Received enable-sound event from server",
          payload,
        );
        // Enable sound through user interaction
        this.enableSound();
        // Play a test sound to confirm it's working
        this.playSound()
          .then(() => {
            console.log("NotificationSound: Test sound played successfully");
          })
          .catch((error) => {
            console.error(
              "NotificationSound: Failed to play test sound:",
              error,
            );
          });
      });
    },

    destroyed() {
      console.log("NotificationSound hook destroyed");
      // Clean up event listeners
      document.removeEventListener("click", this.enableSound);
      document.removeEventListener("keydown", this.enableSound);
    },
  },
};

/**
 * Modal Event Handlers
 * Manages opening and closing of modal dialogs triggered by server
 *
 * These events are dispatched by LiveView when modal operations are needed:
 * - phx:open_modal - Opens a modal with specified ID
 * - phx:close_modal - Closes a modal with specified ID
 */
window.addEventListener("phx:open_modal", (e) => {
  const modal = document.getElementById(e.detail.id);
  if (modal) modal.showModal();
});

window.addEventListener("phx:close_modal", (e) => {
  const modal = document.getElementById(e.detail.id);
  if (modal) modal.close();
});

/**
 * LiveSocket Configuration
 * Establishes WebSocket connection for real-time features
 *
 * @param {string} "/live" - WebSocket endpoint
 * @param {Socket} Socket - Phoenix Socket constructor
 * @param {Object} options - Configuration options
 * @param {number} options.longPollFallbackMs - Fallback to HTTP long polling after 2.5s
 * @param {Object} options.params - Parameters sent with each request
 * @param {Object} options.hooks - Custom hooks for LiveView components
 */
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Expose liveSocket globally for debugging
window.liveSocket = liveSocket;

/**
 * Progress Bar Configuration
 * Shows loading indicator during page transitions and form submissions
 *
 * The progress bar provides visual feedback for:
 * - LiveView navigation between pages
 * - Form submissions that take time
 * - Server-side operations
 */
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

/**
 * LiveSocket Connection
 * Initiates WebSocket connection if LiveView components are present
 */
liveSocket.connect();

// Log connection status
console.log("LiveSocket: Attempting to connect...");

// Monitor connection status
liveSocket.socket.onOpen(() => {
  console.log("LiveSocket: WebSocket connection opened successfully!");
  console.log(`LiveSocket: Connected = ${liveSocket.isConnected()}`);
});

liveSocket.socket.onError((e) => {
  console.error("LiveSocket: WebSocket connection error:", e);
});

liveSocket.socket.onClose((e) => {
  console.warn("LiveSocket: WebSocket connection closed:", e);
});

// Enable debug logging in development
if (window.location.hostname === "localhost") {
  liveSocket.enableDebug();
  console.log("LiveSocket: Debug mode enabled");
}

/**
 * Debug Tools
 * Exposes liveSocket globally for debugging in browser console
 *
 * Available commands:
 * - liveSocket.enableDebug() - Enable debug logging
 * - liveSocket.enableLatencySim(1000) - Simulate network latency
 * - liveSocket.disableLatencySim() - Disable latency simulation
 */
window.liveSocket = liveSocket;

/**
 * Development Tools (Development Environment Only)
 *
 * Phoenix Live Reload provides developer productivity features:
 * 1. Stream server logs to browser console
 * 2. Click on elements to jump to code definitions
 *
 * These features are only enabled in development mode for security
 * and performance reasons.
 */
if (process.env.NODE_ENV === "development") {
  window.addEventListener(
    "phx:live_reload:attached",
    ({ detail: reloader }) => {
      /**
       * Server Log Streaming
       * Streams Elixir server logs directly to browser console
       * Useful for debugging without switching windows
       */
      reloader.enableServerLogs();

      /**
       * Code Navigation Feature
       * Click on elements with modifier keys to open in editor:
       *
       * @key {c} - Open at caller location (where component is used)
       * @key {d} - Open at definition location (where component is defined)
       *
       * Requires PLUG_EDITOR environment variable to be configured
       */
      let keyDown;
      window.addEventListener("keydown", (e) => (keyDown = e.key));
      window.addEventListener("keyup", (e) => (keyDown = null));
      window.addEventListener(
        "click",
        (e) => {
          if (keyDown === "c") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtCaller(e.target);
          } else if (keyDown === "d") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtDef(e.target);
          }
        },
        true,
      );

      // Expose reloader for manual control if needed
      window.liveReloader = reloader;
    },
  );
}
