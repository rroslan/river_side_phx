defmodule RiverSideWeb.VendorLive.Dashboard do
  @moduledoc """
  LiveView module for the vendor dashboard interface.

  This module provides the main control panel for vendors to manage their
  food stall operations in the River Side Food Court. It offers real-time
  order management, menu control, and business analytics.

  ## Features

  ### Order Management
  * Real-time order notifications via PubSub
  * Order status updates (accept, prepare, complete, cancel)
  * Visual order queue with status indicators
  * Order history and filtering

  ### Menu Management
  * Add, edit, and remove menu items
  * Toggle item availability
  * Manage prices and descriptions
  * Upload and crop item images

  ### Business Operations
  * View daily sales statistics
  * Track order completion times
  * Monitor customer satisfaction
  * Manage vendor profile

  ## Real-time Updates

  The dashboard subscribes to vendor-specific PubSub topics for:
  * New incoming orders
  * Order status changes
  * Menu item updates
  * System notifications

  ## Order Lifecycle

  1. **Pending** - New order received, awaiting vendor action
  2. **Preparing** - Vendor accepted and is preparing the order
  3. **Ready** - Order prepared and ready for pickup
  4. **Completed** - Customer collected the order
  5. **Cancelled** - Order cancelled by vendor or customer

  ## Security

  * Requires vendor role for access
  * Vendors can only see/modify their own orders
  * All actions are scoped to the vendor's account
  """
  use RiverSideWeb, :live_view

  alias RiverSide.Vendors
  alias RiverSideWeb.Helpers.TimezoneHelper
  alias RiverSideWeb.Helpers.OrderStatusHelper

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200" id="vendor-dashboard" phx-hook="NotificationSound">
      <!-- Navigation -->
      <div class="navbar bg-base-300 shadow-lg">
        <div class="flex-1">
          <h1 class="text-2xl font-bold text-base-content px-4">
            {if @vendor, do: @vendor.name, else: "Vendor Dashboard"}
          </h1>
        </div>
        <div class="flex-none">
          <div class="dropdown dropdown-end ml-2">
            <label tabindex="0" class="btn btn-ghost btn-circle avatar">
              <div class="w-10 rounded-full bg-primary text-primary-content flex items-center justify-center">
                <span class="text-xl font-semibold">
                  {String.first(@current_scope.user.email) |> String.upcase()}
                </span>
              </div>
            </label>
            <ul
              tabindex="0"
              class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow-2xl bg-base-100 rounded-box w-52"
            >
              <li class="menu-title">
                <span>{@current_scope.user.email}</span>
              </li>
              <li>
                <div class="divider my-0"></div>
              </li>
              <li>
                <.link href={~p"/users/settings"} class="gap-3">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="w-4 h-4"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z"
                    />
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                    />
                  </svg>
                  Settings
                </.link>
              </li>
              <li>
                <div class="divider my-0"></div>
              </li>
              <li>
                <.link href={~p"/users/log-out"} method="delete" class="gap-3">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="w-4 h-4"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15m3 0l3-3m0 0l-3-3m3 3H9"
                    />
                  </svg>
                  Log out
                </.link>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <%= if @vendor do %>
        <div class="container mx-auto p-6">
          <!-- Flash Messages -->
          <%= if Phoenix.Flash.get(@flash, :error) do %>
            <div class="alert alert-error mb-4">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="stroke-current flex-shrink-0 h-6 w-6"
                fill="none"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              <span>{Phoenix.Flash.get(@flash, :error)}</span>
            </div>
          <% end %>

          <%= if Phoenix.Flash.get(@flash, :info) do %>
            <div class="alert alert-info mb-4">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="stroke-current flex-shrink-0 w-6 h-6"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              <span>{Phoenix.Flash.get(@flash, :info)}</span>
            </div>
          <% end %>
          
    <!-- Vendor Profile Card -->
          <div class="card bg-base-100 shadow-xl mb-6">
            <div class="card-body">
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-4">
                  <%= if @vendor.logo_url do %>
                    <img
                      src={@vendor.logo_url}
                      alt={@vendor.name}
                      class="w-20 h-20 rounded-lg object-cover"
                    />
                  <% else %>
                    <div class="w-20 h-20 rounded-lg bg-base-300 flex items-center justify-center">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke-width="1.5"
                        stroke="currentColor"
                        class="w-10 h-10 text-base-content/50"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 0 0 1.5-1.5V6a1.5 1.5 0 0 0-1.5-1.5H3.75A1.5 1.5 0 0 0 2.25 6v12a1.5 1.5 0 0 0 1.5 1.5Zm10.5-11.25h.008v.008h-.008V8.25Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z"
                        />
                      </svg>
                    </div>
                  <% end %>
                  <div>
                    <h2 class="text-2xl font-bold">{@vendor.name}</h2>
                    <%= if @vendor.description do %>
                      <p class="text-base-content/70">{@vendor.description}</p>
                    <% else %>
                      <p class="text-base-content/50">No description added</p>
                    <% end %>
                    <div class="mt-1">
                      <span class={
                        if @vendor.is_active, do: "badge badge-success", else: "badge badge-error"
                      }>
                        {if @vendor.is_active, do: "Active", else: "Inactive"}
                      </span>
                    </div>
                  </div>
                </div>
                <button class="btn btn-primary" phx-click="edit_profile">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="w-4 h-4"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l9.93-9.93Z"
                    />
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M19.5 7.125M18 13.875v4.5a1.875 1.875 0 0 1-1.875 1.875H5.625a1.875 1.875 0 0 1-1.875-1.875V8.625a1.875 1.875 0 0 1 1.875-1.875h4.5"
                    />
                  </svg>
                  Edit Profile
                </button>
              </div>

              <%= if !@vendor.logo_url || @vendor.name == "New Vendor" do %>
                <div class="alert alert-warning mt-4">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="stroke-current flex-shrink-0 h-6 w-6"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                    />
                  </svg>
                  <div>
                    <h3 class="font-bold">Complete Your Profile</h3>
                    <div class="text-xs">
                      Please update your vendor name and upload a logo to get started.
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
          
    <!-- Sales Stats -->
          <div class="stats shadow bg-base-100 w-full mb-6">
            <div class="stat">
              <div class="stat-figure text-success">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  class="inline-block w-8 h-8 stroke-current"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M2.25 18.75a60.07 60.07 0 0115.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 013 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 00-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 01-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 003 15h-.75M15 10.5a3 3 0 11-6 0 3 3 0 016 0zm3 0h.008v.008H18V10.5zm-12 0h.008v.008H6V10.5z"
                  />
                </svg>
              </div>
              <div class="stat-title">Today's Sales</div>
              <div class="stat-value">RM {format_currency(@sales_stats.today.total)}</div>
              <div class="stat-desc">{@sales_stats.today.count} orders</div>
            </div>

            <div class="stat">
              <div class="stat-figure text-primary">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  class="inline-block w-8 h-8 stroke-current"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5"
                  />
                </svg>
              </div>
              <div class="stat-title">This Month</div>
              <div class="stat-value">RM {format_currency(@sales_stats.month.total)}</div>
              <div class="stat-desc">{@sales_stats.month.count} orders</div>
            </div>

            <div class="stat">
              <div class="stat-figure text-warning">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  class="inline-block w-8 h-8 stroke-current"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
              </div>
              <div class="stat-title">Active Orders</div>
              <div class="stat-value">{length(@active_orders)}</div>
              <div class="stat-desc">Pending & Preparing</div>
            </div>
          </div>
          
    <!-- Tabs -->
          <div class="tabs tabs-boxed mb-6">
            <a
              class={"tab #{if @active_tab == "orders", do: "tab-active", else: ""}"}
              phx-click="set_tab"
              phx-value-tab="orders"
            >
              Active Orders
            </a>
            <a
              class={"tab #{if @active_tab == "menu", do: "tab-active", else: ""}"}
              phx-click="set_tab"
              phx-value-tab="menu"
            >
              Menu Items
            </a>
            <a
              class={"tab #{if @active_tab == "analytics", do: "tab-active", else: ""}"}
              phx-click="set_tab"
              phx-value-tab="analytics"
            >
              Analytics
            </a>
          </div>
          
    <!-- Content based on active tab -->
          <!-- Debug: Active tab = {@active_tab} -->
          <%= case @active_tab do %>
            <% "orders" -> %>
              <div class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
                <%= for order <- @active_orders do %>
                  <div class="card bg-base-100 shadow-xl">
                    <div class="card-body">
                      <div class="flex justify-between items-start">
                        <h2 class="card-title">Table {order.table_number}</h2>
                        <div class={OrderStatusHelper.status_badge_class(order.status)}>
                          {OrderStatusHelper.status_text(order.status)}
                        </div>
                      </div>
                      <p class="text-sm opacity-70">Order #{order.order_number}</p>
                      <div class="divider my-2"></div>
                      <div class="space-y-2">
                        <%= for item <- order.order_items do %>
                          <div class="flex justify-between items-center">
                            <div>
                              <span class="font-semibold">{item.quantity}x</span>
                              <span>{item.menu_item.name}</span>
                            </div>
                            <span class="text-sm">RM {format_currency(item.subtotal)}</span>
                          </div>
                          <%= if item.notes do %>
                            <p class="text-sm opacity-70 ml-6">Note: {item.notes}</p>
                          <% end %>
                        <% end %>
                      </div>
                      <div class="divider my-2"></div>
                      <div class="flex justify-between items-center font-bold">
                        <span>Total</span>
                        <span>RM {format_currency(order.total_amount)}</span>
                      </div>
                      <div class="card-actions justify-end mt-4">
                        <%= case order.status do %>
                          <% "pending" -> %>
                            <button
                              class="btn btn-primary btn-sm"
                              phx-click="update_order_status"
                              phx-value-id={order.id}
                              phx-value-status="preparing"
                            >
                              Start Preparing
                            </button>
                          <% "preparing" -> %>
                            <button
                              class="btn btn-success btn-sm"
                              phx-click="update_order_status"
                              phx-value-id={order.id}
                              phx-value-status="ready"
                            >
                              Ready for Pickup
                            </button>
                          <% "ready" -> %>
                            <span class="text-sm text-success">
                              {OrderStatusHelper.status_text(order.status)}
                            </span>
                        <% end %>
                        <button
                          class="btn btn-error btn-sm btn-outline"
                          phx-click="update_order_status"
                          phx-value-id={order.id}
                          phx-value-status="cancelled"
                          data-confirm="Are you sure you want to cancel this order?"
                        >
                          Cancel
                        </button>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
              <%= if Enum.empty?(@active_orders) do %>
                <div class="text-center py-12">
                  <p class="text-lg opacity-70">No active orders at the moment</p>
                </div>
              <% end %>
            <% "menu" -> %>
              <div class="card bg-base-100 shadow-xl">
                <div class="card-body">
                  <div class="flex justify-between items-center mb-4">
                    <h2 class="card-title">Menu Items</h2>
                    <button class="btn btn-primary" phx-click="new_menu_item">
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
                          d="M12 4.5v15m7.5-7.5h-15"
                        />
                      </svg>
                      Add Item
                    </button>
                  </div>
                  
    <!-- Food Items -->
                  <h3 class="text-lg font-semibold mt-4 mb-2">Food</h3>
                  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    <%= for item <- Enum.filter(@menu_items, & &1.category == "food") do %>
                      <div class="card card-compact bg-base-200">
                        <figure class="px-4 pt-4">
                          <%= if item.image_url do %>
                            <img
                              src={item.image_url}
                              alt={item.name}
                              class="rounded-xl h-48 w-48 mx-auto object-cover"
                            />
                          <% else %>
                            <div class="rounded-xl h-48 w-48 mx-auto bg-base-300 flex items-center justify-center">
                              <svg
                                xmlns="http://www.w3.org/2000/svg"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke-width="1.5"
                                stroke="currentColor"
                                class="w-12 h-12 opacity-50"
                              >
                                <path
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                  d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 0 0 1.5-1.5V6a1.5 1.5 0 0 0-1.5-1.5H3.75A1.5 1.5 0 0 0 2.25 6v12a1.5 1.5 0 0 0 1.5 1.5Zm10.5-11.25h.008v.008h-.008V8.25Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z"
                                />
                              </svg>
                            </div>
                          <% end %>
                        </figure>
                        <div class="card-body">
                          <h3 class="card-title text-base">{item.name}</h3>
                          <p class="text-sm opacity-70">{item.description}</p>
                          <div class="flex justify-between items-center mt-2">
                            <span class="text-lg font-bold">RM {format_currency(item.price)}</span>
                            <div class={"badge #{if item.is_available, do: "badge-success", else: "badge-error"}"}>
                              {if item.is_available, do: "Available", else: "Unavailable"}
                            </div>
                          </div>
                          <div class="card-actions justify-end mt-2">
                            <button
                              class="btn btn-ghost btn-xs"
                              phx-click="edit_menu_item"
                              phx-value-id={item.id}
                            >
                              Edit
                            </button>
                            <button
                              class="btn btn-ghost btn-xs"
                              phx-click="toggle_availability"
                              phx-value-id={item.id}
                            >
                              {if item.is_available, do: "Disable", else: "Enable"}
                            </button>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                  
    <!-- Drinks Items -->
                  <h3 class="text-lg font-semibold mt-8 mb-2">Drinks</h3>
                  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    <%= for item <- Enum.filter(@menu_items, & &1.category == "drinks") do %>
                      <div class="card card-compact bg-base-200">
                        <figure class="px-4 pt-4">
                          <%= if item.image_url do %>
                            <img
                              src={item.image_url}
                              alt={item.name}
                              class="rounded-xl h-48 w-48 mx-auto object-cover"
                            />
                          <% else %>
                            <div class="rounded-xl h-48 w-48 mx-auto bg-base-300 flex items-center justify-center">
                              <svg
                                xmlns="http://www.w3.org/2000/svg"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke-width="1.5"
                                stroke="currentColor"
                                class="w-12 h-12 opacity-50"
                              >
                                <path
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                  d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 0 0 1.5-1.5V6a1.5 1.5 0 0 0-1.5-1.5H3.75A1.5 1.5 0 0 0 2.25 6v12a1.5 1.5 0 0 0 1.5 1.5Zm10.5-11.25h.008v.008h-.008V8.25Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z"
                                />
                              </svg>
                            </div>
                          <% end %>
                        </figure>
                        <div class="card-body">
                          <h3 class="card-title text-base">{item.name}</h3>
                          <p class="text-sm opacity-70">{item.description}</p>
                          <div class="flex justify-between items-center mt-2">
                            <span class="text-lg font-bold">RM {format_currency(item.price)}</span>
                            <div class={"badge #{if item.is_available, do: "badge-success", else: "badge-error"}"}>
                              {if item.is_available, do: "Available", else: "Unavailable"}
                            </div>
                          </div>
                          <div class="card-actions justify-end mt-2">
                            <button
                              class="btn btn-ghost btn-xs"
                              phx-click="edit_menu_item"
                              phx-value-id={item.id}
                            >
                              Edit
                            </button>
                            <button
                              class="btn btn-ghost btn-xs"
                              phx-click="toggle_availability"
                              phx-value-id={item.id}
                            >
                              {if item.is_available, do: "Disable", else: "Enable"}
                            </button>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            <% "analytics" -> %>
              <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <!-- Top Selling Items -->
                <div class="card bg-base-100 shadow-xl">
                  <div class="card-body">
                    <h2 class="card-title mb-4">Top Selling Items Today</h2>
                    <div class="overflow-x-auto">
                      <table class="table table-zebra">
                        <thead>
                          <tr>
                            <th>Item</th>
                            <th>Quantity</th>
                            <th>Revenue</th>
                          </tr>
                        </thead>
                        <tbody>
                          <%= for item <- @sales_stats.top_items do %>
                            <tr>
                              <td>{item.name}</td>
                              <td>{item.quantity}</td>
                              <td>RM {format_currency(item.revenue)}</td>
                            </tr>
                          <% end %>
                        </tbody>
                      </table>
                    </div>
                    <%= if Enum.empty?(@sales_stats.top_items) do %>
                      <p class="text-center py-4 opacity-70">No sales data for today yet</p>
                    <% end %>
                  </div>
                </div>
                
    <!-- Recent Orders -->
                <div class="card bg-base-100 shadow-xl">
                  <div class="card-body">
                    <h2 class="card-title mb-4">Recent Completed Orders</h2>
                    <div class="space-y-2">
                      <%= for order <- Enum.take(@completed_orders, 5) do %>
                        <div class="flex justify-between items-center p-3 bg-base-200 rounded-lg">
                          <div>
                            <p class="font-semibold">Table {order.table_number}</p>
                            <p class="text-sm opacity-70">
                              {TimezoneHelper.format_malaysian_time_only(order.updated_at)}
                            </p>
                          </div>
                          <span class="text-lg font-bold">
                            RM {format_currency(order.total_amount)}
                          </span>
                        </div>
                      <% end %>
                    </div>
                    <%= if Enum.empty?(@completed_orders) do %>
                      <p class="text-center py-4 opacity-70">No completed orders today</p>
                    <% end %>
                  </div>
                </div>
              </div>
            <% _ -> %>
              <!-- Default to orders tab if active_tab has unexpected value -->
              <div class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
                <%= for order <- @active_orders do %>
                  <div class="card bg-base-100 shadow-xl">
                    <div class="card-body">
                      <div class="flex justify-between items-start">
                        <h2 class="card-title">Table {order.table_number}</h2>
                        <div class={OrderStatusHelper.status_badge_class(order.status)}>
                          {OrderStatusHelper.status_text(order.status)}
                        </div>
                      </div>
                      <p class="text-sm opacity-70">Order #{order.order_number}</p>
                      <div class="divider my-2"></div>
                      <div class="space-y-2">
                        <%= for item <- order.order_items do %>
                          <div class="flex justify-between items-center">
                            <div>
                              <span class="font-semibold">{item.quantity}x</span>
                              <span>{item.menu_item.name}</span>
                            </div>
                            <span class="text-sm">RM {format_currency(item.subtotal)}</span>
                          </div>
                          <%= if item.notes do %>
                            <p class="text-sm opacity-70 ml-6">Note: {item.notes}</p>
                          <% end %>
                        <% end %>
                      </div>
                      <div class="divider my-2"></div>
                      <div class="flex justify-between items-center font-bold">
                        <span>Total</span>
                        <span>RM {format_currency(order.total_amount)}</span>
                      </div>
                      <div class="card-actions justify-end mt-4">
                        <%= case order.status do %>
                          <% "pending" -> %>
                            <button
                              class="btn btn-primary btn-sm"
                              phx-click="update_order_status"
                              phx-value-id={order.id}
                              phx-value-status="preparing"
                            >
                              Start Preparing
                            </button>
                          <% "preparing" -> %>
                            <button
                              class="btn btn-success btn-sm"
                              phx-click="update_order_status"
                              phx-value-id={order.id}
                              phx-value-status="ready"
                            >
                              Ready for Pickup
                            </button>
                          <% "ready" -> %>
                            <span class="text-sm text-success">
                              {OrderStatusHelper.status_text(order.status)}
                            </span>
                        <% end %>
                        <button
                          class="btn btn-error btn-sm btn-outline"
                          phx-click="update_order_status"
                          phx-value-id={order.id}
                          phx-value-status="cancelled"
                          data-confirm="Are you sure you want to cancel this order?"
                        >
                          Cancel
                        </button>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
              <%= if Enum.empty?(@active_orders) do %>
                <div class="text-center py-12">
                  <p class="text-lg opacity-70">No active orders at the moment</p>
                </div>
              <% end %>
          <% end %>
        </div>
      <% else %>
        <!-- No vendor profile -->
        <div class="container mx-auto p-6">
          <div class="alert alert-error shadow-lg">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="stroke-current flex-shrink-0 h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <span>No vendor profile found. Please contact an administrator.</span>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # Vendor is already loaded in scope!
    vendor = socket.assigns.current_scope.vendor

    if vendor do
      # Subscribe to real-time updates
      Vendors.subscribe_to_vendor_orders(vendor.id)

      require Logger
      Logger.info("Vendor Dashboard: Subscribed to vendor_orders:#{vendor.id}")

      # Load initial data
      menu_items = Vendors.list_menu_items(vendor.id)
      active_orders = Vendors.list_active_orders(vendor.id)

      completed_orders =
        Vendors.list_todays_orders(vendor.id) |> Enum.filter(&(&1.status == "completed"))

      sales_stats = Vendors.get_vendor_sales_stats(vendor.id)

      {:ok,
       socket
       |> assign(vendor: vendor)
       |> assign(menu_items: menu_items)
       |> assign(active_orders: active_orders)
       |> assign(completed_orders: completed_orders)
       |> assign(sales_stats: sales_stats)
       |> assign(active_tab: "orders")}
    else
      # Create a default vendor profile
      case Vendors.create_vendor(%{
             name: "New Vendor",
             user_id: socket.assigns.current_scope.user.id,
             active: true
           }) do
        {:ok, vendor} ->
          {:ok,
           socket
           |> assign(vendor: vendor)
           |> assign(menu_items: [])
           |> assign(active_orders: [])
           |> assign(completed_orders: [])
           |> assign(sales_stats: %{total_sales: 0, total_orders: 0})
           |> assign(active_tab: "orders")
           |> put_flash(:info, "Welcome! Please complete your vendor profile.")
           |> assign(
             sales_stats: %{
               today: %{count: 0, total: Decimal.new("0")},
               month: %{count: 0, total: Decimal.new("0")},
               top_items: []
             }
           )
           |> assign(active_tab: "orders")}

        {:error, _} ->
          {:ok,
           socket
           |> assign(vendor: nil)
           |> assign(menu_items: [])
           |> assign(active_orders: [])
           |> assign(completed_orders: [])
           |> assign(
             sales_stats: %{
               today: %{count: 0, total: Decimal.new("0")},
               month: %{count: 0, total: Decimal.new("0")},
               top_items: []
             }
           )
           |> assign(active_tab: "orders")}
      end
    end
  end

  @impl true
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    # Load menu items when switching to menu tab
    socket =
      if tab == "menu" and not Map.has_key?(socket.assigns, :menu_items) do
        menu_items = Vendors.list_menu_items(socket.assigns.vendor.id)
        assign(socket, menu_items: menu_items)
      else
        socket
      end

    {:noreply, assign(socket, active_tab: tab)}
  end

  @impl true
  def handle_event("update_order_status", %{"id" => id, "status" => status}, socket) do
    order = Vendors.get_order!(id)

    # Use scope for authorization
    if RiverSide.Accounts.Scope.can?(socket.assigns.current_scope, :update_status, order) do
      case Vendors.update_order_status(order, %{status: status}) do
        {:ok, _order} ->
          # Refresh data
          active_orders = Vendors.list_active_orders(socket.assigns.vendor.id)

          completed_orders =
            Vendors.list_todays_orders(socket.assigns.vendor.id)
            |> Enum.filter(&(&1.status == "completed"))

          sales_stats = Vendors.get_vendor_sales_stats(socket.assigns.vendor.id)

          {:noreply,
           socket
           |> assign(active_orders: active_orders)
           |> assign(completed_orders: completed_orders)
           |> assign(sales_stats: sales_stats)
           |> put_flash(:info, "Order status updated successfully")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to update order status")}
      end
    else
      {:noreply, put_flash(socket, :error, "You don't have permission to update this order")}
    end
  end

  @impl true
  def handle_event("toggle_availability", %{"id" => id}, socket) do
    menu_item = Vendors.get_menu_item!(id)

    # Check authorization using scope
    if RiverSide.Accounts.Scope.can?(socket.assigns.current_scope, :update, menu_item) do
      case Vendors.toggle_menu_item_availability(menu_item) do
        {:ok, updated_item} ->
          # Reload all menu items to ensure consistency
          menu_items = Vendors.list_menu_items(socket.assigns.vendor.id)

          {:noreply,
           socket
           |> assign(menu_items: menu_items)
           |> put_flash(
             :info,
             "#{updated_item.name} is now #{if updated_item.is_available, do: "available", else: "unavailable"}"
           )}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to update item")}
      end
    else
      {:noreply, put_flash(socket, :error, "You don't have permission to update this item")}
    end
  end

  @impl true
  def handle_event("new_menu_item", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/vendor/menu/new")}
  end

  @impl true
  def handle_event("edit_menu_item", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/vendor/menu/#{id}/edit")}
  end

  @impl true
  def handle_event("edit_profile", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/vendor/profile/edit")}
  end

  @impl true
  def handle_info({:order_updated, order}, socket) do
    # Log the incoming order update
    require Logger

    Logger.info(
      "Vendor Dashboard: Received order update for order ##{order.id}, vendor_id: #{order.vendor_id}, my vendor_id: #{socket.assigns.vendor.id}"
    )

    # Update orders in real-time
    active_orders = Vendors.list_active_orders(socket.assigns.vendor.id)

    completed_orders =
      Vendors.list_todays_orders(socket.assigns.vendor.id)
      |> Enum.filter(&(&1.status == "completed"))

    sales_stats = Vendors.get_vendor_sales_stats(socket.assigns.vendor.id)

    # Check if this is a new order (status is pending and it's for our vendor)
    {flash_socket, should_play_sound} =
      if order.status == "pending" && order.vendor_id == socket.assigns.vendor.id do
        {put_flash(socket, :info, "New order received! Table #{order.table_number}"), true}
      else
        {socket, false}
      end

    # Push event to play sound if it's a new order
    final_socket =
      if should_play_sound do
        push_event(flash_socket, "play-notification-sound", %{})
      else
        flash_socket
      end

    {:noreply,
     final_socket
     |> assign(active_orders: active_orders)
     |> assign(completed_orders: completed_orders)
     |> assign(sales_stats: sales_stats)}
  end

  defp format_currency(decimal) do
    string_value = Decimal.to_string(decimal, :normal)

    # Add .0 if there's no decimal point
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
end
