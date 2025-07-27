defmodule RiverSideWeb.Helpers.OrderStatusHelper do
  @moduledoc """
  Centralized helper for order status display and styling.
  Ensures consistency across vendor, customer, and cashier views.
  """

  @doc """
  Returns the display text for a given order status.
  """
  def status_text("pending"), do: "Pending"
  def status_text("preparing"), do: "Preparing"
  def status_text("ready"), do: "Ready for Pickup"
  def status_text("completed"), do: "Completed"
  def status_text("cancelled"), do: "Cancelled"
  def status_text(_), do: "Unknown"

  @doc """
  Returns the badge CSS class for a given order status.
  """
  def status_badge_class("pending"), do: "badge badge-warning"
  def status_badge_class("preparing"), do: "badge badge-info"
  def status_badge_class("ready"), do: "badge badge-success"
  def status_badge_class("completed"), do: "badge badge-neutral"
  def status_badge_class("cancelled"), do: "badge badge-error"
  def status_badge_class(_), do: "badge"

  @doc """
  Returns the background color class for order cards based on status.
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
  Returns appropriate action button for vendor based on current status.
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
  """
  def can_mark_as_paid?(status), do: status == "ready"

  @doc """
  Checks if an order can be completed based on its status and payment.
  """
  def can_complete?(status, paid), do: status == "ready" && paid

  @doc """
  Returns a short status text for compact displays.
  """
  def status_short_text("pending"), do: "Pending"
  def status_short_text("preparing"), do: "Prep"
  def status_short_text("ready"), do: "Ready"
  def status_short_text("completed"), do: "Done"
  def status_short_text("cancelled"), do: "Cancel"
  def status_short_text(_), do: "?"

  @doc """
  Returns icon SVG path for status visualization.
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
