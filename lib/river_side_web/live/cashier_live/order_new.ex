defmodule RiverSideWeb.CashierLive.OrderNew do
  use RiverSideWeb, :live_view

  alias RiverSide.Vendors

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <!-- Navigation -->
      <div class="navbar bg-base-300 shadow-lg">
        <div class="flex-1">
          <h1 class="text-2xl font-bold text-base-content px-4">Create New Order</h1>
        </div>
        <div class="flex-none">
          <.link href={~p"/cashier/dashboard"} class="btn btn-ghost">
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
                d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18"
              />
            </svg>
            Back to Dashboard
          </.link>
        </div>
      </div>
      
    <!-- Main Content -->
      <div class="container mx-auto p-6">
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- Vendor Selection -->
          <div class="lg:col-span-2">
            <div class="card bg-base-100 shadow-xl mb-6">
              <div class="card-body">
                <h2 class="card-title mb-4">Select Vendor</h2>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <%= for vendor <- @vendors do %>
                    <div
                      class={"card bg-base-200 cursor-pointer hover:shadow-lg transition-shadow " <> if(@selected_vendor && @selected_vendor.id == vendor.id, do: "ring-2 ring-primary", else: "")}
                      phx-click="select_vendor"
                      phx-value-id={vendor.id}
                    >
                      <div class="card-body">
                        <h3 class="font-bold">{vendor.name}</h3>
                        <p class="text-sm text-base-content/70">
                          {vendor.description || "No description"}
                        </p>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
            
    <!-- Menu Items -->
            <%= if @selected_vendor do %>
              <div class="card bg-base-100 shadow-xl">
                <div class="card-body">
                  <h2 class="card-title mb-4">{@selected_vendor.name} Menu</h2>
                  
    <!-- Category Tabs -->
                  <div class="tabs tabs-boxed mb-4">
                    <a
                      class={"tab " <> if(@selected_category == "all", do: "tab-active", else: "")}
                      phx-click="set_category"
                      phx-value-category="all"
                    >
                      All
                    </a>
                    <a
                      class={"tab " <> if(@selected_category == "food", do: "tab-active", else: "")}
                      phx-click="set_category"
                      phx-value-category="food"
                    >
                      Food
                    </a>
                    <a
                      class={"tab " <> if(@selected_category == "drinks", do: "tab-active", else: "")}
                      phx-click="set_category"
                      phx-value-category="drinks"
                    >
                      Drinks
                    </a>
                  </div>
                  
    <!-- Menu Items Grid -->
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <%= for item <- filter_menu_items(@menu_items, @selected_category) do %>
                      <div class="card bg-base-200">
                        <div class="card-body">
                          <div class="flex justify-between items-start">
                            <div class="flex-1">
                              <h4 class="font-bold">{item.name}</h4>
                              <%= if item.description do %>
                                <p class="text-sm text-base-content/70">{item.description}</p>
                              <% end %>
                              <p class="text-lg font-semibold text-primary mt-2">
                                RM {format_currency(item.price)}
                              </p>
                            </div>
                            <button
                              class="btn btn-primary btn-sm"
                              phx-click="add_item"
                              phx-value-id={item.id}
                            >
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
                                  d="M12 4.5v15m7.5-7.5h-15"
                                />
                              </svg>
                            </button>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
          
    <!-- Order Summary -->
          <div class="lg:col-span-1">
            <div class="card bg-base-100 shadow-xl sticky top-6">
              <div class="card-body">
                <h2 class="card-title mb-4">Order Summary</h2>

                <%= if Enum.empty?(@cart_items) do %>
                  <div class="text-center py-8">
                    <p class="text-base-content/60">No items added yet</p>
                  </div>
                <% else %>
                  <div class="space-y-3">
                    <%= for {item_id, cart_item} <- @cart_items do %>
                      <div class="flex justify-between items-center">
                        <div class="flex-1">
                          <p class="font-medium">{cart_item.name}</p>
                          <div class="flex items-center gap-2 mt-1">
                            <button
                              class="btn btn-xs btn-circle"
                              phx-click="decrease_quantity"
                              phx-value-id={item_id}
                            >
                              -
                            </button>
                            <span class="text-sm font-bold">{cart_item.quantity}</span>
                            <button
                              class="btn btn-xs btn-circle"
                              phx-click="increase_quantity"
                              phx-value-id={item_id}
                            >
                              +
                            </button>
                            <span class="text-sm text-base-content/70">
                              × RM {format_currency(cart_item.price)}
                            </span>
                          </div>
                        </div>
                        <div class="text-right">
                          <p class="font-semibold">RM {format_currency(cart_item.subtotal)}</p>
                          <button
                            class="btn btn-ghost btn-xs text-error"
                            phx-click="remove_item"
                            phx-value-id={item_id}
                          >
                            Remove
                          </button>
                        </div>
                      </div>
                    <% end %>
                  </div>

                  <div class="divider"></div>

                  <div class="space-y-2">
                    <div class="flex justify-between items-center">
                      <p class="text-lg font-bold">Total</p>
                      <p class="text-xl font-bold text-primary">
                        RM {format_currency(@total_amount)}
                      </p>
                    </div>
                  </div>

                  <div class="divider"></div>
                  
    <!-- Customer Details -->
                  <div class="form-control w-full">
                    <label class="label">
                      <span class="label-text">Customer Name</span>
                    </label>
                    <input
                      type="text"
                      class="input input-bordered w-full"
                      phx-blur="set_customer_name"
                      value={@customer_name}
                      placeholder="Enter customer name"
                    />
                  </div>

                  <div class="form-control w-full mt-2">
                    <label class="label">
                      <span class="label-text">Table Number (Optional)</span>
                    </label>
                    <input
                      type="text"
                      class="input input-bordered w-full"
                      phx-blur="set_table_number"
                      value={@table_number}
                      placeholder="Enter table number"
                    />
                  </div>

                  <button
                    class="btn btn-primary w-full mt-4"
                    phx-click="place_order"
                    disabled={@customer_name == "" || @customer_name == nil}
                  >
                    Place Order
                  </button>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_scope.user.is_cashier do
      vendors = Vendors.list_active_vendors()

      {:ok,
       socket
       |> assign(
         vendors: vendors,
         selected_vendor: nil,
         menu_items: [],
         selected_category: "all",
         cart_items: %{},
         total_amount: Decimal.new("0"),
         customer_name: "",
         table_number: ""
       )}
    else
      {:ok,
       socket
       |> put_flash(:error, "You are not authorized to access this page")
       |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("select_vendor", %{"id" => id}, socket) do
    vendor = Vendors.get_vendor!(id)
    menu_items = Vendors.list_available_menu_items(vendor.id)

    {:noreply,
     socket
     |> assign(
       selected_vendor: vendor,
       menu_items: menu_items,
       cart_items: %{},
       total_amount: Decimal.new("0")
     )}
  end

  @impl true
  def handle_event("set_category", %{"category" => category}, socket) do
    {:noreply, assign(socket, selected_category: category)}
  end

  @impl true
  def handle_event("add_item", %{"id" => id}, socket) do
    item = Enum.find(socket.assigns.menu_items, &(&1.id == String.to_integer(id)))

    if item do
      cart_items =
        Map.update(
          socket.assigns.cart_items,
          item.id,
          %{
            name: item.name,
            price: item.price,
            quantity: 1,
            subtotal: item.price
          },
          fn existing ->
            new_quantity = existing.quantity + 1
            %{existing | quantity: new_quantity, subtotal: Decimal.mult(item.price, new_quantity)}
          end
        )

      total_amount = calculate_total(cart_items)

      {:noreply, assign(socket, cart_items: cart_items, total_amount: total_amount)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("increase_quantity", %{"id" => id}, socket) do
    item_id = String.to_integer(id)
    cart_items = update_quantity(socket.assigns.cart_items, item_id, 1)
    total_amount = calculate_total(cart_items)

    {:noreply, assign(socket, cart_items: cart_items, total_amount: total_amount)}
  end

  @impl true
  def handle_event("decrease_quantity", %{"id" => id}, socket) do
    item_id = String.to_integer(id)
    cart_items = update_quantity(socket.assigns.cart_items, item_id, -1)
    total_amount = calculate_total(cart_items)

    {:noreply, assign(socket, cart_items: cart_items, total_amount: total_amount)}
  end

  @impl true
  def handle_event("remove_item", %{"id" => id}, socket) do
    item_id = String.to_integer(id)
    cart_items = Map.delete(socket.assigns.cart_items, item_id)
    total_amount = calculate_total(cart_items)

    {:noreply, assign(socket, cart_items: cart_items, total_amount: total_amount)}
  end

  @impl true
  def handle_event("set_customer_name", %{"value" => value}, socket) do
    {:noreply, assign(socket, customer_name: value)}
  end

  @impl true
  def handle_event("set_table_number", %{"value" => value}, socket) do
    {:noreply, assign(socket, table_number: value)}
  end

  @impl true
  def handle_event("place_order", _params, socket) do
    if socket.assigns.customer_name != "" && !Enum.empty?(socket.assigns.cart_items) do
      order_attrs = %{
        vendor_id: socket.assigns.selected_vendor.id,
        cashier_id: socket.assigns.current_scope.user.id,
        customer_name: socket.assigns.customer_name,
        table_number: socket.assigns.table_number,
        status: "pending"
      }

      items =
        Enum.map(socket.assigns.cart_items, fn {item_id, cart_item} ->
          %{
            menu_item_id: item_id,
            quantity: cart_item.quantity,
            price: cart_item.price
          }
        end)

      case Vendors.create_order_with_items(order_attrs, items) do
        {:ok, order} ->
          {:noreply,
           socket
           |> put_flash(:info, "Order ##{order.order_number} created successfully!")
           |> push_navigate(to: ~p"/cashier/dashboard")}

        {:error, _reason} ->
          {:noreply,
           socket
           |> put_flash(:error, "Failed to create order. Please try again.")}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, "Please enter customer name and add items to the order.")}
    end
  end

  defp filter_menu_items(menu_items, "all"), do: menu_items

  defp filter_menu_items(menu_items, category) do
    Enum.filter(menu_items, &(&1.category == category))
  end

  defp update_quantity(cart_items, item_id, change) do
    case Map.get(cart_items, item_id) do
      nil ->
        cart_items

      item ->
        new_quantity = item.quantity + change

        if new_quantity <= 0 do
          Map.delete(cart_items, item_id)
        else
          Map.put(cart_items, item_id, %{
            item
            | quantity: new_quantity,
              subtotal: Decimal.mult(item.price, new_quantity)
          })
        end
    end
  end

  defp calculate_total(cart_items) do
    cart_items
    |> Map.values()
    |> Enum.reduce(Decimal.new("0"), fn item, acc ->
      Decimal.add(acc, item.subtotal)
    end)
  end

  defp format_currency(decimal) when is_struct(decimal, Decimal) do
    decimal
    |> Decimal.to_float()
    |> :erlang.float_to_binary(decimals: 2)
  end

  defp format_currency(nil), do: "0.00"
end
