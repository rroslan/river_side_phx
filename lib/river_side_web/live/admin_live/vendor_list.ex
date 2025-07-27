defmodule RiverSideWeb.AdminLive.VendorList do
  use RiverSideWeb, :live_view

  alias RiverSide.Vendors
  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <!-- Delete Confirmation Modal -->
      <%= if @show_delete_modal do %>
        <div class="modal modal-open">
          <div class="modal-box w-11/12 max-w-md">
            <h3 class="font-bold text-lg">Confirm Vendor Deletion</h3>

            <%= if @delete_impact do %>
              <div class="py-4 space-y-4">
                <p class="text-sm sm:text-base">
                  Are you sure you want to delete <strong class="break-all">{@delete_impact.vendor_name}</strong>?
                </p>

                <div class="alert alert-warning mb-4">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="stroke-current shrink-0 h-6 w-6"
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
                  <span>This action cannot be undone!</span>
                </div>

                <div class="stats stats-vertical sm:stats-horizontal shadow w-full">
                  <div class="stat">
                    <div class="stat-title text-xs sm:text-sm">Menu Items</div>
                    <div class="stat-value text-base sm:text-lg">{@delete_impact.menu_items}</div>
                  </div>
                  <div class="stat">
                    <div class="stat-title text-xs sm:text-sm">Total Orders</div>
                    <div class="stat-value text-base sm:text-lg">{@delete_impact.orders.total}</div>
                    <%= if @delete_impact.orders.active > 0 do %>
                      <div class="stat-desc text-error text-xs">
                        {@delete_impact.orders.active} active orders!
                      </div>
                    <% end %>
                  </div>
                  <div class="stat">
                    <div class="stat-title text-xs sm:text-sm">Order Items</div>
                    <div class="stat-value text-base sm:text-lg">{@delete_impact.order_items}</div>
                  </div>
                </div>

                <div class="mt-4">
                  <p class="text-xs sm:text-sm">
                    User account: <strong class="break-all">{@delete_impact.user_email}</strong>
                    <%= if @delete_impact.user_will_be_deleted do %>
                      <span class="text-error">(will be deleted)</span>
                    <% else %>
                      <span class="text-success">(will be kept - has other roles)</span>
                    <% end %>
                  </p>
                </div>
              </div>
            <% end %>

            <div class="modal-action">
              <button type="button" class="btn" phx-click="cancel_delete">Cancel</button>
              <button
                type="button"
                class="btn btn-error"
                phx-click="confirm_delete"
                phx-value-id={@delete_vendor_id}
              >
                Delete Vendor
              </button>
            </div>
          </div>
        </div>
      <% end %>
      
    <!-- Header -->
      <div class="navbar bg-base-100 shadow-lg">
        <div class="flex-1">
          <a href="/admin/dashboard" class="btn btn-ghost normal-case text-xl">
            River Side Admin
          </a>
          <div class="breadcrumbs text-xs sm:text-sm ml-2 sm:ml-4">
            <ul>
              <li><a href="/admin/dashboard">Dashboard</a></li>
              <li>Vendor Management</li>
            </ul>
          </div>
        </div>
        <div class="flex-none">
          <span class="hidden sm:inline text-sm mr-4">Admin: {@current_scope.user.email}</span>
          <a href="/admin/dashboard" class="btn btn-xs sm:btn-sm btn-ghost">
            <span class="hidden sm:inline">Back to Dashboard</span>
            <span class="sm:hidden">Back</span>
          </a>
        </div>
      </div>
      
    <!-- Main Content -->
      <div class="container mx-auto px-2 sm:px-4 py-4 sm:py-8">
        <!-- Stats -->
        <div class="stats stats-vertical sm:stats-horizontal shadow w-full mb-4 sm:mb-8">
          <div class="stat p-4 sm:p-6">
            <div class="stat-figure text-primary hidden sm:block">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-8 h-8"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M13.5 21v-7.5a.75.75 0 01.75-.75h3a.75.75 0 01.75.75V21m-4.5 0H2.36m11.14 0H18m0 0h3.64m-1.39 0V9.349m-16.5 11.65V9.35m0 0a3.001 3.001 0 003.75-.615A2.993 2.993 0 009.75 9.75c.896 0 1.7-.393 2.25-1.016a2.993 2.993 0 002.25 1.016c.896 0 1.7-.393 2.25-1.016a3.001 3.001 0 003.75.614m-16.5 0a3.004 3.004 0 01-.621-4.72L4.318 3.44A1.5 1.5 0 015.378 3h13.243a1.5 1.5 0 011.06.44l1.19 1.189a3 3 0 01-.621 4.72m-13.5 8.65h3.75a.75.75 0 00.75-.75V13.5a.75.75 0 00-.75-.75H6.75a.75.75 0 00-.75.75v3.75c0 .415.336.75.75.75z"
                />
              </svg>
            </div>
            <div class="stat-title text-xs sm:text-sm">Total Vendors</div>
            <div class="stat-value text-xl sm:text-3xl">{length(@vendors)}</div>
            <div class="stat-desc text-xs">Registered vendor accounts</div>
          </div>

          <div class="stat p-4 sm:p-6">
            <div class="stat-figure text-success hidden sm:block">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-8 h-8"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <div class="stat-title text-xs sm:text-sm">Active Vendors</div>
            <div class="stat-value text-xl sm:text-3xl">{Enum.count(@vendors, & &1.is_active)}</div>
            <div class="stat-desc text-xs">Currently operating</div>
          </div>

          <div class="stat p-4 sm:p-6">
            <div class="stat-figure text-warning hidden sm:block">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-8 h-8"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z"
                />
              </svg>
            </div>
            <div class="stat-title text-xs sm:text-sm">Inactive Vendors</div>
            <div class="stat-value text-xl sm:text-3xl">
              {Enum.count(@vendors, &(not &1.is_active))}
            </div>
            <div class="stat-desc text-xs">Currently inactive</div>
          </div>

          <div class="stat p-4 sm:p-6">
            <div class="stat-figure text-info hidden sm:block">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                class="w-8 h-8"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M20.25 6.375c0 2.278-3.694 4.125-8.25 4.125S3.75 8.653 3.75 6.375m16.5 0c0-2.278-3.694-4.125-8.25-4.125S3.75 4.097 3.75 6.375m16.5 0v11.25c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125V6.375m16.5 0v3.75m-16.5-3.75v3.75m16.5 0v3.75C20.25 16.153 16.556 18 12 18s-8.25-1.847-8.25-4.125v-3.75m16.5 0c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125"
                />
              </svg>
            </div>
            <div class="stat-title text-xs sm:text-sm">Total Menu Items</div>
            <div class="stat-value text-xl sm:text-3xl">{@total_menu_items}</div>
            <div class="stat-desc text-xs">Across all vendors</div>
          </div>
        </div>
        
    <!-- Vendor List -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body p-4 sm:p-6">
            <div class="flex justify-between items-center mb-4">
              <h2 class="card-title text-lg sm:text-xl">Vendor Details</h2>
              <button class="btn btn-ghost btn-xs sm:btn-sm" phx-click="refresh">
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
                    d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182m0-4.991v4.99"
                  />
                </svg>
                Refresh
              </button>
            </div>

            <div class="overflow-x-auto -mx-4 sm:mx-0">
              <table class="table table-zebra table-xs sm:table-sm">
                <thead>
                  <tr>
                    <th>Vendor</th>
                    <th class="hidden sm:table-cell">Owner</th>
                    <th>Status</th>
                    <th class="hidden lg:table-cell">Items</th>
                    <th class="hidden lg:table-cell">Orders</th>
                    <th class="hidden md:table-cell">Created</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for vendor <- @vendors do %>
                    <tr>
                      <td>
                        <div class="flex items-center gap-2 sm:gap-3">
                          <div class="avatar hidden sm:block">
                            <div class="mask mask-squircle w-8 h-8 sm:w-12 sm:h-12 bg-primary text-primary-content">
                              <span class="text-sm sm:text-xl font-semibold">
                                {String.first(vendor.name) |> String.upcase()}
                              </span>
                            </div>
                          </div>
                          <div>
                            <div class="font-bold text-xs sm:text-sm">{vendor.name}</div>
                            <%= if vendor.description do %>
                              <div class="text-xs opacity-50 hidden sm:block">
                                {String.slice(vendor.description, 0, 30)}{if String.length(
                                                                               vendor.description
                                                                             ) > 30,
                                                                             do: "..."}
                              </div>
                            <% end %>
                          </div>
                        </div>
                      </td>
                      <td class="hidden sm:table-cell">
                        <%= if vendor.user do %>
                          <div>
                            <div class="text-xs sm:text-sm truncate max-w-[150px]">
                              {vendor.user.email}
                            </div>
                            <div class="text-xs opacity-50">ID: {vendor.user_id}</div>
                          </div>
                        <% else %>
                          <span class="text-error text-xs">No user linked</span>
                        <% end %>
                      </td>
                      <td>
                        <%= if vendor.is_active do %>
                          <span class="badge badge-success badge-xs sm:badge-sm">Active</span>
                        <% else %>
                          <span class="badge badge-error badge-xs sm:badge-sm">Inactive</span>
                        <% end %>
                      </td>
                      <td class="hidden lg:table-cell">
                        <span class="badge badge-ghost badge-xs sm:badge-sm">
                          {Map.get(@vendor_menu_counts, vendor.id, 0)}
                        </span>
                      </td>
                      <td class="hidden lg:table-cell">
                        <span class="badge badge-ghost badge-xs sm:badge-sm">
                          {Map.get(@vendor_order_counts, vendor.id, 0)}
                        </span>
                      </td>
                      <td class="hidden md:table-cell">
                        <div class="text-xs sm:text-sm">
                          {Calendar.strftime(vendor.inserted_at, "%b %d, %Y")}
                        </div>
                        <div class="text-xs opacity-50 hidden lg:block">
                          {Calendar.strftime(vendor.inserted_at, "%I:%M %p")}
                        </div>
                      </td>
                      <td>
                        <div class="flex gap-1 sm:gap-2">
                          <button
                            class="btn btn-ghost btn-xs"
                            phx-click="toggle_vendor_status"
                            phx-value-id={vendor.id}
                            phx-value-active={vendor.is_active}
                          >
                            <span class="hidden sm:inline">
                              <%= if vendor.is_active do %>
                                Deactivate
                              <% else %>
                                Activate
                              <% end %>
                            </span>
                            <span class="sm:hidden">
                              <%= if vendor.is_active do %>
                                Off
                              <% else %>
                                On
                              <% end %>
                            </span>
                          </button>
                          <button
                            class="btn btn-ghost btn-xs hidden sm:inline-flex"
                            phx-click="view_vendor"
                            phx-value-id={vendor.id}
                          >
                            View
                          </button>
                          <button
                            class="btn btn-ghost btn-xs text-error"
                            phx-click="delete_vendor"
                            phx-value-id={vendor.id}
                          >
                            <span class="hidden sm:inline">Delete</span>
                            <svg
                              xmlns="http://www.w3.org/2000/svg"
                              fill="none"
                              viewBox="0 0 24 24"
                              stroke-width="1.5"
                              stroke="currentColor"
                              class="w-3 h-3 sm:hidden"
                            >
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0"
                              />
                            </svg>
                          </button>
                        </div>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <%= if @vendors == [] do %>
              <div class="text-center py-8">
                <p class="text-sm sm:text-base text-base-content/60">No vendors found</p>
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- Issues Section -->
        <%= if @vendor_issues != [] do %>
          <div class="card bg-warning/20 shadow-xl mt-4 sm:mt-8">
            <div class="card-body p-4 sm:p-6">
              <h2 class="card-title text-warning text-lg sm:text-xl">Vendor Issues</h2>
              <ul class="list-disc list-inside">
                <%= for issue <- @vendor_issues do %>
                  <li class="text-xs sm:text-sm">{issue}</li>
                <% end %>
              </ul>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_scope.user.is_admin do
      {:ok,
       socket
       |> load_vendor_data()
       |> assign(show_delete_modal: false)
       |> assign(delete_vendor_id: nil)
       |> assign(delete_impact: nil)}
    else
      {:ok,
       socket
       |> put_flash(:error, "You are not authorized to access this page")
       |> push_navigate(to: ~p"/admin/dashboard")}
    end
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    {:noreply,
     socket
     |> load_vendor_data()
     |> put_flash(:info, "Vendor list refreshed")}
  end

  @impl true
  def handle_event("toggle_vendor_status", %{"id" => id, "active" => active}, socket) do
    vendor_id = String.to_integer(id)
    is_active = active == "true"

    vendor = Enum.find(socket.assigns.vendors, &(&1.id == vendor_id))

    if vendor do
      case Vendors.update_vendor(vendor, %{is_active: not is_active}) do
        {:ok, _updated_vendor} ->
          status = if is_active, do: "deactivated", else: "activated"

          {:noreply,
           socket
           |> load_vendor_data()
           |> put_flash(:info, "#{vendor.name} has been #{status}")}

        {:error, _changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Failed to update vendor status")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("view_vendor", %{"id" => _id}, socket) do
    # In a real implementation, this would navigate to a vendor detail page
    {:noreply,
     socket
     |> put_flash(:info, "Vendor detail view not yet implemented")}
  end

  @impl true
  def handle_event("delete_vendor", %{"id" => id}, socket) do
    vendor_id = String.to_integer(id)
    vendor = Enum.find(socket.assigns.vendors, &(&1.id == vendor_id))

    if vendor do
      # Get deletion impact information
      impact = RiverSide.Vendors.VendorCleanup.check_vendor_deletion_impact(vendor)

      {:noreply,
       socket
       |> assign(show_delete_modal: true)
       |> assign(delete_vendor_id: vendor_id)
       |> assign(delete_impact: impact)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("cancel_delete", _params, socket) do
    {:noreply,
     socket
     |> assign(show_delete_modal: false)
     |> assign(delete_vendor_id: nil)
     |> assign(delete_impact: nil)}
  end

  @impl true
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    vendor_id = String.to_integer(id)
    vendor = Enum.find(socket.assigns.vendors, &(&1.id == vendor_id))

    if vendor do
      case RiverSide.Vendors.VendorCleanup.delete_vendor_with_cascade(vendor) do
        {:ok, deleted_info} ->
          message =
            "Vendor '#{deleted_info.vendor_name}' and all associated data deleted successfully! " <>
              "Deleted: #{deleted_info.menu_items_count} menu items, " <>
              "#{deleted_info.orders_count} orders, " <>
              "#{deleted_info.order_items_count} order items."

          {:noreply,
           socket
           |> load_vendor_data()
           |> assign(show_delete_modal: false)
           |> assign(delete_vendor_id: nil)
           |> assign(delete_impact: nil)
           |> put_flash(:info, message)}

        {:error, reason} ->
          error_message =
            case reason do
              {:cascade_deletion_error, _} -> "Failed to delete vendor data. Please try again."
              {:vendor_deletion_failed, _} -> "Failed to delete vendor profile. Please try again."
              {:user_deletion_failed, _} -> "Failed to delete user account. Please try again."
              _ -> "Failed to delete vendor. Please try again."
            end

          {:noreply,
           socket
           |> assign(show_delete_modal: false)
           |> assign(delete_vendor_id: nil)
           |> assign(delete_impact: nil)
           |> put_flash(:error, error_message)}
      end
    else
      {:noreply, socket}
    end
  end

  defp load_vendor_data(socket) do
    vendors = Vendors.list_vendors()

    # Calculate menu item counts for each vendor
    vendor_menu_counts =
      vendors
      |> Enum.map(fn vendor ->
        {vendor.id, length(Vendors.list_menu_items(vendor.id))}
      end)
      |> Map.new()

    # Calculate today's order counts for each vendor
    vendor_order_counts =
      vendors
      |> Enum.map(fn vendor ->
        {vendor.id, length(Vendors.list_todays_orders(vendor.id))}
      end)
      |> Map.new()

    # Calculate total menu items
    total_menu_items = Enum.reduce(vendor_menu_counts, 0, fn {_id, count}, acc -> acc + count end)

    # Check for issues
    vendor_issues = check_vendor_issues(vendors)

    socket
    |> assign(vendors: vendors)
    |> assign(vendor_menu_counts: vendor_menu_counts)
    |> assign(vendor_order_counts: vendor_order_counts)
    |> assign(total_menu_items: total_menu_items)
    |> assign(vendor_issues: vendor_issues)
  end

  defp check_vendor_issues(vendors) do
    issues = []

    # Check for vendors without users
    vendors_without_users =
      Enum.filter(vendors, fn vendor ->
        is_nil(vendor.user)
      end)

    issues =
      if length(vendors_without_users) > 0 do
        ["#{length(vendors_without_users)} vendor(s) without linked user accounts" | issues]
      else
        issues
      end

    # Check for inactive vendors with recent orders
    # This would require additional logic to implement

    issues
  end
end
