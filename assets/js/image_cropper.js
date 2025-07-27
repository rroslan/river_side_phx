/**
 * ImageCropper Hook for Phoenix LiveView
 *
 * A custom image cropping tool that integrates with Phoenix LiveView to provide
 * client-side image manipulation capabilities. Uses the browser's built-in Canvas API
 * for image processing without external dependencies.
 *
 * @module ImageCropper
 *
 * @example
 * // In your LiveView template:
 * <div id="image-cropper" phx-hook="ImageCropper">
 *   <input type="file" data-image-input accept="image/*" />
 *   <canvas data-crop-canvas></canvas>
 *   <button data-crop-button>Crop Image</button>
 * </div>
 *
 * @property {HTMLElement} el - The root element with the hook attached
 * @property {HTMLCanvasElement} canvas - The canvas element for drawing the image and crop area
 * @property {CanvasRenderingContext2D} ctx - The 2D rendering context for the canvas
 * @property {HTMLInputElement} imageInput - File input element for image selection
 * @property {HTMLButtonElement} cropButton - Button to trigger the crop action
 * @property {Image} image - The loaded image object
 * @property {Object} cropData - Current crop area configuration
 * @property {number} cropData.x - X coordinate of crop area
 * @property {number} cropData.y - Y coordinate of crop area
 * @property {number} cropData.width - Width of crop area
 * @property {number} cropData.height - Height of crop area
 * @property {number} cropData.aspectRatio - Aspect ratio constraint (width/height)
 */
