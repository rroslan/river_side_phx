defmodule RiverSideWeb.VendorLive.MenuItemForm do
  use RiverSideWeb, :live_view

  alias Phoenix.LiveView.JS
  alias RiverSide.Vendors
  alias RiverSide.Vendors.MenuItem
  alias RiverSideWeb.Helpers.UploadHelper

  @upload_opts [
    accept: ~w(.jpg .jpeg .png .gif .webp),
    max_entries: 1,
    max_file_size: 10_000_000
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200" id="menu-item-form">
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

                <%= if @menu_item.image_url && @live_action == :edit && !@remove_image && Enum.empty?(@uploads.image.entries) do %>
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
                        class="btn btn-sm btn-error btn-outline"
                        phx-click="remove_image"
                        data-confirm="Are you sure you want to remove this image?"
                      >
                        Remove Image
                      </button>
                    </div>
                  </div>
                <% end %>

                <%= if @remove_image do %>
                  <p class="text-sm text-warning mb-2">
                    The current image will be removed when you save.
                  </p>
                <% end %>

                <div class="space-y-4">
                  <div
                    class="relative border-2 border-dashed border-base-300 rounded-lg p-6 text-center hover:border-primary transition-colors cursor-pointer"
                    phx-drop-target={@uploads.image.ref}
                    phx-click={JS.dispatch("click", to: "#menu-item-image-input")}
                  >
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
                        {if Enum.empty?(@uploads.image.entries),
                          do: "Click or drag to upload",
                          else: "Add a different image"}
                      </span>
                    </p>
                    <p class="text-xs text-base-content/50">PNG, JPG, GIF, or WEBP up to 10MB</p>
                    <.live_file_input
                      upload={@uploads.image}
                      id="menu-item-image-input"
                      class="file-input file-input-bordered absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                      aria-label="Upload menu item image"
                    />
                  </div>

                  <%= for entry <- @uploads.image.entries do %>
                    <div class="border rounded-lg p-4 flex items-center gap-4">
                      <.live_img_preview entry={entry} class="w-20 h-20 object-cover rounded" />
                      <div class="flex-1">
                        <p class="font-medium text-sm">{entry.client_name}</p>
                        <progress
                          class="progress progress-primary w-full mt-2"
                          max="100"
                          value={entry.progress}
                        >
                        </progress>
                      </div>
                      <button
                        type="button"
                        class="btn btn-sm btn-ghost"
                        phx-click="cancel-upload"
                        phx-value-ref={entry.ref}
                      >
                        Cancel
                      </button>
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
         socket
         |> assign(vendor: vendor)
         |> allow_upload(:image, @upload_opts)
         |> apply_action(socket.assigns.live_action, params)}
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
    |> assign(:remove_image, false)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    menu_item = Vendors.get_menu_item!(id)

    if menu_item.vendor_id == socket.assigns.vendor.id do
      changeset = Vendors.change_menu_item(menu_item)

      socket
      |> assign(:menu_item, menu_item)
      |> assign(:form, to_form(changeset))
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
  def handle_event("remove_image", _params, socket) do
    {:noreply, assign(socket, :remove_image, true)}
  end

  @impl true
  def handle_event("save", %{"menu_item" => menu_item_params}, socket) do
    case attach_uploaded_image(socket, menu_item_params) do
      {:ok, updated_params, remove_flag} ->
        updated_params = Map.put(updated_params, "vendor_id", socket.assigns.vendor.id)
        socket = assign(socket, :remove_image, remove_flag)
        save_menu_item(socket, socket.assigns.live_action, updated_params)

      {:error, messages} ->
        changeset =
          socket.assigns.menu_item
          |> Vendors.change_menu_item(menu_item_params)
          |> Map.put(:action, :validate)

        {:noreply,
         socket
         |> put_flash(:error, Enum.join(messages, ". "))
         |> assign(:form, to_form(changeset))}
    end
  end

  defp attach_uploaded_image(socket, params) do
    {paths, errors} =
      consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
        filename = UploadHelper.generate_unique_filename(entry.client_name)

        case UploadHelper.process_upload(path, filename,
               allowed_extensions: @upload_opts[:accept],
               max_size: @upload_opts[:max_file_size],
               subdirectory: "menu_items"
             ) do
          {:ok, %{public_path: public_path}} -> {:ok, {:ok, public_path}}
          {:error, reason} -> {:ok, {:error, reason}}
        end
      end)
      |> Enum.reduce({[], []}, fn
        {:ok, path}, {paths, errors} -> {[path | paths], errors}
        {:error, reason}, {paths, errors} -> {paths, [reason | errors]}
      end)

    paths = Enum.reverse(paths)
    errors = Enum.reverse(errors)

    cond do
      errors != [] ->
        {:error, Enum.map(errors, &upload_error_message/1)}

      paths != [] ->
        {:ok, Map.put(params, "image_url", hd(paths)), false}

      socket.assigns[:remove_image] ->
        {:ok, Map.put(params, "image_url", nil), true}

      true ->
        {:ok, params, false}
    end
  end

  defp upload_error_message(:file_not_found), do: "Uploaded file could not be read"
  defp upload_error_message(:file_too_large), do: "Image exceeds the 10MB size limit"
  defp upload_error_message(:invalid_file), do: "Invalid image file"
  defp upload_error_message(:invalid_path), do: "Upload path is invalid"
  defp upload_error_message(reason), do: "Image upload failed: #{inspect(reason)}"

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
