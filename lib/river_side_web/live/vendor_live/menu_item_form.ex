defmodule RiverSideWeb.VendorLive.MenuItemForm do
  use RiverSideWeb, :live_view

  alias RiverSide.Vendors
  alias RiverSide.Vendors.MenuItem

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200" id="menu-item-form" phx-hook="ImageCropper">
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
                <%= if @menu_item.image_url && @live_action == :edit && !@cropped_image do %>
                  <div class="mb-4">
                    <p class="text-sm text-base-content/70 mb-2">Current image:</p>
                    <img
                      src={@menu_item.image_url}
                      alt="Current menu item image"
                      class="w-32 h-32 object-cover rounded-lg"
                    />
                    <div class="flex gap-2 mt-2">
                      <button
                        type="button"
                        class="btn btn-sm btn-ghost"
                        onclick="document.getElementById('image-file-input').click()"
                      >
                        Change Image
                      </button>
                      <button
                        type="button"
                        class="btn btn-sm btn-error btn-outline"
                        phx-click="remove_image"
                        data-confirm="Are you sure you want to remove this image?"
                      >
                        Remove Image
                      </button>
                    </div>
                  </div>
                <% end %>
                
    <!-- Image Cropper Container -->
                <div data-cropper-container class="mb-4">
                  <input
                    type="file"
                    data-image-input
                    accept="image/*"
                    class="hidden"
                    id="image-file-input"
                  />
                  <canvas data-crop-canvas class="w-full border-2 border-base-300 rounded-lg hidden"></canvas>
                  
    <!-- Crop Controls -->
                  <div data-crop-controls class="hidden mt-4 space-y-4">
                    <div class="flex gap-2 flex-wrap">
                      <button
                        type="button"
                        class="btn btn-sm"
                        phx-click="change_aspect_ratio"
                        phx-value-ratio="1"
                      >
                        Square (1:1)
                      </button>
                      <button
                        type="button"
                        class="btn btn-sm"
                        phx-click="change_aspect_ratio"
                        phx-value-ratio="1.5"
                      >
                        Wide (3:2)
                      </button>
                      <button
                        type="button"
                        class="btn btn-sm"
                        phx-click="change_aspect_ratio"
                        phx-value-ratio="0.75"
                      >
                        Tall (3:4)
                      </button>
                    </div>
                    <button type="button" data-crop-button class="btn btn-primary btn-sm">
                      Crop & Use Image
                    </button>
                  </div>
                  
    <!-- Cropped Preview -->
                  <div :if={@cropped_image} class="mt-4">
                    <p class="text-sm text-base-content/70 mb-2">Preview:</p>
                    <img
                      src={@cropped_image}
                      alt="Cropped preview"
                      class="w-32 h-32 object-cover rounded-lg"
                    />
                  </div>
                </div>
                
    <!-- Upload Section -->
                <div class="space-y-4">
                  <div
                    class="border-2 border-dashed border-base-300 rounded-lg p-6 text-center hover:border-primary transition-colors cursor-pointer"
                    onclick="document.getElementById('image-file-input').click()"
                  >
                    <label for="image-file-input" class="cursor-pointer">
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
                        <span class="font-medium text-primary">
                          {if @live_action == :edit && @menu_item.image_url && !@cropped_image,
                            do: "Click to change image",
                            else: "Click to upload"}
                        </span>
                      </p>
                      <p class="text-xs text-base-content/50">PNG, JPG, GIF up to 10MB</p>
                      <p class="text-xs text-warning mt-2">
                        Images will be cropped to fit menu display
                      </p>
                    </label>
                  </div>
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
    |> assign(:cropped_image, nil)
    |> assign(:temp_image_path, nil)
    |> assign(:remove_image, false)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    menu_item = Vendors.get_menu_item!(id)

    if menu_item.vendor_id == socket.assigns.vendor.id do
      changeset = Vendors.change_menu_item(menu_item)

      socket
      |> assign(:menu_item, menu_item)
      |> assign(:form, to_form(changeset))
      |> assign(:cropped_image, nil)
      |> assign(:temp_image_path, nil)
      |> assign(:remove_image, false)
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
  def handle_event("change_aspect_ratio", %{"ratio" => ratio}, socket) do
    {:noreply, push_event(socket, "change_aspect_ratio", %{ratio: String.to_float(ratio)})}
  end

  @impl true
  def handle_event("image_loaded", %{"width" => _width, "height" => _height}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "image_cropped",
        %{"data" => data_url, "width" => width, "height" => height},
        socket
      ) do
    # Extract base64 data
    "data:image/" <> rest = data_url
    [_type, base64_data] = String.split(rest, ";base64,", parts: 2)

    # Generate filename
    timestamp = System.system_time(:second)
    filename = "menu_item_#{timestamp}_#{width}x#{height}.jpg"

    # Save to uploads directory
    uploads_dir = Path.join([:code.priv_dir(:river_side), "static", "uploads"])
    File.mkdir_p!(uploads_dir)

    dest_path = Path.join(uploads_dir, filename)
    File.write!(dest_path, Base.decode64!(base64_data))

    {:noreply,
     socket
     |> assign(:cropped_image, ~p"/uploads/#{filename}")
     |> assign(:temp_image_path, ~p"/uploads/#{filename}")
     |> push_event("reset_file_input", %{})}
  end

  @impl true
  def handle_event("remove_image", _params, socket) do
    # For edit mode, clear the current image
    if socket.assigns.live_action == :edit do
      {:noreply,
       socket
       |> assign(:menu_item, %{socket.assigns.menu_item | image_url: nil})
       |> assign(:cropped_image, nil)
       |> assign(:temp_image_path, nil)
       |> assign(:remove_image, true)
       |> push_event("reset_file_input", %{})}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save", %{"menu_item" => menu_item_params}, socket) do
    menu_item_params =
      cond do
        socket.assigns[:remove_image] ->
          Map.put(menu_item_params, "image_url", nil)

        socket.assigns.temp_image_path ->
          Map.put(menu_item_params, "image_url", socket.assigns.temp_image_path)

        true ->
          menu_item_params
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
end