export default {
  /**
   * Lifecycle callback - Called when the hook is mounted to the DOM
   *
   * Initializes the image cropper by:
   * 1. Setting up DOM element references
   * 2. Creating bound event handlers for proper cleanup
   * 3. Initializing crop data with defaults
   * 4. Setting up event listeners for user interaction
   *
   * @returns {void}
   */
  /**
   * Lifecycle callback - Called when the hook is mounted to the DOM
   *
   * Initializes the image cropper by:
   * 1. Setting up DOM element references
   * 2. Creating bound event handlers for proper cleanup
   * 3. Initializing crop data with defaults
   * 4. Setting up event listeners for user interaction
   *
   * @returns {void}
   */
  mounted() {
    console.log("ImageCropper hook mounted");

    // Store bound event handlers so we can remove them later
    // This is crucial for proper memory management and preventing duplicate listeners
    this.handleImageSelectBound = (e) => this.handleImageSelect(e);
    this.handleMouseDownBound = (e) => this.handleMouseDown(e);
    this.handleMouseMoveBound = (e) => this.handleMouseMove(e);
    this.handleMouseUpBound = (e) => this.handleMouseUp(e);
    this.handleTouchStartBound = (e) => this.handleTouchStart(e);
    this.handleTouchMoveBound = (e) => this.handleTouchMove(e);
    this.handleTouchEndBound = (e) => this.handleTouchEnd(e);
    this.cropImageBound = () => this.cropImage();

    this.cropperContainer = this.el.querySelector("[data-cropper-container]");
    this.imageInput = this.el.querySelector("[data-image-input]");
    this.cropButton = this.el.querySelector("[data-crop-button]");
    this.canvas = this.el.querySelector("[data-crop-canvas]");
    this.preview = this.el.querySelector("[data-crop-preview]");
    this.controls = this.el.querySelector("[data-crop-controls]");

    if (!this.canvas) {
      console.error("Canvas element not found");
      return;
    }

    this.ctx = this.canvas.getContext("2d");
    this.image = new Image();
    this.cropData = {
      x: 0,
      y: 0,
      width: 300,
      height: 300,
      aspectRatio: 1,
    };

    this.isDragging = false;
    this.isResizing = false;
    this.dragStart = { x: 0, y: 0 };
    this.resizeHandle = null;

    // Set up event listeners
    if (this.imageInput) {
      // Reset input on mount to ensure clean state
      this.imageInput.value = "";
      this.imageInput.addEventListener("change", this.handleImageSelectBound);
    } else {
      console.error("Image input element not found");
    }

    if (this.cropButton) {
      this.cropButton.addEventListener("click", this.cropImageBound);
    }

    // Listen for file input reset event
    this.handleEvent("reset_file_input", () => {
      console.log("Resetting file input");
      if (this.imageInput) {
        this.imageInput.value = "";
      }
    });

    // Listen for aspect ratio changes
    this.handleEvent("change_aspect_ratio", ({ ratio }) => {
      this.cropData.aspectRatio = ratio;
      if (ratio === 1) {
        this.cropData.width = this.cropData.height = Math.min(
          this.cropData.width,
          this.cropData.height,
        );
      } else if (ratio > 1) {
        this.cropData.height = this.cropData.width / ratio;
      } else {
        this.cropData.width = this.cropData.height * ratio;
      }
      this.drawCanvas();
    });
  },

  /**
   * Sets up mouse and touch event listeners on the canvas
   *
   * This method ensures clean event handling by:
   * 1. Removing any existing listeners to prevent duplicates
   * 2. Adding fresh listeners for mouse and touch interactions
   * 3. Setting up window-level listeners for drag operations that extend outside the canvas
   *
   * @private
   * @returns {void}
   */
  setupCanvasListeners() {
    // Remove any existing listeners first
    this.canvas.removeEventListener("mousedown", this.handleMouseDownBound);
    this.canvas.removeEventListener("mousemove", this.handleMouseMoveBound);
    this.canvas.removeEventListener("mouseup", this.handleMouseUpBound);
    this.canvas.removeEventListener("touchstart", this.handleTouchStartBound);
    this.canvas.removeEventListener("touchmove", this.handleTouchMoveBound);
    this.canvas.removeEventListener("touchend", this.handleTouchEndBound);
    window.removeEventListener("mousemove", this.handleMouseMoveBound);
    window.removeEventListener("mouseup", this.handleMouseUpBound);

    // Add fresh listeners
    this.canvas.addEventListener("mousedown", this.handleMouseDownBound);
    this.canvas.addEventListener("touchstart", this.handleTouchStartBound, {
      passive: false,
    });
    this.canvas.addEventListener("touchmove", this.handleTouchMoveBound, {
      passive: false,
    });
    this.canvas.addEventListener("touchend", this.handleTouchEndBound, {
      passive: false,
    });

    // Add window listeners for mouse move and up to handle dragging outside canvas
    window.addEventListener("mousemove", this.handleMouseMoveBound);
    window.addEventListener("mouseup", this.handleMouseUpBound);
  },

  /**
   * Handles file input change event when user selects an image
   *
   * Validates the selected file is an image, reads it using FileReader,
   * and loads it into the canvas for cropping.
   *
   * @param {Event} e - The change event from the file input
   * @returns {void}
   *
   * @fires image_loaded - Pushed to server with image dimensions when image loads successfully
   */
  handleImageSelect(e) {
    console.log("Image selected", e.target.files);
    const file = e.target.files[0];
    if (!file || !file.type.startsWith("image/")) {
      console.log("No valid image file selected");
      return;
    }

    const reader = new FileReader();
    reader.onload = (event) => {
      this.image.onload = () => {
        console.log("Image loaded successfully");
        this.setupCanvas();
        this.drawCanvas();
        if (this.canvas) {
          this.canvas.classList.remove("hidden");
          // Set up canvas event listeners after canvas is visible
          this.setupCanvasListeners();
        }
        if (this.controls) {
          this.controls.classList.remove("hidden");
        }
        this.pushEvent("image_loaded", {
          width: this.image.width,
          height: this.image.height,
        });
      };
      this.image.src = event.target.result;
    };
    reader.readAsDataURL(file);
  },

  /**
   * Configures canvas dimensions and initial crop area
   *
   * Scales the canvas to fit within the container while maintaining the image's
   * aspect ratio. Sets up initial crop area centered on the image with maximum
   * size that fits within bounds.
   *
   * @private
   * @returns {void}
   */
  setupCanvas() {
    // Set canvas size to fit container while maintaining aspect ratio
    const containerWidth = this.cropperContainer.offsetWidth;
    const containerHeight = 400; // Fixed height

    const scale = Math.min(
      containerWidth / this.image.width,
      containerHeight / this.image.height,
    );

    this.canvas.width = this.image.width * scale;
    this.canvas.height = this.image.height * scale;
    this.scale = scale;

    // Initialize crop area to center
    const cropSize = Math.min(this.canvas.width, this.canvas.height) * 0.8;
    this.cropData = {
      ...this.cropData,
      x: (this.canvas.width - cropSize) / 2,
      y: (this.canvas.height - cropSize) / 2,
      width: cropSize,
      height: cropSize,
    };

    // Make sure canvas is interactive
    this.canvas.style.cursor = "crosshair";
  },

  drawCanvas() {
    if (!this.image.src) return;

    // Clear canvas
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

    // Draw image
    this.ctx.drawImage(this.image, 0, 0, this.canvas.width, this.canvas.height);

    // Draw dark overlay
    this.ctx.fillStyle = "rgba(0, 0, 0, 0.5)";
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);

    // Clear crop area
    this.ctx.save();
    this.ctx.globalCompositeOperation = "destination-out";
    this.ctx.fillRect(
      this.cropData.x,
      this.cropData.y,
      this.cropData.width,
      this.cropData.height,
    );
    this.ctx.restore();

    // Draw crop area border
    this.ctx.strokeStyle = "#fff";
    this.ctx.lineWidth = 2;
    this.ctx.strokeRect(
      this.cropData.x,
      this.cropData.y,
      this.cropData.width,
      this.cropData.height,
    );

    // Draw resize handles
    this.drawResizeHandles();

    // Draw grid
    this.drawGrid();
  },

  drawResizeHandles() {
    const handles = this.getResizeHandles();
    this.ctx.fillStyle = "#fff";

    handles.forEach((handle) => {
      this.ctx.fillRect(handle.x - 4, handle.y - 4, 8, 8);
    });
  },

  drawGrid() {
    this.ctx.strokeStyle = "rgba(255, 255, 255, 0.3)";
    this.ctx.lineWidth = 1;

    // Draw thirds
    for (let i = 1; i <= 2; i++) {
      const x = this.cropData.x + (this.cropData.width / 3) * i;
      const y = this.cropData.y + (this.cropData.height / 3) * i;

      this.ctx.beginPath();
      this.ctx.moveTo(x, this.cropData.y);
      this.ctx.lineTo(x, this.cropData.y + this.cropData.height);
      this.ctx.stroke();

      this.ctx.beginPath();
      this.ctx.moveTo(this.cropData.x, y);
      this.ctx.lineTo(this.cropData.x + this.cropData.width, y);
      this.ctx.stroke();
    }
  },

  getResizeHandles() {
    const { x, y, width, height } = this.cropData;
    return [
      { name: "nw", x: x, y: y },
      { name: "n", x: x + width / 2, y: y },
      { name: "ne", x: x + width, y: y },
      { name: "e", x: x + width, y: y + height / 2 },
      { name: "se", x: x + width, y: y + height },
      { name: "s", x: x + width / 2, y: y + height },
      { name: "sw", x: x, y: y + height },
      { name: "w", x: x, y: y + height / 2 },
    ];
  },

  /**
   * Handles mouse down events on the canvas
   *
   * Determines if the user clicked on:
   * 1. A resize handle - initiates resize mode
   * 2. Inside the crop area - initiates drag mode
   * 3. Outside the crop area - no action
   *
   * @param {MouseEvent} e - The mouse down event
   * @returns {void}
   */
  handleMouseDown(e) {
    e.preventDefault();
    const rect = this.canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;

    console.log("Mouse down at:", x, y);
    console.log("Crop area:", this.cropData);

    // Check if clicking on resize handle
    const handles = this.getResizeHandles();
    for (let handle of handles) {
      if (Math.abs(x - handle.x) < 8 && Math.abs(y - handle.y) < 8) {
        this.isResizing = true;
        this.resizeHandle = handle.name;
        this.dragStart = { x, y };
        this.canvas.style.cursor = this.getCursorForHandle(handle.name);
        return;
      }
    }

    // Check if clicking inside crop area
    if (
      x >= this.cropData.x &&
      x <= this.cropData.x + this.cropData.width &&
      y >= this.cropData.y &&
      y <= this.cropData.y + this.cropData.height
    ) {
      this.isDragging = true;
      this.dragStart = { x: x - this.cropData.x, y: y - this.cropData.y };
      this.canvas.style.cursor = "move";
      console.log("Started dragging");
    }
  },

  handleMouseMove(e) {
    e.preventDefault();
    const rect = this.canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;

    if (this.isDragging) {
      this.cropData.x = Math.max(
        0,
        Math.min(x - this.dragStart.x, this.canvas.width - this.cropData.width),
      );
      this.cropData.y = Math.max(
        0,
        Math.min(
          y - this.dragStart.y,
          this.canvas.height - this.cropData.height,
        ),
      );
      this.drawCanvas();
    } else if (this.isResizing) {
      this.handleResize(x, y);
      this.drawCanvas();
    } else {
      // Update cursor based on hover position
      this.updateCursor(x, y);
    }
  },

  handleMouseUp(e) {
    e.preventDefault();
    console.log("Mouse up - stopping drag/resize");
    this.isDragging = false;
    this.isResizing = false;
    this.resizeHandle = null;
    this.updateCursor(
      e.clientX - this.canvas.getBoundingClientRect().left,
      e.clientY - this.canvas.getBoundingClientRect().top,
    );
  },

  handleTouchStart(e) {
    e.preventDefault();
    const touch = e.touches[0];
    const rect = this.canvas.getBoundingClientRect();
    const evt = {
      clientX: touch.clientX,
      clientY: touch.clientY,
    };
    this.handleMouseDown(evt);
  },

  handleTouchMove(e) {
    e.preventDefault();
    const touch = e.touches[0];
    const evt = {
      clientX: touch.clientX,
      clientY: touch.clientY,
    };
    this.handleMouseMove(evt);
  },

  handleTouchEnd(e) {
    e.preventDefault();
    this.handleMouseUp();
  },

  handleResize(x, y) {
    const { aspectRatio } = this.cropData;
    let newX = this.cropData.x;
    let newY = this.cropData.y;
    let newWidth = this.cropData.width;
    let newHeight = this.cropData.height;

    switch (this.resizeHandle) {
      case "se":
        newWidth = x - this.cropData.x;
        newHeight = aspectRatio === 1 ? newWidth : newWidth / aspectRatio;
        break;
      case "sw":
        newWidth = this.cropData.x + this.cropData.width - x;
        newHeight = aspectRatio === 1 ? newWidth : newWidth / aspectRatio;
        newX = x;
        break;
      case "ne":
        newWidth = x - this.cropData.x;
        newHeight = aspectRatio === 1 ? newWidth : newWidth / aspectRatio;
        newY = this.cropData.y + this.cropData.height - newHeight;
        break;
      case "nw":
        newWidth = this.cropData.x + this.cropData.width - x;
        newHeight = aspectRatio === 1 ? newWidth : newWidth / aspectRatio;
        newX = x;
        newY = this.cropData.y + this.cropData.height - newHeight;
        break;
    }

    // Ensure minimum size
    if (newWidth >= 50 && newHeight >= 50) {
      // Ensure within canvas bounds
      if (
        newX >= 0 &&
        newY >= 0 &&
        newX + newWidth <= this.canvas.width &&
        newY + newHeight <= this.canvas.height
      ) {
        this.cropData.x = newX;
        this.cropData.y = newY;
        this.cropData.width = newWidth;
        this.cropData.height = newHeight;
      }
    }
  },

  updateCursor(x, y) {
    const handles = this.getResizeHandles();
    for (let handle of handles) {
      if (Math.abs(x - handle.x) < 8 && Math.abs(y - handle.y) < 8) {
        this.canvas.style.cursor = this.getCursorForHandle(handle.name);
        return;
      }
    }

    if (
      x >= this.cropData.x &&
      x <= this.cropData.x + this.cropData.width &&
      y >= this.cropData.y &&
      y <= this.cropData.y + this.cropData.height
    ) {
      this.canvas.style.cursor = "move";
    } else {
      this.canvas.style.cursor = "default";
    }
  },

  getCursorForHandle(handle) {
    const cursors = {
      nw: "nw-resize",
      n: "n-resize",
      ne: "ne-resize",
      e: "e-resize",
      se: "se-resize",
      s: "s-resize",
      sw: "sw-resize",
      w: "w-resize",
    };
    return cursors[handle] || "default";
  },

  cropImage() {
    // Create a new canvas for the cropped image
    const cropCanvas = document.createElement("canvas");
    const cropCtx = cropCanvas.getContext("2d");

    // Calculate actual crop dimensions on original image
    const scaleX = this.image.width / this.canvas.width;
    const scaleY = this.image.height / this.canvas.height;

    const sourceX = this.cropData.x * scaleX;
    const sourceY = this.cropData.y * scaleY;
    const sourceWidth = this.cropData.width * scaleX;
    const sourceHeight = this.cropData.height * scaleY;

    // Set output size (max 800px for web optimization)
    const maxSize = 800;
    const outputScale = Math.min(
      1,
      maxSize / Math.max(sourceWidth, sourceHeight),
    );

    cropCanvas.width = sourceWidth * outputScale;
    cropCanvas.height = sourceHeight * outputScale;

    // Draw cropped image
    cropCtx.drawImage(
      this.image,
      sourceX,
      sourceY,
      sourceWidth,
      sourceHeight,
      0,
      0,
      cropCanvas.width,
      cropCanvas.height,
    );

    // Convert to blob and send to server
    cropCanvas.toBlob(
      (blob) => {
        const reader = new FileReader();
        reader.onloadend = () => {
          this.pushEvent("image_cropped", {
            data: reader.result,
            width: cropCanvas.width,
            height: cropCanvas.height,
          });
          // Reset file input after successful crop
          if (this.imageInput) {
            this.imageInput.value = "";
          }
        };
        reader.readAsDataURL(blob);
      },
      "image/jpeg",
      0.9,
    );
  },

  /**
   * Lifecycle callback - Called when the hook is removed from the DOM
   *
   * Performs cleanup by removing all event listeners to prevent memory leaks
   * and ensure proper garbage collection of resources.
   *
   * @returns {void}
   */
  destroyed() {
    // Clean up event listeners
    if (this.imageInput) {
      this.imageInput.removeEventListener(
        "change",
        this.handleImageSelectBound,
      );
    }
    if (this.canvas) {
      this.canvas.removeEventListener("mousedown", this.handleMouseDownBound);
      this.canvas.removeEventListener("touchstart", this.handleTouchStartBound);
      this.canvas.removeEventListener("touchmove", this.handleTouchMoveBound);
      this.canvas.removeEventListener("touchend", this.handleTouchEndBound);
    }
    // Clean up window listeners
    window.removeEventListener("mousemove", this.handleMouseMoveBound);
    window.removeEventListener("mouseup", this.handleMouseUpBound);

    if (this.cropButton) {
      this.cropButton.removeEventListener("click", this.cropImageBound);
    }
  },
};
