defmodule RiverSide.Vendors do
  @moduledoc """
  The Vendors context.
  """

  import Ecto.Query, warn: false
  alias RiverSide.Repo
  alias RiverSideWeb.Helpers.TimezoneHelper

  alias RiverSide.Vendors.{Vendor, MenuItem, Order, OrderItem}

  # Vendor functions

  @doc """
  Returns the list of vendors.
  """
  def list_vendors do
    Repo.all(from v in Vendor, preload: [:user])
  end

  @doc """
  Returns the list of active vendors.
  """
  def list_active_vendors do
    Repo.all(from v in Vendor, where: v.is_active == true, preload: [:user])
  end

  @doc """
  Gets a single vendor.
  """
  def get_vendor!(id), do: Repo.get!(Vendor, id) |> Repo.preload([:user, :menu_items])

  @doc """
  Gets a vendor by user_id.
  """
  def get_vendor_by_user_id(user_id) do
    Repo.get_by(Vendor, user_id: user_id) |> Repo.preload([:menu_items])
  end

  @doc """
  Creates a vendor.
  """
  def create_vendor(attrs \\ %{}) do
    %Vendor{}
    |> Vendor.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a vendor.
  """
  def update_vendor(%Vendor{} = vendor, attrs) do
    vendor
    |> Vendor.update_profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Toggles vendor active status.
  """
  def toggle_vendor_active(%Vendor{} = vendor) do
    vendor
    |> Vendor.toggle_active_changeset(%{is_active: !vendor.is_active})
    |> Repo.update()
  end

  @doc """
  Deletes a vendor.
  """
  def delete_vendor(%Vendor{} = vendor) do
    Repo.delete(vendor)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking vendor changes.
  """
  def change_vendor(%Vendor{} = vendor, attrs \\ %{}) do
    Vendor.changeset(vendor, attrs)
  end

  # Menu Item functions

  @doc """
  Returns the list of menu items for a vendor.
  """
  def list_menu_items(vendor_id) do
    Repo.all(
      from m in MenuItem,
        where: m.vendor_id == ^vendor_id,
        order_by: [asc: m.category, asc: m.name]
    )
  end

  @doc """
  Returns the list of available menu items for a vendor.
  """
  def list_available_menu_items(vendor_id) do
    Repo.all(
      from m in MenuItem,
        where: m.vendor_id == ^vendor_id and m.is_available == true,
        order_by: [asc: m.category, asc: m.name]
    )
  end

  @doc """
  Gets a single menu_item.
  """
  def get_menu_item!(id), do: Repo.get!(MenuItem, id)

  @doc """
  Creates a menu_item.
  """
  def create_menu_item(attrs \\ %{}) do
    %MenuItem{}
    |> MenuItem.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a menu_item.
  """
  def update_menu_item(%MenuItem{} = menu_item, attrs) do
    menu_item
    |> MenuItem.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Toggles menu item availability.
  """
  def toggle_menu_item_availability(%MenuItem{} = menu_item) do
    menu_item
    |> MenuItem.toggle_availability_changeset(%{is_available: !menu_item.is_available})
    |> Repo.update()
  end

  @doc """
  Deletes a menu_item.
  """
  def delete_menu_item(%MenuItem{} = menu_item) do
    Repo.delete(menu_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking menu_item changes.
  """
  def change_menu_item(%MenuItem{} = menu_item, attrs \\ %{}) do
    MenuItem.changeset(menu_item, attrs)
  end

  # Order functions

  @doc """
  Returns the list of orders for a vendor.
  """
  def list_vendor_orders(vendor_id, opts \\ []) do
    query =
      from o in Order,
        order_by: [desc: o.inserted_at],
        preload: [:cashier, :vendor, order_items: :menu_item]

    query =
      if vendor_id do
        from o in query, where: o.vendor_id == ^vendor_id
      else
        query
      end

    query =
      if status = opts[:status] do
        from o in query, where: o.status == ^status
      else
        query
      end

    query =
      if date = opts[:date] do
        from o in query,
          where: fragment("DATE(?)", o.inserted_at) == ^date
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Returns today's orders for a vendor.
  """
  def list_todays_orders(vendor_id \\ nil) do
    today = TimezoneHelper.malaysian_today()
    list_vendor_orders(vendor_id, date: today)
  end

  @doc """
  Returns active orders (pending, preparing, ready) for a vendor.
  """
  def list_active_orders(vendor_id \\ nil) do
    query =
      from o in Order,
        where: o.status in ["pending", "preparing", "ready"],
        order_by: [asc: o.inserted_at],
        preload: [:cashier, :vendor, order_items: :menu_item]

    query =
      if vendor_id do
        from o in query, where: o.vendor_id == ^vendor_id
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Checks if all orders for a table are completed or cancelled.
  """
  def all_orders_completed_for_table?(table_number) do
    active_count =
      from(o in Order,
        where: o.table_number == ^to_string(table_number),
        where: o.status not in ["completed", "cancelled"],
        select: count(o.id)
      )
      |> Repo.one()

    active_count == 0
  end

  @doc """
  Lists all orders for a specific table number.
  """
  def list_orders_for_table(table_number) do
    from(o in Order,
      where: o.table_number == ^to_string(table_number),
      order_by: [asc: o.inserted_at],
      preload: [:vendor]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single order.
  """
  def get_order!(id) do
    Repo.get!(Order, id) |> Repo.preload([:vendor, :cashier, order_items: :menu_item])
  end

  @doc """
  Creates an order with order items.
  """
  def create_order_with_items(attrs, items) do
    Repo.transaction(fn ->
      # Create the order
      case create_order(attrs) do
        {:ok, order} ->
          # Create order items and calculate total
          total =
            Enum.reduce(items, Decimal.new("0"), fn item_attrs, acc ->
              menu_item = get_menu_item!(item_attrs["menu_item_id"] || item_attrs[:menu_item_id])

              item_attrs = Map.put(item_attrs, :order_id, order.id)

              case create_order_item(item_attrs, menu_item) do
                {:ok, order_item} ->
                  Decimal.add(acc, order_item.subtotal)

                {:error, changeset} ->
                  Repo.rollback(changeset)
              end
            end)

          # Update order with total
          case update_order_total(order, %{total_amount: total}) do
            {:ok, order} ->
              get_order!(order.id)

            {:error, changeset} ->
              Repo.rollback(changeset)
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Creates an order.
  """
  def create_order(attrs \\ %{}) do
    Repo.transaction(fn ->
      # Extract order items from attrs
      {order_items_attrs, order_attrs} = Map.pop(attrs, :order_items, [])

      # Create the order first
      case %Order{}
           |> Order.create_changeset(order_attrs)
           |> Repo.insert() do
        {:ok, order} ->
          # Calculate total from order items
          total =
            Enum.reduce(order_items_attrs, Decimal.new("0"), fn item_attrs, acc ->
              menu_item = get_menu_item!(item_attrs.menu_item_id)

              item_attrs =
                Map.merge(item_attrs, %{
                  order_id: order.id,
                  price: menu_item.price
                })

              case create_order_item(item_attrs, menu_item) do
                {:ok, order_item} ->
                  Decimal.add(acc, order_item.subtotal)

                {:error, changeset} ->
                  Repo.rollback(changeset)
              end
            end)

          # Update order with total
          case update_order_total(order, %{total_amount: total}) do
            {:ok, updated_order} ->
              # Broadcast the new order
              full_order = get_order!(updated_order.id)
              broadcast_order_update({:ok, full_order})
              full_order

            {:error, changeset} ->
              Repo.rollback(changeset)
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Updates an order status.
  """
  def update_order_status(%Order{} = order, attrs) do
    order
    |> Order.update_status_changeset(attrs)
    |> Repo.update()
    |> broadcast_order_update()
  end

  @doc """
  Marks an order as paid.
  """
  def mark_order_as_paid(%Order{} = order) do
    order
    |> Order.mark_as_paid_changeset()
    |> Repo.update()
    |> broadcast_order_update()
  end

  @doc """
  Updates an order total.
  """
  def update_order_total(%Order{} = order, attrs) do
    order
    |> Order.update_total_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.
  """
  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  # Order Item functions

  @doc """
  Creates an order_item.
  """
  def create_order_item(attrs, menu_item) do
    %OrderItem{}
    |> OrderItem.create_changeset(attrs, menu_item)
    |> Repo.insert()
  end

  @doc """
  Updates order item quantity.
  """
  def update_order_item_quantity(%OrderItem{} = order_item, attrs) do
    order_item
    |> OrderItem.update_quantity_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an order_item.
  """
  def delete_order_item(%OrderItem{} = order_item) do
    Repo.delete(order_item)
  end

  # Sales statistics

  @doc """
  Gets sales statistics for a vendor.
  """
  def get_vendor_sales_stats(vendor_id, date \\ nil) do
    # Use Malaysian date if not provided
    date = date || TimezoneHelper.malaysian_today()
    # Today's stats
    today_query =
      from o in Order,
        where: o.vendor_id == ^vendor_id,
        where: o.status == "completed",
        where: fragment("DATE(?)", o.inserted_at) == ^date,
        select: %{
          count: count(o.id),
          total: sum(o.total_amount) |> coalesce(0)
        }

    today_stats = Repo.one(today_query)

    # This month's stats
    start_of_month = Date.beginning_of_month(date)
    end_of_month = Date.end_of_month(date)

    month_query =
      from o in Order,
        where: o.vendor_id == ^vendor_id,
        where: o.status == "completed",
        where: fragment("DATE(?)", o.inserted_at) >= ^start_of_month,
        where: fragment("DATE(?)", o.inserted_at) <= ^end_of_month,
        select: %{
          count: count(o.id),
          total: sum(o.total_amount) |> coalesce(0)
        }

    month_stats = Repo.one(month_query)

    # Top selling items today
    top_items_query =
      from oi in OrderItem,
        join: o in Order,
        on: o.id == oi.order_id,
        join: mi in MenuItem,
        on: mi.id == oi.menu_item_id,
        where: o.vendor_id == ^vendor_id,
        where: o.status == "completed",
        where: fragment("DATE(?)", o.inserted_at) == ^date,
        group_by: [mi.id, mi.name],
        order_by: [desc: sum(oi.quantity)],
        limit: 5,
        select: %{
          name: mi.name,
          quantity: sum(oi.quantity),
          revenue: sum(oi.subtotal)
        }

    top_items = Repo.all(top_items_query)

    %{
      today: today_stats,
      month: month_stats,
      top_items: top_items
    }
  end

  # PubSub for real-time updates

  @doc """
  Subscribe to vendor order updates.
  """
  def subscribe_to_vendor_orders(vendor_id) do
    Phoenix.PubSub.subscribe(RiverSide.PubSub, "vendor_orders:#{vendor_id}")
  end

  @doc """
  Subscribe to all orders updates (for kitchen display).
  """
  def subscribe_to_all_orders do
    Phoenix.PubSub.subscribe(RiverSide.PubSub, "orders:all")
  end

  defp broadcast_order_update({:ok, order} = result) do
    order = get_order!(order.id)

    Phoenix.PubSub.broadcast(
      RiverSide.PubSub,
      "vendor_orders:#{order.vendor_id}",
      {:order_updated, order}
    )

    Phoenix.PubSub.broadcast(
      RiverSide.PubSub,
      "orders:all",
      {:order_updated, order}
    )

    Phoenix.PubSub.broadcast(
      RiverSide.PubSub,
      "order:#{order.id}",
      {:order_updated, order}
    )

    result
  end

  defp broadcast_order_update(error), do: error

  @doc """
  Subscribe to updates for a specific order.
  """
  def subscribe_to_order_updates(order_id) do
    Phoenix.PubSub.subscribe(RiverSide.PubSub, "order:#{order_id}")
  end

  @doc """
  List all orders for a customer by phone and table number.
  """
  def list_customer_orders(phone, table_number) do
    from(o in Order,
      where: o.customer_name == ^phone and o.table_number == ^to_string(table_number),
      order_by: [desc: o.inserted_at],
      preload: [:vendor, order_items: :menu_item]
    )
    |> Repo.all()
  end
end
