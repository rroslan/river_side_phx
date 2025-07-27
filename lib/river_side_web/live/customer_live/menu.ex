defmodule RiverSideWeb.CustomerLive.Menu do
  use RiverSideWeb, :live_view

  alias RiverSide.Vendors
  alias RiverSide.Tables

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 pb-20">
      <div class="navbar bg-base-300 shadow-lg sticky top-0 z-40">
        <div class="flex-1">
          <h1 class="text-2xl font-bold text-base-content px-4">Menu</h1>
        </div>
        <div class="flex-none gap-2">
          <div class="text-sm text-base-content/70">
            Table #{@customer_info.table_number}
          </div>
          <.link href={~p"/"} class="btn btn-ghost btn-sm">
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
            Exit
          </.link>
        </div>
      </div>

      <div class="container mx-auto p-4">
        <!-- Vendor Tabs -->
        <div class="tabs tabs-boxed mb-6">
          <%= for vendor <- @vendors do %>
            <button
              class={"tab #{if @selected_vendor_id == vendor.id, do: "tab-active"}"}
              phx-click="select_vendor"
              phx-value-id={vendor.id}
            >
              {vendor.name}
            </button>
          <% end %>
        </div>
        
    <!-- Category Filter -->
        <%= if @selected_vendor_id do %>
          <div class="flex gap-2 mb-6 overflow-x-auto pb-2">
            <button
              class={"btn btn-sm #{if @selected_category == "all", do: "btn-primary", else: "btn-ghost"}"}
              phx-click="filter_category"
              phx-value-category="all"
            >
              All
            </button>
            <button
              class={"btn btn-sm #{if @selected_category == "food", do: "btn-primary", else: "btn-ghost"}"}
              phx-click="filter_category"
              phx-value-category="food"
            >
              Food
            </button>
            <button
              class={"btn btn-sm #{if @selected_category == "drinks", do: "btn-primary", else: "btn-ghost"}"}
              phx-click="filter_category"
              phx-value-category="drinks"
            >
              Drinks
            </button>
          </div>
        <% end %>
        
    <!-- Menu Items Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <%= for item <- @filtered_items do %>
            <div class="card bg-base-100 shadow-lg">
              <%= if item.image_url do %>
                <figure>
                  <img src={item.image_url} alt={item.name} class="w-48 h-48 mx-auto object-cover" />
                </figure>
              <% end %>
              <div class="card-body">
                <h3 class="card-title text-lg">{item.name}</h3>
                <%= if item.description do %>
                  <p class="text-sm text-base-content/70">{item.description}</p>
                <% end %>
                <div class="flex justify-between items-center mt-4">
                  <span class="text-xl font-bold">RM {format_currency(item.price)}</span>
                  <div class="flex items-center gap-2">
                    <%= if Map.get(@cart_items, item.id, 0) > 0 do %>
                      <button
                        phx-click="remove_from_cart"
                        phx-value-id={item.id}
                        class="btn btn-sm btn-circle"
                      >
                        -
                      </button>
                      <span class="font-bold">{Map.get(@cart_items, item.id, 0)}</span>
                    <% end %>
                    <button
                      phx-click="add_to_cart"
                      phx-value-id={item.id}
                      class="btn btn-sm btn-circle btn-primary"
                    >
                      +
                    </button>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>

        <%= if @filtered_items == [] do %>
          <div class="text-center py-12">
            <p class="text-base-content/60">No items available in this category</p>
          </div>
        <% end %>
      </div>
      
    <!-- Floating Cart Button -->
      <%= if @cart_count > 0 do %>
        <div class="fixed bottom-6 right-6 z-50">
          <.link
            href={
              ~p"/customer/cart?phone=#{URI.encode(@customer_info.phone)}&table=#{@customer_info.table_number}"
            }
            class="btn btn-primary btn-lg shadow-2xl"
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
                d="M2.25 3h1.386c.51 0 .955.343 1.087.835l.383 1.437M7.5 14.25a3 3 0 00-3 3h15.75m-12.75-3h11.218c1.121-2.3 2.1-4.684 2.924-7.138a60.114 60.114 0 00-16.536-1.84M7.5 14.25L5.106 5.272M6 20.25a.75.75 0 11-1.5 0 .75.75 0 011.5 0zm12.75 0a.75.75 0 11-1.5 0 .75.75 0 011.5 0z"
              />
            </svg>
            <span class="badge badge-sm badge-secondary">{@cart_count}</span>
            <span>RM {format_currency(@cart_total)}</span>
          </.link>
        </div>
      <% end %>
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

      # Get the table
      table = Tables.get_table_by_number!(customer_info.table_number)

      # Subscribe to table updates
      Tables.subscribe_to_table(table.number)

      # Load cart from table
      cart_items =
        Tables.get_table_cart(table)
        |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
        |> Map.new()

      vendors = Vendors.list_active_vendors()
      selected_vendor_id = if vendors != [], do: hd(vendors).id, else: nil

      menu_items =
        if selected_vendor_id, do: Vendors.list_available_menu_items(selected_vendor_id), else: []

      # Calculate initial cart totals
      {count, total} = calculate_cart_totals(cart_items, menu_items)

      {:ok,
       socket
       |> assign(customer_info: customer_info)
       |> assign(table: table)
       |> assign(vendors: vendors)
       |> assign(selected_vendor_id: selected_vendor_id)
       |> assign(selected_category: "all")
       |> assign(menu_items: menu_items)
       |> assign(filtered_items: menu_items)
       |> assign(cart_items: cart_items)
       |> assign(cart_count: count)
       |> assign(cart_total: total)}
    else
      {:ok, push_navigate(socket, to: ~p"/")}
    end
  end

  @impl true
  def handle_event("select_vendor", %{"id" => vendor_id}, socket) do
    vendor_id = String.to_integer(vendor_id)
    menu_items = Vendors.list_available_menu_items(vendor_id)

    {:noreply,
     socket
     |> assign(selected_vendor_id: vendor_id)
     |> assign(menu_items: menu_items)
     |> assign(filtered_items: menu_items)
     |> recalculate_cart_totals()
     |> assign(selected_category: "all")}
  end

  @impl true
  def handle_event("filter_category", %{"category" => category}, socket) do
    filtered_items =
      if category == "all" do
        socket.assigns.menu_items
      else
        Enum.filter(socket.assigns.menu_items, &(&1.category == category))
      end

    {:noreply,
     socket
     |> assign(selected_category: category)
     |> assign(filtered_items: filtered_items)}
  end

  @impl true
  def handle_event("add_to_cart", %{"id" => item_id}, socket) do
    item_id = String.to_integer(item_id)
    item = Enum.find(socket.assigns.menu_items, &(&1.id == item_id))

    if item do
      case Tables.add_to_cart(socket.assigns.table, item_id, 1) do
        {:ok, updated_table} ->
          cart_items =
            Tables.get_table_cart(updated_table)
            |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
            |> Map.new()

          {count, total} = calculate_cart_totals(cart_items, socket.assigns.menu_items)

          {:noreply,
           socket
           |> assign(table: updated_table)
           |> assign(cart_items: cart_items)
           |> assign(cart_count: count)
           |> assign(cart_total: total)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to add item to cart")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("remove_from_cart", %{"id" => item_id}, socket) do
    item_id = String.to_integer(item_id)
    current_qty = Map.get(socket.assigns.cart_items, item_id, 0)

    result =
      if current_qty > 1 do
        Tables.update_cart_item(socket.assigns.table, item_id, current_qty - 1)
      else
        Tables.remove_from_cart(socket.assigns.table, item_id)
      end

    case result do
      {:ok, updated_table} ->
        cart_items =
          Tables.get_table_cart(updated_table)
          |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
          |> Map.new()

        {count, total} = calculate_cart_totals(cart_items, socket.assigns.menu_items)

        {:noreply,
         socket
         |> assign(table: updated_table)
         |> assign(cart_items: cart_items)
         |> assign(cart_count: count)
         |> assign(cart_total: total)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update cart")}
    end
  end

  @impl true
  def handle_info({:table_updated, table}, socket) do
    # Load updated cart from table
    cart_items =
      Tables.get_table_cart(table)
      |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
      |> Map.new()

    {count, total} = calculate_cart_totals(cart_items, socket.assigns.menu_items)

    {:noreply,
     socket
     |> assign(table: table)
     |> assign(cart_items: cart_items)
     |> assign(cart_count: count)
     |> assign(cart_total: total)}
  end

  defp recalculate_cart_totals(socket) do
    {count, total} = calculate_cart_totals(socket.assigns.cart_items, socket.assigns.menu_items)

    socket
    |> assign(cart_count: count)
    |> assign(cart_total: total)
  end

  defp calculate_cart_totals(cart_items, menu_items) do
    Enum.reduce(cart_items, {0, Decimal.new("0")}, fn {item_id, qty}, {count, total} ->
      item = Enum.find(menu_items, &(&1.id == item_id))

      if item do
        item_total = Decimal.mult(item.price, qty)
        {count + qty, Decimal.add(total, item_total)}
      else
        {count, total}
      end
    end)
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
