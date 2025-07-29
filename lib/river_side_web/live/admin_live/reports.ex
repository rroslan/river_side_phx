defmodule RiverSideWeb.AdminLive.Reports do
  use RiverSideWeb, :live_view

  alias RiverSide.Reports

  @impl true
  def mount(_params, _session, socket) do
    # Admin check is already done by the router's on_mount callback

    # Set default date range (last 7 days)
    end_date = Date.utc_today()
    start_date = Date.add(end_date, -6)

    {:ok,
     socket
     |> assign(:page_title, "System Reports")
     |> assign(:start_date, start_date)
     |> assign(:end_date, end_date)
     |> assign(:selected_period, "last_7_days")
     |> assign(:active_tab, "overview")
     |> load_reports()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200" id="reports-download-hook" phx-hook="ReportsDownload">
      <!-- Navigation -->
      <div class="navbar bg-base-300 shadow-lg">
        <div class="flex-1">
          <h1 class="text-2xl font-bold text-base-content px-4">System Reports</h1>
        </div>
        <div class="flex-none">
          <.link navigate={~p"/admin/dashboard"} class="btn btn-ghost btn-sm">
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

      <div class="container mx-auto p-6">
        <!-- Date Range Selector -->
        <div class="card bg-base-100 shadow-xl mb-6">
          <div class="card-body">
            <h2 class="card-title">Report Period</h2>
            <div class="flex flex-wrap gap-4 items-end">
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Quick Select</span>
                </label>
                <select
                  class="select select-bordered"
                  phx-change="change_period"
                  name="period"
                  value={@selected_period}
                >
                  <option value="today">Today</option>
                  <option value="yesterday">Yesterday</option>
                  <option value="last_7_days">Last 7 Days</option>
                  <option value="last_30_days">Last 30 Days</option>
                  <option value="this_month">This Month</option>
                  <option value="last_month">Last Month</option>
                  <option value="custom">Custom Range</option>
                </select>
              </div>

              <%= if @selected_period == "custom" do %>
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Start Date</span>
                  </label>
                  <input
                    type="date"
                    class="input input-bordered"
                    phx-change="change_start_date"
                    name="start_date"
                    value={@start_date}
                  />
                </div>
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">End Date</span>
                  </label>
                  <input
                    type="date"
                    class="input input-bordered"
                    phx-change="change_end_date"
                    name="end_date"
                    value={@end_date}
                  />
                </div>
              <% end %>

              <button phx-click="export_csv" class="btn btn-primary">
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
                    d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3"
                  />
                </svg>
                Export CSV
              </button>
            </div>
            <div class="text-sm text-base-content/60 mt-2">
              Showing data from {format_date(@start_date)} to {format_date(@end_date)}
            </div>
          </div>
        </div>
        
    <!-- Report Tabs -->
        <div class="tabs tabs-boxed mb-6">
          <button
            class={"tab #{if @active_tab == "overview", do: "tab-active"}"}
            phx-click="change_tab"
            phx-value-tab="overview"
          >
            Overview
          </button>
          <button
            class={"tab #{if @active_tab == "vendors", do: "tab-active"}"}
            phx-click="change_tab"
            phx-value-tab="vendors"
          >
            Vendor Performance
          </button>
          <button
            class={"tab #{if @active_tab == "items", do: "tab-active"}"}
            phx-click="change_tab"
            phx-value-tab="items"
          >
            Popular Items
          </button>
          <button
            class={"tab #{if @active_tab == "analytics", do: "tab-active"}"}
            phx-click="change_tab"
            phx-value-tab="analytics"
          >
            Analytics
          </button>
        </div>
        
    <!-- Report Content -->
        <%= case @active_tab do %>
          <% "overview" -> %>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
              <!-- Total Sales -->
              <div class="card bg-base-100 shadow-xl">
                <div class="card-body">
                  <h3 class="card-title text-sm">Total Sales</h3>
                  <div class="stat-value text-2xl text-success">
                    RM {format_currency(@summary.total_sales)}
                  </div>
                  <div class="text-xs text-base-content/60">
                    {format_number(@summary.order_count)} orders
                  </div>
                </div>
              </div>
              
    <!-- Average Order Value -->
              <div class="card bg-base-100 shadow-xl">
                <div class="card-body">
                  <h3 class="card-title text-sm">Average Order</h3>
                  <div class="stat-value text-2xl text-primary">
                    RM {format_currency(@summary.average_order_value)}
                  </div>
                  <div class="text-xs text-base-content/60">per order</div>
                </div>
              </div>
              
    <!-- Completed Orders -->
              <div class="card bg-base-100 shadow-xl">
                <div class="card-body">
                  <h3 class="card-title text-sm">Completed Orders</h3>
                  <div class="stat-value text-2xl text-info">
                    {format_number(@summary.completed_orders)}
                  </div>
                  <div class="text-xs text-base-content/60">
                    {calculate_percentage(@summary.completed_orders, @summary.order_count)}% completion
                    rate
                  </div>
                </div>
              </div>
              
    <!-- Payment Status -->
              <div class="card bg-base-100 shadow-xl">
                <div class="card-body">
                  <h3 class="card-title text-sm">Paid Orders</h3>
                  <div class="stat-value text-2xl text-warning">
                    {format_number(@summary.paid_orders)}
                  </div>
                  <div class="text-xs text-base-content/60">
                    {calculate_percentage(@summary.paid_orders, @summary.order_count)}% payment rate
                  </div>
                </div>
              </div>
            </div>
            
    <!-- Daily Sales Chart -->
            <div class="card bg-base-100 shadow-xl mb-6">
              <div class="card-body">
                <h3 class="card-title">Daily Sales Trend</h3>
                <div class="overflow-x-auto">
                  <table class="table table-sm">
                    <thead>
                      <tr>
                        <th>Date</th>
                        <th>Orders</th>
                        <th>Sales</th>
                        <th class="hidden sm:table-cell">Graph</th>
                      </tr>
                    </thead>
                    <tbody>
                      <%= for day <- @daily_sales do %>
                        <tr>
                          <td>{format_date(day.date)}</td>
                          <td>{day.order_count}</td>
                          <td class="font-semibold">RM {format_currency(day.total_sales)}</td>
                          <td class="hidden sm:table-cell">
                            <div class="w-full bg-base-200 rounded-full h-2">
                              <div
                                class="bg-primary h-2 rounded-full"
                                style={"width: #{calculate_bar_width(day.total_sales, @max_daily_sales)}%"}
                              >
                              </div>
                            </div>
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
            
    <!-- Payment Summary -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="card bg-base-100 shadow-xl">
                <div class="card-body">
                  <h3 class="card-title">Payment Status</h3>
                  <div class="space-y-4">
                    <div class="flex justify-between items-center">
                      <span>Paid Orders</span>
                      <span class="font-semibold text-success">
                        {format_number(@payment_summary.paid_orders)} (RM {format_currency(
                          @payment_summary.paid_amount
                        )})
                      </span>
                    </div>
                    <div class="flex justify-between items-center">
                      <span>Unpaid Orders</span>
                      <span class="font-semibold text-warning">
                        {format_number(@payment_summary.unpaid_orders)} (RM {format_currency(
                          @payment_summary.unpaid_amount
                        )})
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              <div class="card bg-base-100 shadow-xl">
                <div class="card-body">
                  <h3 class="card-title">Order Status Distribution</h3>
                  <div class="space-y-2">
                    <%= for status <- @order_status_distribution do %>
                      <div class="flex justify-between items-center">
                        <span class="capitalize">{status.status}</span>
                        <span class="badge badge-sm">{status.count}</span>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          <% "vendors" -> %>
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body">
                <h3 class="card-title mb-4">Vendor Performance Rankings</h3>
                <div class="overflow-x-auto">
                  <table class="table">
                    <thead>
                      <tr>
                        <th>Rank</th>
                        <th>Vendor</th>
                        <th>Orders</th>
                        <th>Completed</th>
                        <th>Total Sales</th>
                        <th>Avg. Order</th>
                        <th>Performance</th>
                      </tr>
                    </thead>
                    <tbody>
                      <%= for {vendor, index} <- Enum.with_index(@vendor_performance, 1) do %>
                        <tr class="hover">
                          <td>
                            <span class={"badge #{if index <= 3, do: "badge-primary"}"}>
                              #{index}
                            </span>
                          </td>
                          <td class="font-semibold">{vendor.vendor_name}</td>
                          <td>{vendor.order_count}</td>
                          <td>
                            <span class="text-success">
                              {vendor.completed_orders}
                            </span>
                            <span class="text-xs text-base-content/60">
                              ({calculate_percentage(vendor.completed_orders, vendor.order_count)}%)
                            </span>
                          </td>
                          <td class="font-bold">RM {format_currency(vendor.total_sales)}</td>
                          <td>RM {format_currency(vendor.average_order_value)}</td>
                          <td>
                            <div class="w-full bg-base-200 rounded-full h-2.5">
                              <div
                                class="bg-primary h-2.5 rounded-full"
                                style={"width: #{calculate_bar_width(vendor.total_sales, @max_vendor_sales)}%"}
                              >
                              </div>
                            </div>
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          <% "items" -> %>
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <!-- Top Selling Items -->
              <div class="card bg-base-100 shadow-xl">
                <div class="card-body">
                  <h3 class="card-title mb-4">Top Selling Items</h3>
                  <div class="overflow-x-auto">
                    <table class="table table-sm">
                      <thead>
                        <tr>
                          <th>#</th>
                          <th>Item</th>
                          <th>Vendor</th>
                          <th>Sold</th>
                          <th>Revenue</th>
                        </tr>
                      </thead>
                      <tbody>
                        <%= for {item, index} <- Enum.with_index(@popular_items, 1) do %>
                          <tr>
                            <td>{index}</td>
                            <td class="font-medium">{item.item_name}</td>
                            <td class="text-xs">{item.vendor_name}</td>
                            <td class="font-semibold">{item.quantity_sold}</td>
                            <td class="text-success">RM {format_currency(item.total_revenue)}</td>
                          </tr>
                        <% end %>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
              
    <!-- Category Performance -->
              <div class="card bg-base-100 shadow-xl">
                <div class="card-body">
                  <h3 class="card-title mb-4">Category Performance</h3>
                  <%= for category <- @category_performance do %>
                    <div class="mb-4">
                      <div class="flex justify-between items-center mb-2">
                        <span class="font-semibold capitalize">{category.category}</span>
                        <span class="text-sm text-base-content/60">
                          {category.quantity_sold} items sold
                        </span>
                      </div>
                      <div class="flex justify-between items-center">
                        <span class="text-success font-bold">
                          RM {format_currency(category.total_revenue)}
                        </span>
                        <span class="text-xs text-base-content/60">
                          {category.item_count} unique items
                        </span>
                      </div>
                      <div class="divider my-2"></div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          <% "analytics" -> %>
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <!-- Hourly Distribution -->
              <div class="card bg-base-100 shadow-xl">
                <div class="card-body">
                  <h3 class="card-title mb-4">Peak Hours Analysis</h3>
                  <div class="space-y-2">
                    <%= for hour <- @hourly_distribution do %>
                      <div>
                        <div class="flex justify-between items-center mb-1">
                          <span class="text-sm">{format_hour(hour.hour)}</span>
                          <span class="text-xs text-base-content/60">
                            {hour.order_count} orders
                          </span>
                        </div>
                        <div class="w-full bg-base-200 rounded-full h-2">
                          <div
                            class={"h-2 rounded-full #{peak_hour_color(hour.order_count, @max_hourly_orders)}"}
                            style={"width: #{calculate_bar_width(hour.order_count, @max_hourly_orders)}%"}
                          >
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
              
    <!-- Table Utilization -->
              <div class="card bg-base-100 shadow-xl">
                <div class="card-body">
                  <h3 class="card-title mb-4">Table Utilization</h3>
                  <div class="overflow-x-auto">
                    <table class="table table-sm">
                      <thead>
                        <tr>
                          <th>Table</th>
                          <th>Orders</th>
                          <th>Revenue</th>
                        </tr>
                      </thead>
                      <tbody>
                        <%= for table <- Enum.take(@table_utilization, 10) do %>
                          <tr>
                            <td>Table #{table.table_number}</td>
                            <td>{table.order_count}</td>
                            <td class="font-semibold">RM {format_currency(table.total_sales)}</td>
                          </tr>
                        <% end %>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("change_period", %{"period" => period}, socket) do
    {start_date, end_date} = calculate_date_range(period)

    {:noreply,
     socket
     |> assign(:selected_period, period)
     |> assign(:start_date, start_date)
     |> assign(:end_date, end_date)
     |> load_reports()}
  end

  @impl true
  def handle_event("change_start_date", %{"start_date" => date}, socket) do
    case Date.from_iso8601(date) do
      {:ok, start_date} ->
        {:noreply,
         socket
         |> assign(:start_date, start_date)
         |> load_reports()}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("change_end_date", %{"end_date" => date}, socket) do
    case Date.from_iso8601(date) do
      {:ok, end_date} ->
        {:noreply,
         socket
         |> assign(:end_date, end_date)
         |> load_reports()}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_event("export_csv", _params, socket) do
    csv_data = generate_csv_report(socket.assigns)

    {:noreply,
     push_event(socket, "download", %{
       filename:
         "river_side_report_#{Date.to_string(socket.assigns.start_date)}_to_#{Date.to_string(socket.assigns.end_date)}.csv",
       content: csv_data,
       type: "text/csv"
     })}
  end

  defp load_reports(socket) do
    start_datetime = DateTime.new!(socket.assigns.start_date, ~T[00:00:00], "Etc/UTC")
    end_datetime = DateTime.new!(socket.assigns.end_date, ~T[23:59:59], "Etc/UTC")

    # Load all report data
    summary = Reports.get_sales_summary(start_datetime, end_datetime)
    daily_sales = Reports.get_daily_sales(start_datetime, end_datetime)
    vendor_performance = Reports.get_vendor_performance(start_datetime, end_datetime)
    popular_items = Reports.get_popular_items(start_datetime, end_datetime)

    order_status_distribution =
      Reports.get_order_status_distribution(start_datetime, end_datetime)

    hourly_distribution = Reports.get_hourly_distribution(start_datetime, end_datetime)
    payment_summary = Reports.get_payment_summary(start_datetime, end_datetime)
    table_utilization = Reports.get_table_utilization(start_datetime, end_datetime)
    category_performance = Reports.get_category_performance(start_datetime, end_datetime)

    # Calculate max values for chart scaling
    max_daily_sales =
      daily_sales |> Enum.map(& &1.total_sales) |> Enum.max(&>=/2, fn -> Decimal.new("1") end)

    max_vendor_sales =
      vendor_performance
      |> Enum.map(& &1.total_sales)
      |> Enum.max(&>=/2, fn -> Decimal.new("1") end)

    max_hourly_orders =
      hourly_distribution |> Enum.map(& &1.order_count) |> Enum.max(&>=/2, fn -> 1 end)

    socket
    |> assign(:summary, summary)
    |> assign(:daily_sales, daily_sales)
    |> assign(:vendor_performance, vendor_performance)
    |> assign(:popular_items, popular_items)
    |> assign(:order_status_distribution, order_status_distribution)
    |> assign(:hourly_distribution, hourly_distribution)
    |> assign(:payment_summary, payment_summary)
    |> assign(:table_utilization, table_utilization)
    |> assign(:category_performance, category_performance)
    |> assign(:max_daily_sales, max_daily_sales)
    |> assign(:max_vendor_sales, max_vendor_sales)
    |> assign(:max_hourly_orders, max_hourly_orders)
  end

  defp calculate_date_range("today") do
    today = Date.utc_today()
    {today, today}
  end

  defp calculate_date_range("yesterday") do
    yesterday = Date.add(Date.utc_today(), -1)
    {yesterday, yesterday}
  end

  defp calculate_date_range("last_7_days") do
    end_date = Date.utc_today()
    start_date = Date.add(end_date, -6)
    {start_date, end_date}
  end

  defp calculate_date_range("last_30_days") do
    end_date = Date.utc_today()
    start_date = Date.add(end_date, -29)
    {start_date, end_date}
  end

  defp calculate_date_range("this_month") do
    today = Date.utc_today()
    start_date = Date.beginning_of_month(today)
    {start_date, today}
  end

  defp calculate_date_range("last_month") do
    today = Date.utc_today()
    last_month = Date.beginning_of_month(today) |> Date.add(-1)
    start_date = Date.beginning_of_month(last_month)
    end_date = Date.end_of_month(last_month)
    {start_date, end_date}
  end

  defp calculate_date_range(_), do: calculate_date_range("last_7_days")

  defp format_currency(%Decimal{} = amount), do: Decimal.to_string(Decimal.round(amount, 2))
  defp format_currency(_), do: "0.00"

  defp format_number(nil), do: "0"
  defp format_number(num) when is_integer(num), do: Integer.to_string(num)
  defp format_number(num), do: to_string(num)

  defp format_date(date) when is_binary(date), do: date
  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%d %b")
  defp format_date(_), do: ""

  defp format_hour(hour) when is_float(hour), do: format_hour(trunc(hour))
  defp format_hour(hour) when hour < 12, do: "#{hour}:00 AM"
  defp format_hour(12), do: "12:00 PM"
  defp format_hour(hour), do: "#{hour - 12}:00 PM"

  defp calculate_percentage(0, 0), do: 0
  defp calculate_percentage(_, 0), do: 0
  defp calculate_percentage(part, total), do: round(part / total * 100)

  defp calculate_bar_width(%Decimal{} = value, %Decimal{} = max) do
    if Decimal.compare(max, Decimal.new("0")) == :gt do
      value
      |> Decimal.div(max)
      |> Decimal.mult(Decimal.new("100"))
      |> Decimal.to_float()
      |> round()
    else
      0
    end
  end

  defp calculate_bar_width(value, max) when max > 0, do: round(value / max * 100)
  defp calculate_bar_width(_, _), do: 0

  defp peak_hour_color(count, max) when max > 0 do
    percentage = count / max * 100

    cond do
      percentage >= 80 -> "bg-error"
      percentage >= 60 -> "bg-warning"
      percentage >= 40 -> "bg-primary"
      true -> "bg-info"
    end
  end

  defp peak_hour_color(_, _), do: "bg-info"

  defp generate_csv_report(assigns) do
    # Generate CSV based on active tab
    case assigns.active_tab do
      "overview" ->
        headers = ["Date", "Orders", "Sales"]

        data =
          Enum.map(assigns.daily_sales, fn day ->
            %{
              "Date" => format_date(day.date),
              "Orders" => day.order_count,
              "Sales" => format_currency(day.total_sales)
            }
          end)

        {:ok, csv} = Reports.export_to_csv(data, headers)
        csv

      "vendors" ->
        headers = ["Vendor", "Orders", "Completed", "Total Sales", "Average Order"]

        data =
          Enum.map(assigns.vendor_performance, fn vendor ->
            %{
              "Vendor" => vendor.vendor_name,
              "Orders" => vendor.order_count,
              "Completed" => vendor.completed_orders,
              "Total Sales" => format_currency(vendor.total_sales),
              "Average Order" => format_currency(vendor.average_order_value)
            }
          end)

        {:ok, csv} = Reports.export_to_csv(data, headers)
        csv

      "items" ->
        headers = ["Item", "Vendor", "Quantity Sold", "Revenue"]

        data =
          Enum.map(assigns.popular_items, fn item ->
            %{
              "Item" => item.item_name,
              "Vendor" => item.vendor_name,
              "Quantity Sold" => item.quantity_sold,
              "Revenue" => format_currency(item.total_revenue)
            }
          end)

        {:ok, csv} = Reports.export_to_csv(data, headers)
        csv

      _ ->
        # Default to summary report
        "Report Type,Value\n" <>
          "Total Sales,RM #{format_currency(assigns.summary.total_sales)}\n" <>
          "Total Orders,#{assigns.summary.order_count}\n" <>
          "Average Order Value,RM #{format_currency(assigns.summary.average_order_value)}\n" <>
          "Completed Orders,#{assigns.summary.completed_orders}\n" <>
          "Paid Orders,#{assigns.summary.paid_orders}\n"
    end
  end
end
