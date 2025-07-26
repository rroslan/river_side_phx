defmodule RiverSideWeb.VendorLive.MenuItemForm do
  use RiverSideWeb, :live_view

  alias RiverSide.Vendors
  alias RiverSide.Vendors.MenuItem

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="navbar bg-base-300 shadow-lg">
        <div class="flex-1">
          <h1 class="text-2xl font-bold text-base-content px-4">
            {if @live_action == :new, do: "Add Menu Item", else: "Edit Menu Item"}
          </h1>
        </div>
        <div class="flex-none">
          <.link href={~p"/vendor/dashboard"} class="btn btn-ghost">
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

      <div class="container mx-auto p-6 max-w-2xl">
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <.form for={@form} phx-submit="save" phx-change="validate">
              <div class="form-control w-full">
                <label class="label">
                  <span class="label-text">Name</span>
                </label>
                <.input
                  field={@form[:name]}
                  type="text"
                  class="input input-bordered w-full"
                  placeholder="e.g., Nasi Lemak Special"
                  required
                />
              </div>

              <div class="form-control w-full mt-4">
                <label class="label">
                  <span class="label-text">Description</span>
                </label>
                <.input
                  field={@form[:description]}
                  type="textarea"
                  class="textarea textarea-bordered w-full"
                  placeholder="Describe your dish..."
                  rows="3"
                />
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
                <div class="form-control w-full">
                  <label class="label">
                    <span class="label-text">Price (RM)</span>
                  </label>
                  <.input
                    field={@form[:price]}
                    type="number"
                    step="0.01"
                    min="0"
                    class="input input-bordered w-full"
                    placeholder="0.00"
                    required
                  />
                </div>

                <div class="form-control w-full">
                  <label class="label">
                    <span class="label-text">Category</span>
                  </label>
                  <.input
                    field={@form[:category]}
                    type="select"
                    class="select select-bordered w-full"
                    options={[
                      {"Select category", ""},
                      {"Food", "food"},
                      {"Drinks", "drinks"}
                    ]}
                    required
                  />
                </div>
              </div>

              <div class="form-control w-full mt-4">
                <label class="label">
                  <span class="label-text">Image Upload</span>
                </label>
                
    <!-- Current Image -->
                <%= if @menu_item.image_url do %>
                  <div class="mb-4">
                    <p class="text-sm text-base-content/70 mb-2">Current image:</p>
                    <img
                      src={@menu_item.image_url}
                      alt="Current menu item image"
                      class="w-32 h-32 object-cover rounded-lg"
                    />
                  </div>
                <% end %>
                
    <!-- Upload Section -->
                <div class="space-y-4">
                  <div
                    class="border-2 border-dashed border-base-300 rounded-lg p-6 text-center hover:border-primary transition-colors cursor-pointer"
                    phx-drop-target={@uploads.image.ref}
                  >
                    <label for={@uploads.image.ref} class="cursor-pointer">
                      <svg
                        class="mx-auto h-12 w-12 text-base-content/50"
                        stroke="currentColor"
                        fill="none"
                        viewBox="0 0 48 48"
                        aria-hidden="true"
                      >
                        <path
                          d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                        />
                      </svg>
                      <p class="mt-2 text-sm">
                        <span class="font-medium text-primary">Click to upload</span> or drag and drop
                      </p>
                      <p class="text-xs text-base-content/50">PNG, JPG, GIF up to 10MB</p>
                      <.live_file_input upload={@uploads.image} class="hidden" />
                    </label>
                  </div>
                  
    <!-- Upload Preview -->
                  <%= for entry <- @uploads.image.entries do %>
                    <div class="border rounded-lg p-4 flex items-center gap-4">
                      <div class="relative">
                        <.live_img_preview entry={entry} class="w-20 h-20 object-cover rounded" />
                        <%= if entry.progress > 0 and entry.progress < 100 do %>
                          <div class="absolute inset-0 bg-black/50 rounded flex items-center justify-center">
                            <span class="text-white text-sm font-bold">{entry.progress}%</span>
                          </div>
                        <% end %>
                      </div>
                      <div class="flex-1">
                        <p class="font-medium">{entry.client_name}</p>
                        <p class="text-sm text-base-content/70">
                          {Float.round(entry.client_size / 1_000_000, 2)} MB
                        </p>
                        <!-- Upload errors -->
                        <%= for err <- upload_errors(@uploads.image, entry) do %>
                          <p class="text-error text-sm mt-1">{humanize_error(err)}</p>
                        <% end %>
                      </div>
                      <button
                        type="button"
                        phx-click="cancel-upload"
                        phx-value-ref={entry.ref}
                        class="btn btn-ghost btn-sm btn-circle"
                      >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M6 18L18 6M6 6l12 12"
                          />
                        </svg>
                      </button>
                    </div>
                  <% end %>
                  
    <!-- General upload errors -->
                  <%= for err <- upload_errors(@uploads.image) do %>
                    <div class="alert alert-error">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="stroke-current shrink-0 h-6 w-6"
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
                      <span>{humanize_error(err)}</span>
                    </div>
                  <% end %>
                </div>
              </div>

              <div class="form-control mt-4">
                <label class="label cursor-pointer">
                  <span class="label-text">Available for ordering</span>
                  <.input
                    field={@form[:is_available]}
                    type="checkbox"
                    class="checkbox checkbox-success"
                  />
                </label>
              </div>

              <div class="form-actions mt-6 flex gap-2">
                <button type="submit" class="btn btn-primary" phx-disable-with="Saving...">
                  {if @live_action == :new, do: "Create Item", else: "Update Item"}
                </button>
                <.link href={~p"/vendor/dashboard"} class="btn btn-ghost">
                  Cancel
                </.link>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    if socket.assigns.current_scope.user.is_vendor do
      vendor = Vendors.get_vendor_by_user_id(socket.assigns.current_scope.user.id)

      if vendor do
        {:ok,
         socket |> assign(vendor: vendor) |> apply_action(socket.assigns.live_action, params)}
      else
        {:ok,
         socket
         |> put_flash(:error, "Vendor profile not found")
         |> push_navigate(to: ~p"/vendor/dashboard")}
      end
    else
      {:ok,
       socket
       |> put_flash(:error, "You are not authorized to access this page")
       |> push_navigate(to: ~p"/")}
    end
  end

  defp apply_action(socket, :new, _params) do
    changeset = Vendors.change_menu_item(%MenuItem{}, %{vendor_id: socket.assigns.vendor.id})

    socket
    |> assign(:menu_item, %MenuItem{})
    |> assign(:form, to_form(changeset))
    |> allow_upload(:image,
      accept: ~w(.jpg .jpeg .png .gif),
      max_entries: 1,
      max_file_size: 10_000_000
    )
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    menu_item = Vendors.get_menu_item!(id)

    if menu_item.vendor_id == socket.assigns.vendor.id do
      changeset = Vendors.change_menu_item(menu_item)

      socket
      |> assign(:menu_item, menu_item)
      |> assign(:form, to_form(changeset))
      |> allow_upload(:image,
        accept: ~w(.jpg .jpeg .png .gif),
        max_entries: 1,
        max_file_size: 10_000_000
      )
    else
      socket
      |> put_flash(:error, "You are not authorized to edit this item")
      |> push_navigate(to: ~p"/vendor/dashboard")
    end
  end

  @impl true
  def handle_event("validate", %{"menu_item" => menu_item_params}, socket) do
    changeset =
      socket.assigns.menu_item
      |> Vendors.change_menu_item(menu_item_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  @impl true
  def handle_event("save", %{"menu_item" => menu_item_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
        dest = Path.join([:code.priv_dir(:river_side), "static", "uploads", entry.client_name])
        File.cp!(path, dest)
        {:ok, ~p"/uploads/#{entry.client_name}"}
      end)

    menu_item_params =
      case uploaded_files do
        [image_url | _] -> Map.put(menu_item_params, "image_url", image_url)
        [] -> menu_item_params
      end

    menu_item_params = Map.put(menu_item_params, "vendor_id", socket.assigns.vendor.id)
    save_menu_item(socket, socket.assigns.live_action, menu_item_params)
  end

  defp save_menu_item(socket, :new, menu_item_params) do
    case Vendors.create_menu_item(menu_item_params) do
      {:ok, _menu_item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Menu item created successfully")
         |> push_navigate(to: ~p"/vendor/dashboard")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_menu_item(socket, :edit, menu_item_params) do
    case Vendors.update_menu_item(socket.assigns.menu_item, menu_item_params) do
      {:ok, _menu_item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Menu item updated successfully")
         |> push_navigate(to: ~p"/vendor/dashboard")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp humanize_error(:too_large), do: "File is too large (max 10MB)"
  defp humanize_error(:too_many_files), do: "You can only upload one image"
  defp humanize_error(:not_accepted), do: "Invalid file type. Please upload JPG, PNG, or GIF"
  defp humanize_error(error), do: to_string(error)
end
