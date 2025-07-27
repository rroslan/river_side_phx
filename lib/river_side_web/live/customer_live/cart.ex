defmodule RiverSideWeb.CustomerLive.Cart do
  use RiverSideWeb, :live_view

  alias RiverSide.Vendors
  alias RiverSide.Tables

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="navbar bg-base-300 shadow-lg">
        <div class="flex-1">
          <h1 class="text-2xl font-bold text-base-content px-4">
            Your Cart - Table #{@customer_info.table_number}
          </h1>
        </div>
        <div class="flex-none">
          <.link
            href={
              ~p"/customer/menu?phone=#{URI.encode(@customer_info.phone)}&table=#{@customer_info.table_number}"
            }
            class="btn btn-ghost btn-sm"
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
                d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18"
              />
            </svg>
            Back to Menu
          </.link>
        </div>
      </div>

      <div class="container mx-auto p-4 max-w-2xl">
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

        <%= if @cart_items == %{} do %>
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
                  d="M2.25 3h1.386c.51 0 .955.343 1.087.835l.383 1.437M7.5 14.25a3 3 0 00-3 3h15.75m-12.75-3h11.218c1.121-2.3 2.1-4.684 2.924-7.138a60.114 60.114 0 00-16.536-1.84M7.5 14.25L5.106 5.272M6 20.25a.75.75 0 11-1.5 0 .75.75 0 011.5 0zm12.75 0a.75.75 0 11-1.5 0 .75.75 0 011.5 0z"
                />
              </svg>
              <h2 class="text-2xl font-bold mt-4">Your cart is empty</h2>
              <p class="text-base-content/70 mt-2">Add some delicious items from the menu!</p>
              <.link
                href={
                  ~p"/customer/menu?phone=#{URI.encode(@customer_info.phone)}&table=#{@customer_info.table_number}"
                }
                class="btn btn-primary mt-6"
              >
                Browse Menu
              </.link>
            </div>
          </div>
        <% else %>
          <!-- Customer Info -->
          <div class="card bg-base-100 shadow-xl mb-4">
            <div class="card-body">
              <h2 class="card-title">Order Summary</h2>
              <div class="grid grid-cols-2 gap-2 text-sm">
                <span class="font-semibold">Table Number:</span>
                <span class="text-lg">#{@customer_info.table_number}</span>
                <span class="font-semibold">Phone:</span>
                <span>{@customer_info.phone}</span>
                <span class="font-semibold">Total Items:</span>
                <span>{Enum.reduce(@cart_items, 0, fn {_, qty}, acc -> acc + qty end)}</span>
                <span class="font-semibold">Vendors:</span>
                <span>{map_size(@items_by_vendor)}</span>
              </div>
            </div>
          </div>
          
    <!-- Cart Items by Vendor -->
          <%= for {vendor_id, vendor_items} <- @items_by_vendor do %>
            <div class="card bg-base-100 shadow-xl mb-4">
              <div class="card-body">
                <div class="flex items-center gap-2 mb-2">
                  <div class="avatar placeholder">
                    <div class="bg-primary text-primary-content rounded-full w-10">
                      <span class="text-xl">{String.first(vendor_items.vendor.name)}</span>
                    </div>
                  </div>
                  <h3 class="card-title">{vendor_items.vendor.name}</h3>
                </div>
                <div class="divider my-2"></div>

                <%= for item <- vendor_items.items do %>
                  <div class="flex justify-between items-center py-2 border-b border-base-200 last:border-0">
                    <div class="flex-1">
                      <h4 class="font-semibold">{item.name}</h4>
                      <p class="text-sm text-base-content/70">
                        {item.description}
                      </p>
                      <p class="text-sm font-medium mt-1">
                        RM {format_currency(item.price)} × {item.quantity}
                      </p>
                    </div>
                    <div class="flex items-center gap-2">
                      <button
                        phx-click="update_quantity"
                        phx-value-id={item.id}
                        phx-value-action="decrease"
                        class="btn btn-sm btn-circle"
                      >
                        -
                      </button>
                      <span class="w-8 text-center font-bold">{item.quantity}</span>
                      <button
                        phx-click="update_quantity"
                        phx-value-id={item.id}
                        phx-value-action="increase"
                        class="btn btn-sm btn-circle"
                      >
                        +
                      </button>
                      <span class="font-bold ml-4">
                        RM {format_currency(Decimal.mult(item.price, item.quantity))}
                      </span>
                    </div>
                  </div>
                <% end %>

                <div class="divider"></div>
                <div class="flex justify-between font-bold">
                  <span>Subtotal:</span>
                  <span>RM {format_currency(vendor_items.subtotal)}</span>
                </div>
              </div>
            </div>
          <% end %>
          
    <!-- Total and Checkout -->
          <div class="card bg-primary text-primary-content shadow-xl">
            <div class="card-body">
              <div class="flex justify-between text-2xl font-bold">
                <span>Total:</span>
                <span>RM {format_currency(@total)}</span>
              </div>
              <button
                phx-click="checkout"
                class="btn btn-secondary btn-lg mt-4"
                phx-disable-with="Processing..."
              >
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
                    d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25 2.25 0 002.25-2.25V6.75A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25v10.5A2.25 2.25 0 004.5 19.5z"
                  />
                </svg>
                Place Order
              </button>
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

    if phone && table_number do
      customer_info = %{
        phone: phone,
        table_number: String.to_integer(table_number)
      }

      # Get the table and load cart from it
      table = Tables.get_table_by_number!(customer_info.table_number)

      # Subscribe to table updates
      Tables.subscribe_to_table(table.number)

      # Load cart from table
      cart_items =
        Tables.get_table_cart(table)
        |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
        |> Map.new()

      {items_by_vendor, total} = organize_cart_items(cart_items)

      {:ok,
       socket
       |> assign(customer_info: customer_info)
       |> assign(table: table)
       |> assign(cart_items: cart_items)
       |> assign(items_by_vendor: items_by_vendor)
       |> assign(total: total)}
    else
      {:ok, push_navigate(socket, to: ~p"/")}
    end
  end

  @impl true
  def handle_event("update_quantity", %{"id" => item_id, "action" => action}, socket) do
    item_id = String.to_integer(item_id)
    current_qty = Map.get(socket.assigns.cart_items, item_id, 0)

    result =
      case action do
        "increase" ->
          Tables.update_cart_item(socket.assigns.table, item_id, current_qty + 1)

        "decrease" ->
          if current_qty > 1 do
            Tables.update_cart_item(socket.assigns.table, item_id, current_qty - 1)
          else
            Tables.remove_from_cart(socket.assigns.table, item_id)
          end
      end

    case result do
      {:ok, updated_table} ->
        cart_items =
          Tables.get_table_cart(updated_table)
          |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
          |> Map.new()

        {items_by_vendor, total} = organize_cart_items(cart_items)

        {:noreply,
         socket
         |> assign(table: updated_table)
         |> assign(cart_items: cart_items)
         |> assign(items_by_vendor: items_by_vendor)
         |> assign(total: total)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update cart")}
    end
  end

  @impl true
  def handle_event("checkout", _params, socket) do
    customer_info = socket.assigns.customer_info

    # Check if cart is empty
    if map_size(socket.assigns.cart_items) == 0 do
      {:noreply, put_flash(socket, :error, "Your cart is empty")}
    else
      # Create orders for each vendor
      order_results =
        Enum.map(socket.assigns.items_by_vendor, fn {vendor_id, vendor_items} ->
          order_params = %{
            vendor_id: vendor_id,
            customer_phone: customer_info.phone,
            customer_name: customer_info.phone,
            table_number: to_string(customer_info.table_number),
            order_items:
              Enum.map(vendor_items.items, fn item ->
                %{
                  menu_item_id: item.id,
                  quantity: item.quantity,
                  price: item.price
                }
              end)
          }

          Vendors.create_order(order_params)
        end)

      # Check if all orders were created successfully
      case Enum.find(order_results, fn {status, _} -> status == :error end) do
        nil ->
          # All orders successful, get the order IDs
          order_ids = Enum.map(order_results, fn {:ok, order} -> order.id end)

          # Clear the cart from the table
          Tables.clear_cart(socket.assigns.table)

          # Redirect to order tracking with parameters
          {:noreply,
           socket
           |> put_flash(:info, "Order placed successfully!")
           |> push_navigate(
             to:
               ~p"/customer/orders?phone=#{URI.encode(customer_info.phone)}&table=#{customer_info.table_number}&order_ids=#{Enum.join(order_ids, ",")}"
           )}

        error ->
          # Log the error for debugging
          require Logger
          Logger.error("Order creation failed: #{inspect(error)}")

          {:noreply,
           socket
           |> put_flash(:error, "Failed to place order. Please try again.")}
      end
    end
  end

  @impl true
  def handle_info({:table_updated, table}, socket) do
    # Load updated cart from table
    cart_items =
      Tables.get_table_cart(table)
      |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
      |> Map.new()

    {items_by_vendor, total} = organize_cart_items(cart_items)

    {:noreply,
     socket
     |> assign(table: table)
     |> assign(cart_items: cart_items)
     |> assign(items_by_vendor: items_by_vendor)
     |> assign(total: total)}
  end

  defp organize_cart_items(cart_items) do
    items_with_details =
      Enum.map(cart_items, fn {item_id, quantity} ->
        item = Vendors.get_menu_item!(item_id)
        Map.put(item, :quantity, quantity)
      end)

    # Group by vendor
    by_vendor =
      Enum.group_by(items_with_details, & &1.vendor_id)
      |> Enum.map(fn {vendor_id, items} ->
        vendor = Vendors.get_vendor!(vendor_id)

        subtotal =
          Enum.reduce(items, Decimal.new("0"), fn item, acc ->
            Decimal.add(acc, Decimal.mult(item.price, item.quantity))
          end)

        {vendor_id, %{vendor: vendor, items: items, subtotal: subtotal}}
      end)
      |> Map.new()

    # Calculate total
    total =
      Enum.reduce(by_vendor, Decimal.new("0"), fn {_, vendor_items}, acc ->
        Decimal.add(acc, vendor_items.subtotal)
      end)

    {by_vendor, total}
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
end
