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

      // Create audio element for notification sound - pleasant ping/chime
      this.audio = new Audio(
        "data:audio/mpeg;base64,//uQxAAAAAAAAAAAAAAAAAAAAAAASW5mbwAAAA8AAAAJAAAJcABCQkJCQkJCQkJCXl5eXl5eXl5eXnp6enp6enp6enqVlZWVlZWVlZWVsbGxsbGxsbGxsc3Nzc3Nzc3Nzc3p6enp6enp6enp//////////////////8AAAA5TEFNRTMuOThyAaUAAAAALCQAABRGJAILQgAARgAACXC8w0MJAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//uQxAAOUx1TOa2YgDAAADSAAAAEYFQAfQJfj/AgCAIAgGHluTkxAAQ/KBjwQMH/6BVVVVW//VVVd6oFVVWBVVf/qq3qgVVVYFX//6qr1QAAoGAgGP//h/4IIECAR/BA8H//4nE5xPEZxOcRAoFEwGA4HA/ygKIxGYJ+4n0+JnA++f+b5jHz//4mATUDn+OD35fm+Y38////kAOFBAEQhjLLdYSi1YGAGAL1tKcUL/gNhwRcAAAvgAGV8pUdZgCYHGCBgCZAmH5gMwD3fRNT9/Sf/85DE3ZNGNOQBLdgAxETjAcwMMDTAcwXJQJTfNIjOqDF8i5HN80uv/wQBAAAECREBJjRVN5HNY3nM7jOpDOczJ4zqA0fMySNGH/vQBAAAIICBFJGBZiQgAD2K+pKP////5N/mxuJyMb9iTnxyJHnZJNJCCgUGBQCjhCkFEOQkYY4rQ//qHdnGBgCAJoQoJgwdQ4GhQAJigz////OQBOGEAG2tEJCkqoYh/qDHQ5iKKPElBpHJHJTjGQcCOdqkB5i4OUYFBgRgA4IahfnHBRg//+QxN2WAHTcATqYAR5NwFpzH3w/yPyOpMOpL8n/JZOOf6wEQoOAQgJ7g8Mf/f4P+c3//8n//xP/CgkD8z7/3//8kCMAAQhBNJJHmJxEQPCgbZGxLEtZHHH///5DxJJzJJJJOJJJJGT/w4kJEAcOHyJJEgAAAqSoqkrROJETjQGcnGzYl/kzGYzGYy/jIrTKgKbdhjm3zJ//////85DE9IsNHNQBP0gBnJ/+P//+ZAAAD0uTJHOdHJkcjJJN5yT/8H/JP///4cSUkkkkkkk4k/8TiQABEQ4HBQCAAADSQaQaGRGJP/9Cov///5DVxrGsb//////Ef/84ASiWNRjGP//GRGJsSST/w4zGNCMVjGRkYmSGJDjG6wOJHJA0f///+HEgaNxEzMyMyYxIsC0bkR8Q0aFhSYBo2P/zkMTKiZjsygE/kACJkUNBiJn///4o8QCQSSTvGNxiZGQkmJkSSRxJI8Y0OJBmMZGJEQkAOdGSZDGcJ+JP/w4k/wfySokkOJ/w5JJLEggkj//k///5P/8D+TiT2BJNAkp4n//kwkckiSSRJMJP/w4ckSTjyQJJJJkkEkjwJJJOJJJI//4gkSST//9IEgyJIkjNgVv+aFNJIkD///+QxN6L5OzGCT+YALLJNHFH////////////HP/TUTQz+JJBpJJJJJJJJJzJJJUJJJDjQJpKJNJEowKP/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////85DFAQkQvJQBP5gAAAADSAAAAEpJJJiJJJJJJJJJOJJJJLBpBJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJIQU=",
      );

      // Track if sound is enabled
      this.soundEnabled = false;

      // Enable sound on first user interaction
      this.enableSound = () => {
        if (!this.soundEnabled) {
          this.soundEnabled = true;
          console.log("Sound notifications enabled");
          // Try to play a silent sound to unlock audio
          this.audio.volume = 0;
          this.audio
            .play()
            .then(() => {
              this.audio.volume = 1;
              this.audio.pause();
              this.audio.currentTime = 0;
              console.log("Audio context unlocked successfully");
            })
            .catch((error) => {
              console.error("Failed to unlock audio context:", error);
            });
        }
      };

      // Add click listener to enable sound
      document.addEventListener("click", this.enableSound, { once: true });
      document.addEventListener("keydown", this.enableSound, { once: true });

      // Handle the custom event from LiveView
      this.handleEvent("play-notification-sound", () => {
        console.log("Received play-notification-sound event");

        if (!this.soundEnabled) {
          console.log("Sound not yet enabled - waiting for user interaction");
          return;
        }

        // Play the notification sound
        this.audio
          .play()
          .then(() => {
            console.log("Notification sound played successfully");
          })
          .catch((error) => {
            console.error("Failed to play notification sound:", error);
          });
      });

      // Handle enable sound event
      this.handleEvent("enable-sound", () => {
        console.log("Received enable-sound event");
        // Enable sound through user interaction
        this.enableSound();
        // Play a test sound to confirm it's working
        this.audio.volume = 0.5;
        this.audio
          .play()
          .then(() => {
            console.log("Test sound played successfully");
            this.audio.pause();
            this.audio.currentTime = 0;
            this.audio.volume = 1;
          })
          .catch((error) => {
            console.error("Failed to play test sound:", error);
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
