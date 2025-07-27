defmodule RiverSideWeb.CashierLive.Dashboard do
  use RiverSideWeb, :live_view

  alias RiverSide.Vendors
  alias RiverSide.Tables
  alias RiverSideWeb.Helpers.TimezoneHelper

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
        <!-- Today's Summary -->
        <div class="card bg-base-100 shadow-xl mb-8">
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
        
    <!-- Active Orders -->
        <div class="card bg-base-100 shadow-xl mb-8">
          <div class="card-body">
            <div class="flex justify-between items-center mb-4">
              <h2 class="card-title text-2xl">Active Orders by Table</h2>
              <div class="text-sm text-base-content/60">
                <span class="font-semibold">{length(@orders_by_table)}</span> tables with orders
              </div>
            </div>
            <%= if Enum.empty?(@active_orders) do %>
              <div class="text-center py-8">
                <p class="text-base-content/60">No active orders at the moment</p>
              </div>
            <% else %>
              <!-- Table View -->
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                <%= for {table_number, table_data} <- @orders_by_table do %>
                  <div class="card bg-base-200 shadow-xl">
                    <div class="card-body">
                      <div class="flex justify-between items-start">
                        <h3 class="card-title">Table #{table_number}</h3>
                        <%= if table_data.all_paid do %>
                          <span class="badge badge-success">All Paid</span>
                        <% else %>
                          <% paid_count = Enum.count(table_data.orders, & &1.paid) %>
                          <span class="badge badge-warning">
                            {paid_count}/{table_data.order_count} Paid
                          </span>
                        <% end %>
                      </div>

                      <div class="mt-2 space-y-2">
                        <%= for order <- table_data.orders do %>
                          <div class="p-2 bg-base-100 rounded">
                            <div class="flex justify-between items-center">
                              <div>
                                <p class="font-semibold text-sm">{order.vendor.name}</p>
                                <p class="text-xs text-base-content/60">#{order.order_number}</p>
                              </div>
                              <div class="text-right">
                                <span class={"badge badge-sm #{status_badge_class(order.status)}"}>
                                  {String.capitalize(order.status)}
                                </span>
                                <p class="text-sm font-semibold mt-1">
                                  RM {format_currency(order.total_amount)}
                                </p>
                              </div>
                            </div>
                          </div>
                        <% end %>
                      </div>

                      <div class="divider my-2"></div>

                      <div class="flex justify-between items-center font-bold">
                        <span>Total</span>
                        <span class="text-lg">RM {format_currency(table_data.total_amount)}</span>
                      </div>

                      <div class="card-actions justify-end mt-4">
                        <button
                          phx-click="view_table_orders"
                          phx-value-table={table_number}
                          class="btn btn-primary btn-sm"
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
                    <th>Table</th>
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
                      <td>#{order.table_number}</td>
                      <td>{TimezoneHelper.format_malaysian_time_only(order.inserted_at)}</td>
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
                  <%= if @selected_order do %>
                    <% table_orders = Vendors.list_orders_for_table(@selected_order.table_number) %>
                    <% active_orders =
                      Enum.filter(table_orders, &(&1.status not in ["completed", "cancelled"])) %>
                    <%= if length(active_orders) > 1 do %>
                      <div>
                        <p class="text-sm text-base-content/70">Table Orders</p>
                        <div class="text-sm">
                          <%= for order <- active_orders do %>
                            <div class={"badge #{if order.id == @selected_order.id, do: "badge-primary", else: "badge-ghost"} badge-sm mr-1"}>
                              {order.vendor.name}: {String.capitalize(order.status)}
                            </div>
                          <% end %>
                        </div>
                      </div>
                    <% end %>
                  <% end %>
                  <div>
                    <p class="text-sm text-base-content/70">Payment Status</p>
                    <%= if @selected_order.paid == true do %>
                      <span class="badge badge-success">
                        Paid at {TimezoneHelper.format_malaysian_time_only(@selected_order.paid_at)}
                      </span>
                    <% else %>
                      <span class="badge badge-warning">Unpaid</span>
                    <% end %>
                  </div>
                  <div>
                    <p class="text-sm text-base-content/70">Time</p>
                    <p class="font-bold">
                      {TimezoneHelper.format_malaysian_time_only(@selected_order.inserted_at)}
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
              <%= if @selected_order && @selected_order.status == "ready" && @selected_order.paid != true do %>
                <button
                  phx-click="mark_as_paid"
                  phx-value-id={@selected_order.id}
                  class="btn btn-warning"
                >
                  Mark as Paid
                </button>
              <% end %>
              <button phx-click="close_order_modal" class="btn">Close</button>
            </div>
          </div>
        </div>
      <% end %>
      
    <!-- Table Orders Modal -->
      <%= if @show_table_modal do %>
        <div class="modal modal-open">
          <div class="modal-box max-w-4xl">
            <h3 class="font-bold text-lg mb-4">
              Table #{@selected_table} - All Orders
            </h3>

            <% table_orders = Vendors.list_orders_for_table(@selected_table) %>
            <% active_orders =
              Enum.filter(table_orders, &(&1.status not in ["completed", "cancelled"])) %>
            <% total_amount =
              Enum.reduce(active_orders, Decimal.new("0"), fn order, acc ->
                Decimal.add(acc, order.total_amount)
              end) %>

            <div class="stats stats-vertical lg:stats-horizontal shadow mb-4 w-full">
              <div class="stat">
                <div class="stat-title">Active Orders</div>
                <div class="stat-value">{length(active_orders)}</div>
              </div>
              <div class="stat">
                <div class="stat-title">Total Amount</div>
                <div class="stat-value text-primary">RM {format_currency(total_amount)}</div>
              </div>
              <div class="stat">
                <div class="stat-title">Payment Status</div>
                <div class="stat-value text-sm">
                  <%= if Enum.all?(active_orders, & &1.paid) do %>
                    <span class="badge badge-success badge-lg">All Paid</span>
                  <% else %>
                    <% paid_count = Enum.count(active_orders, & &1.paid) %>
                    <span class="badge badge-warning badge-lg">
                      {paid_count}/{length(active_orders)} Paid
                    </span>
                  <% end %>
                </div>
              </div>
            </div>

            <div class="space-y-4 max-h-96 overflow-y-auto">
              <%= for order <- active_orders do %>
                <div class="card bg-base-200">
                  <div class="card-body p-4">
                    <div class="flex justify-between items-start">
                      <div>
                        <h4 class="font-semibold">{order.vendor.name}</h4>
                        <p class="text-sm text-base-content/70">Order #{order.order_number}</p>
                      </div>
                      <div class="text-right">
                        <span class={status_badge_class(order.status)}>
                          {String.capitalize(order.status)}
                        </span>
                        <%= if order.paid do %>
                          <span class="badge badge-success badge-sm ml-1">Paid</span>
                        <% end %>
                      </div>
                    </div>

                    <div class="divider my-2"></div>

                    <div class="space-y-1">
                      <%= for item <- order.order_items do %>
                        <div class="flex justify-between text-sm">
                          <span>{item.quantity}x {item.menu_item.name}</span>
                          <span>RM {format_currency(item.subtotal)}</span>
                        </div>
                      <% end %>
                    </div>

                    <div class="flex justify-between font-semibold mt-2 pt-2 border-t">
                      <span>Subtotal</span>
                      <span>RM {format_currency(order.total_amount)}</span>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>

            <div class="divider"></div>

            <div class="flex justify-between items-center font-bold text-lg">
              <span>Total for Table</span>
              <span class="text-primary">RM {format_currency(total_amount)}</span>
            </div>

            <div class="modal-action">
              <%= if Enum.all?(active_orders, &(&1.status == "ready")) do %>
                <%= if not Enum.all?(active_orders, & &1.paid) do %>
                  <button
                    phx-click="pay_all_table_orders"
                    phx-value-table={@selected_table}
                    class="btn btn-warning"
                  >
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
                        d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25 2.25 0 002.25-2.25V6.75A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25v10.5A2.25 2.25 0 004.5 19.5z"
                      />
                    </svg>
                    Pay All Orders
                  </button>
                <% else %>
                  <button
                    phx-click="release_table"
                    phx-value-table={@selected_table}
                    class="btn btn-success"
                  >
                    Release Table
                  </button>
                <% end %>
              <% end %>
              <button phx-click="close_table_modal" class="btn">Close</button>
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
      IO.puts("Cashier dashboard mounted - subscribed to order updates")

      {:ok,
       socket
       |> assign(show_order_modal: false, selected_order: nil)
       |> assign(show_table_modal: false, selected_table: nil)
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
  def handle_event("view_order", %{"id" => id}, socket) do
    order = Vendors.get_order!(id)
    {:noreply, assign(socket, show_order_modal: true, selected_order: order)}
  end

  @impl true
  def handle_event("close_order_modal", _params, socket) do
    {:noreply, assign(socket, show_order_modal: false, selected_order: nil)}
  end

  @impl true
  def handle_event("mark_as_paid", %{"id" => order_id}, socket) do
    order = Vendors.get_order!(order_id)

    case Vendors.mark_order_as_paid(order) do
      {:ok, updated_order} ->
        socket =
          if socket.assigns.show_order_modal do
            assign(socket, selected_order: updated_order)
          else
            socket
          end

        {:noreply,
         socket
         |> put_flash(:info, "Order #{order.order_number} marked as paid")
         |> load_orders()}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to mark order as paid")
         |> load_orders()}
    end
  end

  @impl true
  def handle_event("view_table_orders", %{"table" => table_number}, socket) do
    table_orders =
      socket.assigns.active_orders
      |> Enum.filter(&(&1.table_number == table_number))

    {:noreply,
     socket
     |> assign(:show_table_modal, true)
     |> assign(:selected_table, table_number)
     |> assign(:table_orders, table_orders)}
  end

  def handle_event("close_table_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_table_modal, false)
     |> assign(:selected_table, nil)}
  end

  def handle_event("pay_all_table_orders", %{"table" => table_number}, socket) do
    # Get all active orders for the table
    orders =
      Vendors.list_orders_for_table(table_number)
      |> Enum.filter(&(&1.status not in ["completed", "cancelled"] and not &1.paid))

    # Mark all orders as paid
    Enum.each(orders, fn order ->
      Vendors.mark_order_as_paid(order)
    end)

    {:noreply,
     socket
     |> put_flash(:info, "All orders for table #{table_number} marked as paid")
     |> assign(:show_table_modal, false)
     |> assign(:selected_table, nil)
     |> load_orders()}
  end

  def handle_event("release_table", %{"table" => table_number}, socket) do
    # Complete all orders and release table
    orders =
      Vendors.list_orders_for_table(table_number)
      |> Enum.filter(&(&1.status not in ["completed", "cancelled"]))

    # Update all orders to completed
    Enum.each(orders, fn order ->
      Vendors.update_order_status(order, "completed")
    end)

    # Release the table
    case Tables.get_table_by_number(String.to_integer(table_number)) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Table not found")
         |> assign(:show_table_modal, false)
         |> assign(:selected_table, nil)
         |> load_orders()}

      table ->
        case Tables.release_table(table) do
          {:ok, _table} ->
            {:noreply,
             socket
             |> put_flash(:success, "Table #{table_number} released successfully")
             |> assign(:show_table_modal, false)
             |> assign(:selected_table, nil)
             |> load_orders()}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> put_flash(:error, "Failed to release table")
             |> assign(:show_table_modal, false)
             |> assign(:selected_table, nil)
             |> load_orders()}
        end
    end
  end

  def handle_event("complete_and_release", %{"id" => order_id, "table" => table_number}, socket) do
    order = Vendors.get_order!(order_id)

    # Check if order is paid before completing
    if order.paid != true do
      {:noreply,
       socket
       |> put_flash(:error, "Order must be marked as paid before releasing table")
       |> load_orders()}
    else
      case Vendors.update_order_status(order, %{status: "completed"}) do
        {:ok, _updated_order} ->
          # Check if all orders for this table are completed
          if Vendors.all_orders_completed_for_table?(table_number) do
            # All orders completed, try to release the table
            case Tables.get_table_by_number(String.to_integer(table_number)) do
              nil ->
                # Table doesn't exist, but order is completed
                {:noreply,
                 socket
                 |> put_flash(:info, "Order completed")
                 |> load_orders()}

              table ->
                case Tables.release_table(table) do
                  {:ok, _released_table} ->
                    {:noreply,
                     socket
                     |> put_flash(:info, "Order completed and table #{table_number} released")
                     |> load_orders()}

                  {:error, _} ->
                    # Table release failed, but order is completed
                    {:noreply,
                     socket
                     |> put_flash(:info, "Order completed")
                     |> load_orders()}
                end
            end
          else
            # Other orders still active for this table
            other_orders = Vendors.list_orders_for_table(table_number)

            active_count =
              Enum.count(
                other_orders,
                &(&1.status not in ["completed", "cancelled"] && &1.id != order.id)
              )

            {:noreply,
             socket
             |> put_flash(
               :info,
               "Order completed. #{active_count} other order(s) still active for table #{table_number}"
             )
             |> load_orders()}
          end

        {:error, _} ->
          {:noreply,
           socket
           |> put_flash(:error, "Failed to complete order")
           |> load_orders()}
      end
    end
  end

  @impl true
  def handle_info({:order_updated, updated_order}, socket) do
    # Log the update for debugging
    IO.puts(
      "Cashier received order update: Order ##{updated_order.order_number}, Status: #{updated_order.status}, Table: #{updated_order.table_number}"
    )

    # Always reload orders to get fresh data
    socket = load_orders(socket) |> load_stats()

    # Update selected order if it's the one being viewed in modal
    socket =
      if socket.assigns[:selected_order] && socket.assigns.selected_order.id == updated_order.id do
        # Get fresh order data with all associations
        fresh_order = Vendors.get_order!(updated_order.id)
        assign(socket, :selected_order, fresh_order)
      else
        socket
      end

    # Update table modal if viewing the table that contains this order
    socket =
      if socket.assigns[:selected_table] && socket.assigns[:show_table_modal] do
        # Get fresh table orders
        table_orders =
          socket.assigns.active_orders
          |> Enum.filter(&(&1.table_number == socket.assigns.selected_table))
          |> Enum.sort_by(& &1.inserted_at, :asc)

        assign(socket, :table_orders, table_orders)
      else
        socket
      end

    {:noreply, socket}
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

    # Group active orders by table
    orders_by_table = group_orders_by_table(active_orders)

    IO.puts(
      "Loaded #{length(active_orders)} active orders across #{length(orders_by_table)} tables"
    )

    assign(socket,
      active_orders: active_orders,
      orders_by_table: orders_by_table,
      completed_orders: completed_orders
    )
  end

  defp group_orders_by_table(orders) do
    orders
    |> Enum.group_by(& &1.table_number)
    |> Enum.map(fn {table_number, table_orders} ->
      total_amount =
        Enum.reduce(table_orders, Decimal.new("0"), fn order, acc ->
          Decimal.add(acc, order.total_amount)
        end)

      all_paid = Enum.all?(table_orders, & &1.paid)
      all_ready = Enum.all?(table_orders, &(&1.status == "ready"))

      {table_number,
       %{
         orders: table_orders,
         total_amount: total_amount,
         all_paid: all_paid,
         all_ready: all_ready,
         order_count: length(table_orders)
       }}
    end)
    |> Enum.sort_by(fn {table_num, _} -> String.to_integer(table_num) end)
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
