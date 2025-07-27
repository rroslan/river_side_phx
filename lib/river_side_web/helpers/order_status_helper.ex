defmodule RiverSideWeb.Helpers.OrderStatusHelper do
  @moduledoc """
  Centralized helper for order status display and styling.
  Ensures consistency across vendor, customer, and cashier views.

  This module provides a single source of truth for how order statuses
  are displayed throughout the River Side Food Court system. All status-related
  display logic should use these functions to maintain consistency.

  ## Order Status Flow

  The typical order lifecycle follows this progression:

  1. **Pending** - Customer has placed the order
  2. **Preparing** - Vendor has started preparing the order
  3. **Ready for Pickup** - Order is ready for customer collection
  4. **Completed** - Order has been picked up and paid for
  5. **Cancelled** - Order was cancelled (can happen from pending/preparing states)
  """

  @doc """
  Returns the display text for a given order status.

  This function provides human-readable status text that should be used
  consistently across all user interfaces.

  ## Examples

      iex> OrderStatusHelper.status_text("pending")
      "Pending"

      iex> OrderStatusHelper.status_text("ready")
      "Ready for Pickup"

      iex> OrderStatusHelper.status_text("unknown_status")
      "Unknown"
  """
  def status_text("pending"), do: "Pending"
  def status_text("preparing"), do: "Preparing"
  def status_text("ready"), do: "Ready for Pickup"
  def status_text("completed"), do: "Completed"
  def status_text("cancelled"), do: "Cancelled"
  def status_text(_), do: "Unknown"

  @doc """
  Returns the badge CSS class for a given order status.

  These classes use DaisyUI badge components with semantic colors
  to provide visual distinction between different order states.

  ## Color Meanings

  - **Warning (Yellow)** - Pending orders awaiting action
  - **Info (Blue)** - Orders being prepared
  - **Success (Green)** - Orders ready for pickup
  - **Neutral (Gray)** - Completed orders
  - **Error (Red)** - Cancelled orders

  ## Examples

      iex> OrderStatusHelper.status_badge_class("pending")
      "badge badge-warning"

      iex> OrderStatusHelper.status_badge_class("ready")
      "badge badge-success"
  """
  def status_badge_class("pending"), do: "badge badge-warning"
  def status_badge_class("preparing"), do: "badge badge-info"
  def status_badge_class("ready"), do: "badge badge-success"
  def status_badge_class("completed"), do: "badge badge-neutral"
  def status_badge_class("cancelled"), do: "badge badge-error"
  def status_badge_class(_), do: "badge"

  @doc """
  Returns the background color class for order cards based on status and payment state.

  This function provides subtle background colors for order cards to help
  cashiers and staff quickly identify order states at a glance. The ready
  status has special handling based on payment status.

  ## Parameters

  - `status` - The order status string
  - `paid` - Boolean indicating if the order has been paid (defaults to false)

  ## Special Cases

  - Ready + Paid: Green background (ready to complete)
  - Ready + Unpaid: Yellow background (awaiting payment)

  ## Examples

      iex> OrderStatusHelper.status_bg_class("ready", true)
      "bg-success/20 border border-success"

      iex> OrderStatusHelper.status_bg_class("ready", false)
      "bg-warning/20 border border-warning"

      iex> OrderStatusHelper.status_bg_class("pending")
      "bg-warning/10"
  """
  def status_bg_class(status, paid \\ false)
  def status_bg_class("ready", true), do: "bg-success/20 border border-success"
  def status_bg_class("ready", false), do: "bg-warning/20 border border-warning"
  def status_bg_class("pending", _), do: "bg-warning/10"
  def status_bg_class("preparing", _), do: "bg-info/10"
  def status_bg_class("completed", _), do: "bg-neutral/10"
  def status_bg_class("cancelled", _), do: "bg-error/10"
  def status_bg_class(_, _), do: "bg-base-100"

  @doc """
  Returns appropriate action button configuration for vendor based on current status.

  This function determines what action button should be displayed to vendors
  based on the current order status, following the defined workflow.

  ## Returns

  - `{button_text, next_status, button_class}` - Tuple with button configuration
  - `nil` - If no action is available for the current status

  ## Workflow

  - Pending → "Start Preparing" → Preparing
  - Preparing → "Ready for Pickup" → Ready
  - Ready/Completed/Cancelled → No further vendor actions

  ## Examples

      iex> OrderStatusHelper.vendor_action_button("pending")
      {"Start Preparing", "preparing", "btn-primary"}

      iex> OrderStatusHelper.vendor_action_button("preparing")
      {"Ready for Pickup", "ready", "btn-success"}

      iex> OrderStatusHelper.vendor_action_button("ready")
      nil
  """
  def vendor_action_button(status) do
    case status do
      "pending" -> {"Start Preparing", "preparing", "btn-primary"}
      "preparing" -> {"Ready for Pickup", "ready", "btn-success"}
      _ -> nil
    end
  end

  @doc """
  Checks if an order can be marked as paid based on its status.

  Only orders that are "ready" for pickup can be marked as paid.
  This ensures customers have their food ready before payment is processed.

  ## Business Rule

  Payment should only be accepted when the order is ready to prevent
  customers from paying for orders that might still take time to prepare.

  ## Examples

      iex> OrderStatusHelper.can_mark_as_paid?("ready")
      true

      iex> OrderStatusHelper.can_mark_as_paid?("preparing")
      false
  """
  def can_mark_as_paid?(status), do: status == "ready"

  @doc """
  Checks if an order can be marked as completed based on its status and payment state.

  An order can only be completed when it is both ready for pickup AND has been paid for.
  This ensures proper order lifecycle management.

  ## Parameters

  - `status` - The current order status
  - `paid` - Boolean indicating if the order has been paid

  ## Business Rule

  Completion indicates the customer has collected their order and payment
  has been processed. Both conditions must be met.

  ## Examples

      iex> OrderStatusHelper.can_complete?("ready", true)
      true

      iex> OrderStatusHelper.can_complete?("ready", false)
      false

      iex> OrderStatusHelper.can_complete?("preparing", true)
      false
  """
  def can_complete?(status, paid), do: status == "ready" && paid

  @doc """
  Returns abbreviated status text for compact displays.

  Use these short versions in space-constrained UI elements like
  mobile views or summary badges.

  ## Examples

      iex> OrderStatusHelper.status_short_text("preparing")
      "Prep"

      iex> OrderStatusHelper.status_short_text("completed")
      "Done"
  """
  def status_short_text("pending"), do: "Pending"
  def status_short_text("preparing"), do: "Prep"
  def status_short_text("ready"), do: "Ready"
  def status_short_text("completed"), do: "Done"
  def status_short_text("cancelled"), do: "Cancel"
  def status_short_text(_), do: "?"

  @doc """
  Returns icon SVG path for status visualization.

  These paths are designed to work with standard 24x24 SVG viewboxes
  and provide intuitive visual representations of each status.

  ## Icon Meanings

  - **Pending**: Clock icon (waiting for action)
  - **Preparing**: Plus/cooking icon (work in progress)
  - **Ready**: Checkmark in circle (complete and ready)
  - **Completed**: Simple checkmark (done)
  - **Cancelled**: X in circle (cancelled/stopped)
  - **Unknown**: Question mark in circle (error state)

  ## Usage Example

      <svg viewBox="0 0 24 24" class="w-6 h-6">
        <path d={OrderStatusHelper.status_icon_path(order.status)}
              fill="none" stroke="currentColor" stroke-width="2"/>
      </svg>
  """
  def status_icon_path("pending") do
    "M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
  end

  def status_icon_path("preparing") do
    "M12 6v6m0 0v6m0-6h6m-6 0H6"
  end

  def status_icon_path("ready") do
    "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
  end

  def status_icon_path("completed") do
    "M5 13l4 4L19 7"
  end

  def status_icon_path("cancelled") do
    "M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
  end

  def status_icon_path(_) do
    "M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
  end
end
