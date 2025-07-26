defmodule RiverSideWeb.CustomerLive.Checkin do
  use RiverSideWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="navbar bg-base-300 shadow-lg">
        <div class="flex-1">
          <h1 class="text-2xl font-bold text-base-content px-4">River Side Food Court</h1>
        </div>
        <div class="flex-none">
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
                d="M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18"
              />
            </svg>
            Back
          </.link>
        </div>
      </div>

      <div class="container mx-auto p-6 max-w-md">
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title text-3xl justify-center mb-2">Welcome!</h2>
            <p class="text-center text-base-content/70 mb-6">
              Table #{@table_number}
            </p>

            <.form for={@form} phx-submit="submit_checkin" phx-change="validate">
              <div class="form-control w-full">
                <label class="label">
                  <span class="label-text">Phone Number</span>
                  <span class="label-text-alt text-error">*Required</span>
                </label>
                <.input
                  field={@form[:phone]}
                  type="tel"
                  placeholder="012-3456789"
                  class="input input-bordered w-full"
                  required
                />
              </div>

              <div class="form-control w-full mt-4">
                <label class="label">
                  <span class="label-text">Name</span>
                  <span class="label-text-alt">Optional</span>
                </label>
                <.input
                  field={@form[:name]}
                  type="text"
                  placeholder="Your name"
                  class="input input-bordered w-full"
                />
              </div>

              <div class="form-actions mt-6">
                <button
                  type="submit"
                  class="btn btn-primary btn-block"
                  phx-disable-with="Processing..."
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
                      d="M3.75 3v11.25A2.25 2.25 0 006 16.5h2.25M3.75 3h-1.5m1.5 0h16.5m0 0h1.5m-1.5 0v11.25A2.25 2.25 0 0118 16.5h-2.25m-7.5 0h7.5m-7.5 0l-1 3m8.5-3l1 3m0 0l.5 1.5m-.5-1.5h-9.5m0 0l-.5 1.5m.75-9l3-3 2.148 2.148A12.061 12.061 0 0116.5 7.605"
                    />
                  </svg>
                  See Menu
                </button>
              </div>
            </.form>
          </div>
        </div>

        <div class="mt-6 text-center">
          <p class="text-sm text-base-content/60">
            Your information will only be used for this order
          </p>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"table_number" => table_number}, _session, socket) do
    form =
      to_form(%{
        "phone" => "",
        "name" => "",
        "table_number" => table_number
      })

    {:ok,
     socket
     |> assign(table_number: table_number)
     |> assign(form: form)}
  end

  @impl true
  def handle_event("validate", %{"phone" => phone, "name" => name}, socket) do
    form =
      to_form(%{
        "phone" => phone,
        "name" => name,
        "table_number" => socket.assigns.table_number
      })

    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("submit_checkin", %{"phone" => phone, "name" => name}, socket) do
    # Redirect to menu with customer info in URL parameters
    {:noreply,
     socket
     |> push_navigate(
       to:
         ~p"/customer/menu?phone=#{URI.encode(phone)}&name=#{URI.encode(name || "")}&table=#{socket.assigns.table_number}"
     )}
  end
end
