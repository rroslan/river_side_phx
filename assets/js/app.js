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
  NotificationSound: {
    mounted() {
      // Create audio element for notification sound
      this.audio = new Audio(
        "data:audio/wav;base64,UklGRjIGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQ4GAAC8/5v/nv+h/6T/qP+r/6//sv+2/7n/vP/A/8P/x//K/87/0f/V/9j/3P/f/+P/5v/q/+3/8f/0//j/+//+/wIABgAJAA0AEAAUABcAGwAeACIAJQApACwAMAA0ADcAOwA+AEIARQBJAEwAUABTAFcAWgBeAGEAZQBoAGwAbwBzAHYAegB9AIEAhACIAIsAjwCSAJYAmQCdAKAApACoAKsArwCyALYAuQC9AMAAxADHAMsAzgDSANUA2QDdAOAA5ADnAOsA7gDyAPUA+QD8AP8AAwEHAQoBDgERARUBGAEcAR8BIwEmASoBLQExATQBOAE7AT8BQgFGAUkBTQFQAVQBVwFbAV4BYgFlAWkBbAFwAXMBdwF6AX4BgQGFAYgBjAGPAZMBlgGaAZ0BoQGkAagBqwGvAbIBtgG5Ab0BwAHEAckBzAHQAdMB1wHaAd4B4QHlAegB7AHwAfMB9wH6Af4BAQIFAggCDAIPAhMCFgIaAh4CIQIlAigCLAIvAjMCNgI6Aj0CQQJEAkgCSwJPAlICVgJZAl0CYAJkAmcCawJvAnICdgJ5An0CgAKEAocCiwKOApIClQKZAp0CoAKkAqcCqwKuArICwQLFAsgCzALPAtMC1gLaAt0C4QLkAugC6wLvAvIC9gL5Av0CAAMEAwcDCwMOAxIDFQMZAxwDIAMjAycDKgMuAzEDNQM4AzwDPwNDA0YDSgNNA1EDVANXA1sDXgNiA2UDaQNsA3ADcwN3A3oDfgOBA4UDiAOMA48DkwOWA5oDnQOhA6QDqAOrA68DsgO2A7kDvAPAA8MDxwPKA84D0QPVA9gD3APfA+MD5gPqA+0D8QPyAPYD+gP9AwEEBQQIBAwEDwQTBBYEGgQdBCEEJAQoBCsELwQyBDYEOQQ9BEAERAHDAMcEygDOBNEE1QTYBNwE3wTjBOYE6gTtBPEE9AT4BPsE/wQCBQYFCQUNBRAFFAUXBRsFHgUiBSUFKQUsBS8FMwU2BToFPQVBBUQFSAVLBU8FUgVWBVkFXQVgBWQFZwVrBW4FcgV1BXkFfAWABYMFhwWKBY4FkQWVBZgFnAWfBaMFpgWqBa0FsQW0BbgFuwW/BcIFxgXJBc0F0AXUBdcF2gXeBOEF5QXoBewF7wXzBfYF+gX9BQEGBAYIBgsGDwYSBhYGGQYdBiAGJAYnBisGLgYyBjUGOAY8Bj8GQwZGBkoGTQZRBlQGWAZbBl8GYgZlBmkGbAZwBnMGdwZ6Bn4GgQaFBogGjAaPBpMGlgaaBp0GoQakBqgGqwaoBq8GlgawBrUGuQa8BsAGwwbGBsAGqAawBpYGlgaoBsAGxgbABqgGlgY=",
      );

      // Handle the custom event from LiveView
      this.handleEvent("play-notification-sound", () => {
        // Play the notification sound
        this.audio.play().catch((e) => {
          // Handle autoplay restrictions
          console.log("Could not play notification sound:", e);
        });
      });
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
