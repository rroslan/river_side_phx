defmodule RiverSide.Reports do
  @moduledoc """
  The Reports context for generating system reports and analytics.
  """

  import Ecto.Query, warn: false
  alias RiverSide.Repo
  alias RiverSide.Vendors.{Order, OrderItem, Vendor, MenuItem}

  @doc """
  Get sales summary for a given date range.
  Returns total sales, order count, and average order value.
  """
  def get_sales_summary(start_date, end_date) do
    query =
      from o in Order,
        where: o.inserted_at >= ^start_date and o.inserted_at <= ^end_date,
        where: o.status != "cancelled",
        select: %{
          total_sales: sum(o.total_amount),
          order_count: count(o.id),
          paid_orders: sum(fragment("CASE WHEN ? THEN 1 ELSE 0 END", o.paid)),
          completed_orders: sum(fragment("CASE WHEN ? = 'completed' THEN 1 ELSE 0 END", o.status))
        }

    result = Repo.one(query) || %{}

    total_sales = result.total_sales || Decimal.new("0")
    order_count = result.order_count || 0

    avg_order_value =
      if order_count > 0, do: Decimal.div(total_sales, order_count), else: Decimal.new("0")

    %{
      total_sales: total_sales,
      order_count: order_count,
      paid_orders: result.paid_orders || 0,
      completed_orders: result.completed_orders || 0,
      average_order_value: avg_order_value
    }
  end

  @doc """
  Get daily sales for a date range.
  Returns sales grouped by day.
  """
  def get_daily_sales(start_date, end_date) do
    query =
      from o in Order,
        where: o.inserted_at >= ^start_date and o.inserted_at <= ^end_date,
        where: o.status != "cancelled",
        group_by: fragment("DATE(?)", o.inserted_at),
        select: %{
          date: fragment("DATE(?)", o.inserted_at),
          total_sales: sum(o.total_amount),
          order_count: count(o.id)
        },
        order_by: fragment("DATE(?)", o.inserted_at)

    Repo.all(query)
  end

  @doc """
  Get vendor performance metrics for a date range.
  """
  def get_vendor_performance(start_date, end_date) do
    query =
      from o in Order,
        join: v in Vendor,
        on: o.vendor_id == v.id,
        where: o.inserted_at >= ^start_date and o.inserted_at <= ^end_date,
        where: o.status != "cancelled",
        group_by: [v.id, v.name],
        select: %{
          vendor_id: v.id,
          vendor_name: v.name,
          total_sales: sum(o.total_amount),
          order_count: count(o.id),
          completed_orders:
            sum(fragment("CASE WHEN ? = 'completed' THEN 1 ELSE 0 END", o.status)),
          average_order_value: fragment("ROUND(AVG(?), 2)", o.total_amount)
        },
        order_by: [desc: sum(o.total_amount)]

    Repo.all(query)
  end

  @doc """
  Get popular menu items for a date range.
  """
  def get_popular_items(start_date, end_date, limit \\ 10) do
    query =
      from oi in OrderItem,
        join: o in Order,
        on: oi.order_id == o.id,
        join: mi in MenuItem,
        on: oi.menu_item_id == mi.id,
        join: v in Vendor,
        on: mi.vendor_id == v.id,
        where: o.inserted_at >= ^start_date and o.inserted_at <= ^end_date,
        where: o.status != "cancelled",
        group_by: [mi.id, mi.name, v.name, mi.price],
        select: %{
          item_id: mi.id,
          item_name: mi.name,
          vendor_name: v.name,
          unit_price: mi.price,
          quantity_sold: sum(oi.quantity),
          total_revenue: sum(oi.subtotal)
        },
        order_by: [desc: sum(oi.quantity)],
        limit: ^limit

    Repo.all(query)
  end

  @doc """
  Get order status distribution for a date range.
  """
  def get_order_status_distribution(start_date, end_date) do
    query =
      from o in Order,
        where: o.inserted_at >= ^start_date and o.inserted_at <= ^end_date,
        group_by: o.status,
        select: %{
          status: o.status,
          count: count(o.id)
        }

    Repo.all(query)
  end

  @doc """
  Get hourly order distribution for a date range.
  """
  def get_hourly_distribution(start_date, end_date) do
    query =
      from o in Order,
        where: o.inserted_at >= ^start_date and o.inserted_at <= ^end_date,
        where: o.status != "cancelled",
        group_by: fragment("EXTRACT(HOUR FROM ?)", o.inserted_at),
        select: %{
          hour: fragment("EXTRACT(HOUR FROM ?)", o.inserted_at),
          order_count: count(o.id),
          total_sales: sum(o.total_amount)
        },
        order_by: fragment("EXTRACT(HOUR FROM ?)", o.inserted_at)

    Repo.all(query)
  end

  @doc """
  Get payment status summary for a date range.
  """
  def get_payment_summary(start_date, end_date) do
    query =
      from o in Order,
        where: o.inserted_at >= ^start_date and o.inserted_at <= ^end_date,
        where: o.status != "cancelled",
        select: %{
          total_orders: count(o.id),
          paid_orders: sum(fragment("CASE WHEN ? THEN 1 ELSE 0 END", o.paid)),
          unpaid_orders: sum(fragment("CASE WHEN NOT ? THEN 1 ELSE 0 END", o.paid)),
          paid_amount: sum(fragment("CASE WHEN ? THEN ? ELSE 0 END", o.paid, o.total_amount)),
          unpaid_amount:
            sum(fragment("CASE WHEN NOT ? THEN ? ELSE 0 END", o.paid, o.total_amount))
        }

    result = Repo.one(query) || %{}

    %{
      total_orders: result.total_orders || 0,
      paid_orders: result.paid_orders || 0,
      unpaid_orders: result.unpaid_orders || 0,
      paid_amount: result.paid_amount || Decimal.new("0"),
      unpaid_amount: result.unpaid_amount || Decimal.new("0")
    }
  end

  @doc """
  Get table utilization for a date range.
  """
  def get_table_utilization(start_date, end_date) do
    query =
      from o in Order,
        where: o.inserted_at >= ^start_date and o.inserted_at <= ^end_date,
        where: o.status != "cancelled",
        group_by: o.table_number,
        select: %{
          table_number: o.table_number,
          order_count: count(o.id),
          total_sales: sum(o.total_amount)
        },
        order_by: [desc: count(o.id)]

    Repo.all(query)
  end

  @doc """
  Get category performance (food vs drinks).
  """
  def get_category_performance(start_date, end_date) do
    query =
      from oi in OrderItem,
        join: o in Order,
        on: oi.order_id == o.id,
        join: mi in MenuItem,
        on: oi.menu_item_id == mi.id,
        where: o.inserted_at >= ^start_date and o.inserted_at <= ^end_date,
        where: o.status != "cancelled",
        group_by: mi.category,
        select: %{
          category: mi.category,
          quantity_sold: sum(oi.quantity),
          total_revenue: sum(oi.subtotal),
          item_count: fragment("COUNT(DISTINCT ?)", mi.id)
        }

    Repo.all(query)
  end

  @doc """
  Export report data to CSV format.
  """
  def export_to_csv(data, headers) when is_list(data) and is_list(headers) do
    csv_data =
      [
        headers
        | Enum.map(data, fn row ->
            Enum.map(headers, fn header ->
              value = Map.get(row, String.to_atom(header), "")
              format_csv_value(value)
            end)
          end)
      ]
      |> Enum.map(fn row ->
        row
        |> Enum.map(&escape_csv_field/1)
        |> Enum.join(",")
      end)
      |> Enum.join("\n")

    {:ok, csv_data}
  end

  defp escape_csv_field(field) when is_binary(field) do
    if String.contains?(field, [",", "\"", "\n"]) do
      "\"" <> String.replace(field, "\"", "\"\"") <> "\""
    else
      field
    end
  end

  defp escape_csv_field(field), do: to_string(field)

  defp format_csv_value(%Decimal{} = value), do: Decimal.to_string(value)
  defp format_csv_value(%Date{} = value), do: Date.to_string(value)
  defp format_csv_value(%DateTime{} = value), do: DateTime.to_string(value)
  defp format_csv_value(value) when is_binary(value), do: value
  defp format_csv_value(value), do: to_string(value)

  @doc """
  Get comparison data between two periods.
  """
  def get_period_comparison(current_start, current_end, previous_start, previous_end) do
    current = get_sales_summary(current_start, current_end)
    previous = get_sales_summary(previous_start, previous_end)

    %{
      current: current,
      previous: previous,
      growth: calculate_growth(current, previous)
    }
  end

  defp calculate_growth(current, previous) do
    %{
      sales_growth: calculate_percentage_change(current.total_sales, previous.total_sales),
      order_growth: calculate_percentage_change(current.order_count, previous.order_count),
      avg_order_growth:
        calculate_percentage_change(current.average_order_value, previous.average_order_value)
    }
  end

  defp calculate_percentage_change(current, previous) when is_number(previous) and previous > 0 do
    Float.round((current - previous) / previous * 100, 2)
  end

  defp calculate_percentage_change(%Decimal{} = current, %Decimal{} = previous) do
    if Decimal.compare(previous, Decimal.new("0")) == :gt do
      current
      |> Decimal.sub(previous)
      |> Decimal.div(previous)
      |> Decimal.mult(Decimal.new("100"))
      |> Decimal.round(2)
      |> Decimal.to_float()
    else
      0.0
    end
  end

  defp calculate_percentage_change(_, _), do: 0.0
end
