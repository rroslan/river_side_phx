defmodule RiverSideWeb.CustomerLive.OrderTracking do
  @moduledoc """
  LiveView module for customer order tracking interface.

  This module provides real-time order status tracking for customers after
  they've placed orders. It shows all active orders and their current status,
  allowing customers to know when to pay and collect their food.

  ## Features

  ### Order Status Tracking
  * Real-time status updates via PubSub
  * Visual status indicators and progress
  * Estimated completion times
  * Order details and vendor information

  ### Multi-Order Support
  * Track orders from multiple vendors
  * Consolidated view of all active orders
  * Individual order status per vendor
  * Total amount for all orders

  ## Order Status Flow

  1. **Pending** - Order submitted, awaiting vendor
  2. **Preparing** - Vendor accepted and preparing
  3. **Ready** - Food ready, proceed to payment
  4. **Paid** - Payment complete, collect food
  5. **Completed** - Order fulfilled
  6. **Cancelled** - Order cancelled

  ## Real-time Updates

  Subscribes to customer-specific PubSub topics:
  * Order status changes
  * Preparation time updates
  * Cancellation notifications
  * Payment confirmations

  ## User Actions

  * View order details
  * Navigate to new order
  * Return to menu
  * Check out when done
  """
  use RiverSideWeb, :live_view

  alias RiverSide.Vendors
  alias RiverSideWeb.Helpers.OrderStatusHelper

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="navbar bg-base-300 shadow-lg">
        <div class="flex-1">
          <h1 class="text-2xl font-bold text-base-content px-4">Order Tracking</h1>
        </div>
        <div class="flex-none">
          <.link href={~p"/customer/menu"} class="btn btn-primary btn-sm">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              class="w-5 h-5"
            >
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
            New Order
          </.link>
        </div>
      </div>

      <div class="container mx-auto p-4 max-w-4xl">
        <!-- Customer Info -->
        <div class="card bg-base-100 shadow-xl mb-6">
          <div class="card-body">
            <div class="flex justify-between items-center">
              <div>
                <h2 class="text-xl font-bold">Table #{@customer_info.table_number}</h2>
                <p class="text-base-content/70">{@customer_info.phone}</p>
              </div>
              <.link href={~p"/"} class="btn btn-error btn-sm">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="w-5 h-5"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15M12 9l-3 3m0 0l3 3m-3-3h12.75"
                  />
                </svg>
                End Session
              </.link>
            </div>
            
    <!-- Vendor Summary -->
            <% all_orders = @active_orders %>
            <%= if length(all_orders) > 0 do %>
              <div class="divider"></div>
              <div>
                <h3 class="text-sm font-bold mb-2">Your Orders By Vendor:</h3>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-2">
                  <%= for {vendor_name, vendor_orders} <- Enum.group_by(all_orders, & &1.vendor.name) do %>
                    <div class="bg-base-200 rounded-lg p-3">
                      <div class="font-semibold">{vendor_name}</div>
                      <div class="text-sm text-base-content/70">
                        {length(vendor_orders)} order(s) •
                        RM {vendor_orders
                        |> Enum.map(& &1.total_amount)
                        |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)
                        |> format_currency()}
                      </div>
                      <div class="flex gap-1 mt-1">
                        <%= for order <- vendor_orders do %>
                          <span class={OrderStatusHelper.status_badge_class(order.status) <> " badge-xs"}>
                            {OrderStatusHelper.status_text(order.status)}
                          </span>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- Vendor Filter -->
        <% all_vendors =
          @active_orders |> Enum.map(& &1.vendor.name) |> Enum.uniq() %>
        <%= if length(all_vendors) > 1 do %>
          <div class="flex gap-2 mb-4 overflow-x-auto">
            <button
              class={"btn btn-sm #{if @selected_vendor == nil, do: "btn-primary", else: "btn-ghost"}"}
              phx-click="filter_vendor"
              phx-value-vendor=""
            >
              All Vendors
            </button>
            <%= for vendor_name <- all_vendors do %>
              <button
                class={"btn btn-sm #{if @selected_vendor == vendor_name, do: "btn-primary", else: "btn-ghost"}"}
                phx-click="filter_vendor"
                phx-value-vendor={vendor_name}
              >
                {vendor_name}
              </button>
            <% end %>
          </div>
        <% end %>
        
    <!-- Active Orders -->
        <% filtered_active = filter_orders_by_vendor(@active_orders, @selected_vendor) %>
        <%= if filtered_active != [] do %>
          <h3 class="text-xl font-bold mb-4">Active Orders</h3>
          <div class="space-y-4 mb-8">
            <%= for order <- filtered_active do %>
              <div class="card bg-base-100 shadow-xl">
                <div class="card-body">
                  <div class="flex justify-between items-start mb-4">
                    <div>
                      <h4 class="text-lg font-bold">{order.vendor.name}</h4>
                      <p class="text-sm text-base-content/70">Order #{order.order_number}</p>
                      <% food_items =
                        Enum.filter(order.order_items, &(&1.menu_item.category == "food")) %>
                      <% drink_items =
                        Enum.filter(order.order_items, &(&1.menu_item.category == "drinks")) %>
                      <div class="flex gap-2 mt-1">
                        <%= if length(food_items) > 0 do %>
                          <span class="badge badge-sm badge-neutral">
                            {length(food_items)} Food
                          </span>
                        <% end %>
                        <%= if length(drink_items) > 0 do %>
                          <span class="badge badge-sm badge-info">
                            {length(drink_items)} Drinks
                          </span>
                        <% end %>
                      </div>
                    </div>
                    <span class={OrderStatusHelper.status_badge_class(order.status) <> " badge-lg"}>
                      {OrderStatusHelper.status_text(order.status)}
                    </span>
                  </div>
                  
    <!-- Order Items -->
                  <div class="space-y-2">
                    <%= for item <- order.order_items do %>
                      <div class="flex justify-between text-sm">
                        <span>{item.quantity}× {item.menu_item.name}</span>
                        <span>RM {format_currency(item.subtotal)}</span>
                      </div>
                    <% end %>
                  </div>

                  <div class="divider"></div>

                  <div class="flex justify-between items-center">
                    <span class="font-bold">Total</span>
                    <span class="text-lg font-bold">RM {format_currency(order.total_amount)}</span>
                  </div>

                  <%= if order.status == "ready" do %>
                    <div class="alert alert-success mt-4">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke-width="1.5"
                        stroke="currentColor"
                        class="w-6 h-6"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          d="M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0"
                        />
                      </svg>
                      <span>Your order is ready for collection!</span>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>

        <%= if @active_orders == [] do %>
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body text-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-24 h-24 mx-auto text-base-content/30"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 002.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 00-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25zM6.75 12h.008v.008H6.75V12zm0 3h.008v.008H6.75V15zm0 3h.008v.008H6.75V18z"
                />
              </svg>
              <h2 class="text-2xl font-bold mt-4">No orders yet</h2>
              <p class="text-base-content/70 mt-2">Start by browsing our delicious menu!</p>
              <.link href={~p"/customer/menu"} class="btn btn-primary mt-6">
                Browse Menu
              </.link>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    phone = params["phone"]
    table_number = params["table"]
    order_ids_param = params["order_ids"]

    if phone && table_number do
      customer_info = %{
        phone: phone,
        table_number: String.to_integer(table_number)
      }

      # Get order IDs from URL parameters
      order_ids =
        if order_ids_param && order_ids_param != "" do
          String.split(order_ids_param, ",") |> Enum.map(&String.to_integer/1)
        else
          []
        end

      orders =
        if order_ids != [] do
          # Get specific orders that were just created
          Enum.map(order_ids, &Vendors.get_order!/1)
        else
          # Get all orders for this customer in this session
          Vendors.list_customer_orders(
            customer_info.phone,
            customer_info.table_number
          )
        end

      # Subscribe to order updates
      Enum.each(orders, fn order ->
        Vendors.subscribe_to_order_updates(order.id)
      end)

      # Only show active orders to customers (not completed ones)
      active_orders =
        Enum.filter(orders, fn order ->
          order.status in ["pending", "preparing", "ready"]
        end)

      {:ok,
       socket
       |> assign(customer_info: customer_info)
       |> assign(active_orders: active_orders)
       |> assign(completed_orders: [])
       |> assign(selected_vendor: nil)}
    else
      {:ok, push_navigate(socket, to: ~p"/")}
    end
  end

  @impl true
  def handle_event("filter_vendor", %{"vendor" => vendor}, socket) do
    selected = if vendor == "", do: nil, else: vendor
    {:noreply, assign(socket, selected_vendor: selected)}
  end

  @impl true
  def handle_info({:order_updated, updated_order}, socket) do
    # Update the specific order in our lists
    active_orders =
      Enum.map(socket.assigns.active_orders, fn order ->
        if order.id == updated_order.id, do: updated_order, else: order
      end)

    # Keep only pending, preparing, and ready orders in active list for customers
    new_active =
      Enum.filter(active_orders, fn order ->
        order.status in ["pending", "preparing", "ready"]
      end)

    {:noreply,
     socket
     |> assign(active_orders: new_active)
     |> assign(completed_orders: [])}
  end

  defp format_currency(decimal) do
    string_value = Decimal.to_string(decimal, :normal)

    float_string =
      if String.contains?(string_value, ".") do
        string_value
      else
        string_value <> ".0"
      end

    float_string
    |> String.to_float()
    |> :erlang.float_to_binary(decimals: 2)
  end

  defp filter_orders_by_vendor(orders, nil), do: orders

  defp filter_orders_by_vendor(orders, vendor_name) do
    Enum.filter(orders, &(&1.vendor.name == vendor_name))
  end
end
