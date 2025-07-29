defmodule RiverSideWeb.TableLive.Index do
  use RiverSideWeb, :live_view

  alias RiverSide.Tables

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="navbar bg-base-300 shadow-lg">
        <div class="flex-1">
          <h1 class="text-2xl font-bold text-base-content px-4">River Side Food Court</h1>
        </div>
        <div class="flex-none gap-2">
          <%= if @current_scope && @current_scope.user.is_admin do %>
            <button phx-click="reset_tables" class="btn btn-warning btn-sm">
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
                  d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182m0-4.991v4.99"
                />
              </svg>
              Reset All Tables
            </button>
          <% end %>
          <%= if @current_scope do %>
            <div class="dropdown dropdown-end">
              <label tabindex="0" class="btn btn-ghost btn-circle avatar">
                <div class="w-10 rounded-full bg-primary text-primary-content flex items-center justify-center">
                  <span class="text-xl font-semibold">
                    {String.first(@current_scope.user.email) |> String.upcase()}
                  </span>
                </div>
              </label>
              <ul
                tabindex="0"
                class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow-2xl bg-base-100 rounded-box w-52"
              >
                <li class="menu-title">
                  <span>{@current_scope.user.email}</span>
                </li>
                <li>
                  <div class="divider my-0"></div>
                </li>
                <%= if @current_scope.user.is_admin do %>
                  <li>
                    <.link href={~p"/admin/dashboard"} class="gap-3">
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
                          d="M3.75 3v11.25A2.25 2.25 0 006 16.5h2.25M3.75 3h-1.5m1.5 0h16.5m0 0h1.5m-1.5 0v11.25A2.25 2.25 0 0118 16.5h-2.25m-7.5 0h7.5m-7.5 0l-1 3m8.5-3l1 3m0 0l.5 1.5m-.5-1.5h-9.5m0 0l-.5 1.5M9 11.25v1.5M12 9v3.75m3-6v6"
                        />
                      </svg>
                      Admin Dashboard
                    </.link>
                  </li>
                <% end %>
                <%= if @current_scope.user.is_vendor do %>
                  <li>
                    <.link href={~p"/vendor/dashboard"} class="gap-3">
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
                          d="M13.5 21v-7.5a.75.75 0 01.75-.75h3a.75.75 0 01.75.75V21m-4.5 0H2.36m11.14 0H18m0 0h3.64m-1.39 0V9.349m-16.5 11.65V9.35m0 0a3.001 3.001 0 003.75-.615A2.993 2.993 0 009.75 9.75c.896 0 1.7-.393 2.25-1.016a2.993 2.993 0 002.25 1.016c.896 0 1.7-.393 2.25-1.016a3.001 3.001 0 003.75.614m-16.5 0a3.004 3.004 0 01-.621-4.72L4.318 3.44A1.5 1.5 0 015.378 3h13.243a1.5 1.5 0 011.06.44l1.19 1.189a3 3 0 01-.621 4.72m-13.5 8.65h3.75a.75.75 0 00.75-.75V13.5a.75.75 0 00-.75-.75H6.75a.75.75 0 00-.75.75v3.75c0 .415.336.75.75.75z"
                        />
                      </svg>
                      Vendor Dashboard
                    </.link>
                  </li>
                <% end %>
                <li>
                  <.link href={~p"/users/settings"} class="gap-3">
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
                        d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z"
                      />
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                      />
                    </svg>
                    Settings
                  </.link>
                </li>
                <li>
                  <div class="divider my-0"></div>
                </li>
                <li>
                  <.link href={~p"/users/log-out"} method="delete" class="gap-3">
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
                        d="M15.75 9V5.25A2.25 2.25 0 0013.5 3h-6a2.25 2.25 0 00-2.25 2.25v13.5A2.25 2.25 0 007.5 21h6a2.25 2.25 0 002.25-2.25V15m3 0l3-3m0 0l-3-3m3 3H9"
                      />
                    </svg>
                    Log out
                  </.link>
                </li>
              </ul>
            </div>
          <% else %>
            <.link href={~p"/users/log-in"} class="btn btn-primary">Staff</.link>
          <% end %>
        </div>
      </div>

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

        <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-6">
          <%= for table_number <- 1..20 do %>
            <div
              id={"table-#{table_number}"}
              phx-click="select_table"
              phx-value-number={table_number}
              class={[
                "card bg-base-100 shadow-xl cursor-pointer transition-all duration-200 hover:scale-105",
                table_status_class(@tables[table_number])
              ]}
            >
              <div class="card-body items-center text-center p-6">
                <h2 class="card-title text-2xl">Table {table_number}</h2>
                <div class="mt-2">
                  <span class={[
                    "badge badge-lg",
                    table_badge_class(@tables[table_number])
                  ]}>
                    {table_status_text(@tables[table_number])}
                  </span>
                </div>
                <%= if @tables[table_number] && @tables[table_number].occupied do %>
                  <div class="text-sm opacity-70 mt-2">
                    {time_elapsed(@tables[table_number].occupied_at)}
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>

        <div class="stats shadow bg-base-100 mt-8">
          <div class="stat">
            <div class="stat-figure text-success">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="inline-block w-8 h-8 stroke-current"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                >
                </path>
              </svg>
            </div>
            <div class="stat-title">Available Tables</div>
            <div class="stat-value text-success">{count_available_tables(@tables)}</div>
          </div>

          <div class="stat">
            <div class="stat-figure text-warning">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="inline-block w-8 h-8 stroke-current"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                >
                </path>
              </svg>
            </div>
            <div class="stat-title">Occupied Tables</div>
            <div class="stat-value text-warning">{count_occupied_tables(@tables)}</div>
          </div>

          <div class="stat">
            <div class="stat-figure text-info">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="inline-block w-8 h-8 stroke-current"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 10V3L4 14h7v7l9-11h-7z"
                >
                </path>
              </svg>
            </div>
            <div class="stat-title">Total Tables</div>
            <div class="stat-value">20</div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # Check if user should be redirected based on their role
    if socket.assigns[:current_scope] && socket.assigns.current_scope.user do
      user = socket.assigns.current_scope.user

      cond do
        user.is_admin ->
          {:ok, push_navigate(socket, to: ~p"/admin/dashboard")}

        user.is_vendor ->
          {:ok, push_navigate(socket, to: ~p"/vendor/dashboard")}

        user.is_cashier ->
          {:ok, push_navigate(socket, to: ~p"/cashier/dashboard")}

        true ->
          # Regular user, show tables
          mount_tables(socket)
      end
    else
      # Not logged in, show tables
      mount_tables(socket)
    end
  end

  defp mount_tables(socket) do
    # Subscribe to table updates
    if connected?(socket) do
      Tables.subscribe()
      :timer.send_interval(1000, self(), :tick)
    end

    # Get real table data from database
    tables_list = Tables.list_tables()

    # Convert to map format expected by the view
    tables =
      tables_list
      |> Enum.map(fn table ->
        {table.number,
         %{
           id: table.id,
           occupied: table.status == "occupied",
           occupied_at: table.occupied_at,
           customer_phone: table.customer_phone
         }}
      end)
      |> Map.new()

    {:ok, assign(socket, tables: tables)}
  end

  @impl true
  def handle_info(:tick, socket) do
    # Update the view to refresh time displays
    {:noreply, socket}
  end

  @impl true
  def handle_info({:table_updated, table}, socket) do
    # Update the specific table in our map
    updated_tables =
      Map.put(socket.assigns.tables, table.number, %{
        id: table.id,
        occupied: table.status == "occupied",
        occupied_at: table.occupied_at,
        customer_phone: table.customer_phone
      })

    {:noreply, assign(socket, tables: updated_tables)}
  end

  @impl true
  def handle_info(:tables_reset, socket) do
    # Reload all tables after reset
    mount_tables(socket)
  end

  @impl true
  def handle_event("select_table", %{"number" => table_number}, socket) do
    table_num = String.to_integer(table_number)
    table_info = socket.assigns.tables[table_num]

    # Check if table is already occupied
    if table_info && table_info.occupied do
      {:noreply, put_flash(socket, :error, "This table is already occupied")}
    else
      # Redirect to customer check-in page
      {:noreply, push_navigate(socket, to: ~p"/customer/checkin/#{table_num}")}
    end
  end

  @impl true
  def handle_event("reset_tables", _params, socket) do
    # Reset all tables in database
    Tables.reset_all_tables()
    {:noreply, put_flash(socket, :info, "All tables have been reset")}
  end

  defp table_status_class(nil), do: ""
  defp table_status_class(%{occupied: true}), do: "ring-2 ring-warning"
  defp table_status_class(%{occupied: false}), do: "ring-2 ring-success"

  defp table_badge_class(nil), do: "badge-success"
  defp table_badge_class(%{occupied: true}), do: "badge-warning"
  defp table_badge_class(%{occupied: false}), do: "badge-success"

  defp table_status_text(nil), do: "Available"
  defp table_status_text(%{occupied: true}), do: "Occupied"
  defp table_status_text(%{occupied: false}), do: "Available"

  defp count_available_tables(tables) do
    Enum.count(tables, fn {_, table} -> !table.occupied end)
  end

  defp count_occupied_tables(tables) do
    Enum.count(tables, fn {_, table} -> table.occupied end)
  end

  defp time_elapsed(nil), do: ""

  defp time_elapsed(occupied_at) do
    seconds = DateTime.diff(DateTime.utc_now(), occupied_at)

    cond do
      seconds < 60 -> "#{seconds}s ago"
      seconds < 3600 -> "#{div(seconds, 60)}m ago"
      true -> "#{div(seconds, 3600)}h #{rem(div(seconds, 60), 60)}m ago"
    end
  end
end
