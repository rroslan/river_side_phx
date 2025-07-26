defmodule RiverSideWeb.CashierLive.Dashboard do
  use RiverSideWeb, :live_view

  alias RiverSide.Vendors

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <!-- Navigation -->
      <div class="navbar bg-base-300 shadow-lg">
        <div class="flex-1">
          <h1 class="text-2xl font-bold text-base-content px-4">Cashier Dashboard</h1>
        </div>
        <div class="flex-none gap-2">
          <div class="dropdown dropdown-end">
            <label tabindex="0" class="btn btn-ghost btn-circle avatar">
              <div class="w-10 rounded-full bg-primary">
                <span class="text-xl font-bold text-primary-content">
                  {String.first(@current_scope.user.email)}
                </span>
              </div>
            </label>
            <ul
              tabindex="0"
              class="mt-3 p-2 shadow menu menu-compact dropdown-content bg-base-100 rounded-box w-52"
            >
              <li class="menu-title">
                <span>{@current_scope.user.email}</span>
              </li>
              <li>
                <.link href={~p"/users/settings"}>Settings</.link>
              </li>
              <li>
                <.link href={~p"/users/log-out"} method="delete">Log out</.link>
              </li>
            </ul>
          </div>
        </div>
      </div>
      
    <!-- Main Content -->
      <div class="container mx-auto p-6">
        <!-- Quick Actions -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">New Order</h2>
              <p>Create a new order for a customer</p>
              <div class="card-actions justify-end">
                <button phx-click="new_order" class="btn btn-primary">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="w-5 h-5 mr-2"
                  >
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
                  </svg>
                  Create Order
                </button>
              </div>
            </div>
          </div>

          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Today's Summary</h2>
              <div class="stats stats-vertical shadow">
                <div class="stat">
                  <div class="stat-title">Total Orders</div>
                  <div class="stat-value text-primary">{@today_stats.total_orders}</div>
                </div>
                <div class="stat">
                  <div class="stat-title">Total Sales</div>
                  <div class="stat-value text-success">RM {@today_stats.total_sales}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Active Orders -->
        <div class="card bg-base-100 shadow-xl mb-8">
          <div class="card-body">
            <h2 class="card-title mb-4">Active Orders</h2>
            <%= if Enum.empty?(@active_orders) do %>
              <div class="text-center py-8">
                <p class="text-base-content/60">No active orders at the moment</p>
              </div>
            <% else %>
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                <%= for order <- @active_orders do %>
                  <div class="card bg-base-200 shadow">
                    <div class="card-body">
                      <div class="flex justify-between items-start">
                        <h3 class="font-bold">Order #{order.order_number}</h3>
                        <span class={status_badge_class(order.status)}>
                          {String.capitalize(order.status)}
                        </span>
                      </div>
                      <p class="text-sm text-base-content/70">{order.vendor.name}</p>
                      <p class="text-lg font-semibold">RM {format_currency(order.total_amount)}</p>
                      <div class="text-sm text-base-content/60">
                        {Calendar.strftime(order.inserted_at, "%I:%M %p")}
                      </div>
                      <div class="card-actions justify-end mt-2">
                        <button
                          phx-click="view_order"
                          phx-value-id={order.id}
                          class="btn btn-sm btn-primary"
                        >
                          View Details
                        </button>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
        
    <!-- Recent Completed Orders -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title mb-4">Recent Completed Orders</h2>
            <div class="overflow-x-auto">
              <table class="table w-full">
                <thead>
                  <tr>
                    <th>Order #</th>
                    <th>Vendor</th>
                    <th>Time</th>
                    <th>Amount</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for order <- @completed_orders do %>
                    <tr class="hover">
                      <td class="font-mono">{order.order_number}</td>
                      <td>{order.vendor.name}</td>
                      <td>{Calendar.strftime(order.inserted_at, "%I:%M %p")}</td>
                      <td class="font-semibold">RM {format_currency(order.total_amount)}</td>
                      <td>
                        <span class={status_badge_class(order.status)}>
                          {String.capitalize(order.status)}
                        </span>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Order Modal -->
      <%= if @show_order_modal do %>
        <div class="modal modal-open">
          <div class="modal-box max-w-2xl">
            <h3 class="font-bold text-lg mb-4">Order Details</h3>
            <%= if @selected_order do %>
              <div class="space-y-4">
                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <p class="text-sm text-base-content/70">Order Number</p>
                    <p class="font-bold">{@selected_order.order_number}</p>
                  </div>
                  <div>
                    <p class="text-sm text-base-content/70">Vendor</p>
                    <p class="font-bold">{@selected_order.vendor.name}</p>
                  </div>
                  <div>
                    <p class="text-sm text-base-content/70">Status</p>
                    <span class={status_badge_class(@selected_order.status)}>
                      {String.capitalize(@selected_order.status)}
                    </span>
                  </div>
                  <div>
                    <p class="text-sm text-base-content/70">Time</p>
                    <p class="font-bold">
                      {Calendar.strftime(@selected_order.inserted_at, "%I:%M %p")}
                    </p>
                  </div>
                </div>

                <div class="divider"></div>

                <div>
                  <h4 class="font-bold mb-2">Order Items</h4>
                  <div class="space-y-2">
                    <%= for item <- @selected_order.order_items do %>
                      <div class="flex justify-between items-center">
                        <div>
                          <p class="font-medium">{item.menu_item.name}</p>
                          <p class="text-sm text-base-content/70">
                            Qty: {item.quantity} × RM {format_currency(item.price)}
                          </p>
                        </div>
                        <p class="font-semibold">RM {format_currency(item.subtotal)}</p>
                      </div>
                    <% end %>
                  </div>
                </div>

                <div class="divider"></div>

                <div class="flex justify-between items-center">
                  <p class="text-lg font-bold">Total Amount</p>
                  <p class="text-xl font-bold text-primary">
                    RM {format_currency(@selected_order.total_amount)}
                  </p>
                </div>
              </div>
            <% end %>
            <div class="modal-action">
              <button phx-click="close_order_modal" class="btn">Close</button>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_scope.user.is_cashier do
      # Subscribe to order updates
      Vendors.subscribe_to_all_orders()

      {:ok,
       socket
       |> assign(show_order_modal: false, selected_order: nil)
       |> load_orders()
       |> load_stats()}
    else
      {:ok,
       socket
       |> put_flash(:error, "You are not authorized to access this page")
       |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("new_order", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/cashier/order/new")}
  end

  @impl true
  def handle_event("view_order", %{"id" => id}, socket) do
    order = Vendors.get_order!(id)
    {:noreply, assign(socket, show_order_modal: true, selected_order: order)}
  end

  @impl true
  def handle_event("close_order_modal", _params, socket) do
    {:noreply, assign(socket, show_order_modal: false, selected_order: nil)}
  end

  @impl true
  def handle_info({:order_updated, _order}, socket) do
    {:noreply, socket |> load_orders()}
  end

  defp load_orders(socket) do
    active_orders =
      Vendors.list_active_orders(nil)
      |> Enum.sort_by(& &1.inserted_at, :asc)

    completed_orders =
      Vendors.list_todays_orders(nil)
      |> Enum.filter(&(&1.status in ["completed", "cancelled"]))
      |> Enum.sort_by(& &1.inserted_at, :desc)
      |> Enum.take(10)

    assign(socket,
      active_orders: active_orders,
      completed_orders: completed_orders
    )
  end

  defp load_stats(socket) do
    # Get all today's orders
    all_orders = Vendors.list_todays_orders(nil)

    total_orders = length(all_orders)

    total_sales =
      all_orders
      |> Enum.filter(&(&1.status == "completed"))
      |> Enum.reduce(Decimal.new("0"), fn order, acc ->
        Decimal.add(acc, order.total_amount || Decimal.new("0"))
      end)
      |> format_currency()

    assign(socket,
      today_stats: %{
        total_orders: total_orders,
        total_sales: total_sales
      }
    )
  end

  defp format_currency(decimal) when is_struct(decimal, Decimal) do
    decimal
    |> Decimal.to_float()
    |> :erlang.float_to_binary(decimals: 2)
  end

  defp format_currency(nil), do: "0.00"

  defp status_badge_class("pending"), do: "badge badge-warning"
  defp status_badge_class("preparing"), do: "badge badge-info"
  defp status_badge_class("ready"), do: "badge badge-success"
  defp status_badge_class("completed"), do: "badge badge-neutral"
  defp status_badge_class("cancelled"), do: "badge badge-error"
  defp status_badge_class(_), do: "badge"
end
