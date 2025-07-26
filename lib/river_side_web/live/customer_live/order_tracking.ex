defmodule RiverSideWeb.CustomerLive.OrderTracking do
  use RiverSideWeb, :live_view

  alias RiverSide.Vendors

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
                <p class="text-base-content/70">
                  {if @customer_info.name, do: @customer_info.name <> " • ", else: ""}{@customer_info.phone}
                </p>
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
          </div>
        </div>
        
    <!-- Active Orders -->
        <%= if @active_orders != [] do %>
          <h3 class="text-xl font-bold mb-4">Active Orders</h3>
          <div class="space-y-4 mb-8">
            <%= for order <- @active_orders do %>
              <div class="card bg-base-100 shadow-xl">
                <div class="card-body">
                  <div class="flex justify-between items-start mb-4">
                    <div>
                      <h4 class="text-lg font-bold">{order.vendor.name}</h4>
                      <p class="text-sm text-base-content/70">Order #{order.order_number}</p>
                    </div>
                    <span class={status_badge_class(order.status) <> " badge-lg"}>
                      {status_text(order.status)}
                    </span>
                  </div>
                  
    <!-- Order Progress -->
                  <div class="w-full mb-4">
                    <ul class="steps steps-horizontal w-full">
                      <li class={"step " <> if(order.status in ["pending", "preparing", "ready", "completed"], do: "step-primary", else: "")}>
                        <span class="text-xs">Pending</span>
                      </li>
                      <li class={"step " <> if(order.status in ["preparing", "ready", "completed"], do: "step-primary", else: "")}>
                        <span class="text-xs">Preparing</span>
                      </li>
                      <li class={"step " <> if(order.status in ["ready", "completed"], do: "step-primary", else: "")}>
                        <span class="text-xs">Ready</span>
                      </li>
                      <li class={"step " <> if(order.status == "completed", do: "step-primary", else: "")}>
                        <span class="text-xs">Completed</span>
                      </li>
                    </ul>
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
        
    <!-- Completed Orders -->
        <%= if @completed_orders != [] do %>
          <h3 class="text-xl font-bold mb-4">Completed Orders</h3>
          <div class="space-y-4">
            <%= for order <- @completed_orders do %>
              <div class="card bg-base-100 shadow-xl opacity-75">
                <div class="card-body">
                  <div class="flex justify-between items-start">
                    <div>
                      <h4 class="font-bold">{order.vendor.name}</h4>
                      <p class="text-sm text-base-content/70">Order #{order.order_number}</p>
                    </div>
                    <div class="text-right">
                      <span class="badge badge-success">Completed</span>
                      <p class="text-sm text-base-content/70 mt-1">
                        {Calendar.strftime(order.updated_at, "%I:%M %p")}
                      </p>
                    </div>
                  </div>
                  <div class="mt-2">
                    <span class="font-bold">Total: RM {format_currency(order.total_amount)}</span>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>

        <%= if @active_orders == [] and @completed_orders == [] do %>
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
    name = params["name"]
    table_number = params["table"]
    order_ids_param = params["order_ids"]

    if phone && table_number do
      customer_info = %{
        phone: phone,
        name: if(name && name != "", do: name, else: nil),
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

      # Separate active and completed orders
      {active_orders, completed_orders} =
        Enum.split_with(orders, fn order ->
          order.status in ["pending", "preparing", "ready"]
        end)

      # Start a timer to refresh order status
      if connected?(socket) and active_orders != [] do
        :timer.send_interval(5000, self(), :refresh_orders)
      end

      {:ok,
       socket
       |> assign(customer_info: customer_info)
       |> assign(active_orders: active_orders)
       |> assign(completed_orders: completed_orders)}
    else
      {:ok, push_navigate(socket, to: ~p"/")}
    end
  end

  @impl true
  def handle_info(:refresh_orders, socket) do
    # Refresh orders from database
    orders =
      Vendors.list_customer_orders(
        socket.assigns.customer_info.phone,
        socket.assigns.customer_info.table_number
      )

    {active_orders, completed_orders} =
      Enum.split_with(orders, fn order ->
        order.status in ["pending", "preparing", "ready"]
      end)

    {:noreply,
     socket
     |> assign(active_orders: active_orders)
     |> assign(completed_orders: completed_orders)}
  end

  @impl true
  def handle_info({:order_updated, updated_order}, socket) do
    # Update the specific order in our lists
    active_orders =
      Enum.map(socket.assigns.active_orders, fn order ->
        if order.id == updated_order.id, do: updated_order, else: order
      end)

    completed_orders =
      Enum.map(socket.assigns.completed_orders, fn order ->
        if order.id == updated_order.id, do: updated_order, else: order
      end)

    # Re-split orders based on status
    all_orders = active_orders ++ completed_orders

    {new_active, new_completed} =
      Enum.split_with(all_orders, fn order ->
        order.status in ["pending", "preparing", "ready"]
      end)

    {:noreply,
     socket
     |> assign(active_orders: new_active)
     |> assign(completed_orders: new_completed)}
  end

  defp status_badge_class("pending"), do: "badge badge-warning"
  defp status_badge_class("preparing"), do: "badge badge-info"
  defp status_badge_class("ready"), do: "badge badge-success"
  defp status_badge_class("completed"), do: "badge badge-neutral"
  defp status_badge_class("cancelled"), do: "badge badge-error"
  defp status_badge_class(_), do: "badge"

  defp status_text("pending"), do: "Pending"
  defp status_text("preparing"), do: "Preparing"
  defp status_text("ready"), do: "Ready to Collect!"
  defp status_text("completed"), do: "Completed"
  defp status_text("cancelled"), do: "Cancelled"
  defp status_text(_), do: "Unknown"

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
end
