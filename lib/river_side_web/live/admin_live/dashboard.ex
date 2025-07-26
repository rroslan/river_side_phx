defmodule RiverSideWeb.AdminLive.Dashboard do
  use RiverSideWeb, :live_view

  alias RiverSide.Accounts
  alias RiverSide.Repo

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <!-- Create User Modal -->
      <dialog id="create_user_modal" class="modal">
        <div class="modal-box">
          <h3 class="font-bold text-lg mb-4">Create New User</h3>
          <.form for={@create_form} phx-submit="create_user" phx-change="validate_create">
            <div class="form-control w-full">
              <label class="label">
                <span class="label-text">Email</span>
              </label>
              <.input
                field={@create_form[:email]}
                type="email"
                class="input input-bordered w-full"
                placeholder="user@example.com"
                required
              />
            </div>

            <div class="form-control w-full mt-4">
              <label class="label">
                <span class="label-text">Roles</span>
              </label>
              <div class="flex flex-col gap-2">
                <label class="label cursor-pointer">
                  <span class="label-text">Admin</span>
                  <.input
                    field={@create_form[:is_admin]}
                    type="checkbox"
                    class="checkbox checkbox-success"
                  />
                </label>
                <label class="label cursor-pointer">
                  <span class="label-text">Vendor</span>
                  <.input
                    field={@create_form[:is_vendor]}
                    type="checkbox"
                    class="checkbox checkbox-warning"
                  />
                </label>
                <label class="label cursor-pointer">
                  <span class="label-text">Cashier</span>
                  <.input
                    field={@create_form[:is_cashier]}
                    type="checkbox"
                    class="checkbox checkbox-info"
                  />
                </label>
              </div>
            </div>

            <div class="modal-action">
              <button type="button" class="btn" onclick="create_user_modal.close()">Cancel</button>
              <button type="submit" class="btn btn-primary" phx-disable-with="Creating...">
                Create User
              </button>
            </div>
          </.form>
        </div>
        <form method="dialog" class="modal-backdrop">
          <button>close</button>
        </form>
      </dialog>
      
    <!-- Edit User Modal -->
      <dialog id="edit_user_modal" class="modal">
        <div class="modal-box">
          <h3 class="font-bold text-lg mb-4">Edit User Roles</h3>
          <%= if @editing_user do %>
            <.form for={@edit_form} phx-submit="update_user" phx-change="validate_edit">
              <input type="hidden" name="user_id" value={@editing_user.id} />

              <div class="mb-4">
                <p class="text-sm opacity-70">Email</p>
                <p class="font-semibold">{@editing_user.email}</p>
              </div>

              <div class="form-control w-full">
                <label class="label">
                  <span class="label-text">Roles</span>
                </label>
                <div class="flex flex-col gap-2">
                  <label class="label cursor-pointer">
                    <span class="label-text">Admin</span>
                    <.input
                      field={@edit_form[:is_admin]}
                      type="checkbox"
                      class="checkbox checkbox-success"
                    />
                  </label>
                  <label class="label cursor-pointer">
                    <span class="label-text">Vendor</span>
                    <.input
                      field={@edit_form[:is_vendor]}
                      type="checkbox"
                      class="checkbox checkbox-warning"
                    />
                  </label>
                  <label class="label cursor-pointer">
                    <span class="label-text">Cashier</span>
                    <.input
                      field={@edit_form[:is_cashier]}
                      type="checkbox"
                      class="checkbox checkbox-info"
                    />
                  </label>
                </div>
              </div>

              <div class="modal-action">
                <button type="button" class="btn" onclick="edit_user_modal.close()">Cancel</button>
                <button type="submit" class="btn btn-primary" phx-disable-with="Updating...">
                  Update Roles
                </button>
              </div>
            </.form>
          <% end %>
        </div>
        <form method="dialog" class="modal-backdrop">
          <button>close</button>
        </form>
      </dialog>
      <div class="navbar bg-base-300 shadow-lg">
        <div class="flex-1">
          <h1 class="text-2xl font-bold text-base-content px-4">Admin Dashboard</h1>
        </div>
        <div class="flex-none">
          <.link href={~p"/"} class="btn btn-ghost">
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
                d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"
              />
            </svg>
            Back to Tables
          </.link>
          <div class="dropdown dropdown-end ml-2">
            <label tabindex="0" class="btn btn-ghost btn-circle avatar">
              <div class="w-10 rounded-full bg-primary text-primary-content">
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
        </div>
      </div>

      <div class="container mx-auto p-6">
        <!-- Stats Overview -->
        <div class="stats shadow bg-base-100 w-full">
          <div class="stat">
            <div class="stat-figure text-primary">
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
                  d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z"
                />
              </svg>
            </div>
            <div class="stat-title">Total Users</div>
            <div class="stat-value">{length(@users)}</div>
            <div class="stat-desc">System users</div>
          </div>

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
                  d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z"
                />
              </svg>
            </div>
            <div class="stat-title">Admins</div>
            <div class="stat-value">{count_by_role(@users, :is_admin)}</div>
            <div class="stat-desc">Administrator accounts</div>
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
                  d="M13.5 21v-7.5a.75.75 0 01.75-.75h3a.75.75 0 01.75.75V21m-4.5 0H2.36m11.14 0H18m0 0h3.64m-1.39 0V9.349m-16.5 11.65V9.35m0 0a3.001 3.001 0 003.75-.615A2.993 2.993 0 009.75 9.75c.896 0 1.7-.393 2.25-1.016a2.993 2.993 0 002.25 1.016c.896 0 1.7-.393 2.25-1.016a3.001 3.001 0 003.75.614m-16.5 0a3.004 3.004 0 01-.621-4.72L4.318 3.44A1.5 1.5 0 015.378 3h13.243a1.5 1.5 0 011.06.44l1.19 1.189a3 3 0 01-.621 4.72m-13.5 8.65h3.75a.75.75 0 00.75-.75V13.5a.75.75 0 00-.75-.75H6.75a.75.75 0 00-.75.75v3.75c0 .415.336.75.75.75z"
                />
              </svg>
            </div>
            <div class="stat-title">Vendors</div>
            <div class="stat-value">{count_by_role(@users, :is_vendor)}</div>
            <div class="stat-desc">Vendor accounts</div>
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
                  d="M2.25 18.75a60.07 60.07 0 0115.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 013 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 00-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 01-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 003 15h-.75M15 10.5a3 3 0 11-6 0 3 3 0 016 0zm3 0h.008v.008H18V10.5zm-12 0h.008v.008H6V10.5z"
                />
              </svg>
            </div>
            <div class="stat-title">Cashiers</div>
            <div class="stat-value">{count_by_role(@users, :is_cashier)}</div>
            <div class="stat-desc">Cashier accounts</div>
          </div>
        </div>
        
    <!-- Users Table -->
        <div class="card bg-base-100 shadow-xl mt-8">
          <div class="card-body">
            <div class="flex justify-between items-center mb-4">
              <h2 class="card-title">System Users</h2>
              <button class="btn btn-primary" onclick="create_user_modal.showModal()">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="w-5 h-5"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
                </svg>
                Create User
              </button>
            </div>
            <div class="overflow-x-auto">
              <table class="table table-zebra">
                <thead>
                  <tr>
                    <th>Email</th>
                    <th>Roles</th>
                    <th>Status</th>
                    <th>Created</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for user <- @users do %>
                    <tr>
                      <td>
                        <div class="flex items-center gap-3">
                          <div class="avatar">
                            <div class="mask mask-squircle w-12 h-12 bg-primary text-primary-content">
                              <span class="text-xl font-semibold">
                                {String.first(user.email) |> String.upcase()}
                              </span>
                            </div>
                          </div>
                          <div>
                            <div class="font-bold">{user.email}</div>
                            <div class="text-sm opacity-50">ID: {user.id}</div>
                          </div>
                        </div>
                      </td>
                      <td>
                        <div class="flex gap-2 flex-wrap">
                          <%= if user.is_admin do %>
                            <span class="badge badge-success gap-2">Admin</span>
                          <% end %>
                          <%= if user.is_vendor do %>
                            <span class="badge badge-warning gap-2">Vendor</span>
                          <% end %>
                          <%= if user.is_cashier do %>
                            <span class="badge badge-info gap-2">Cashier</span>
                          <% end %>
                          <%= if !user.is_admin && !user.is_vendor && !user.is_cashier do %>
                            <span class="badge badge-ghost gap-2">No Role</span>
                          <% end %>
                        </div>
                      </td>
                      <td>
                        <%= if user.confirmed_at do %>
                          <span class="badge badge-success gap-2">
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
                                d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                              />
                            </svg>
                            Confirmed
                          </span>
                        <% else %>
                          <span class="badge badge-warning gap-2">
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
                                d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z"
                              />
                            </svg>
                            Unconfirmed
                          </span>
                        <% end %>
                      </td>
                      <td>
                        <div class="text-sm">
                          {Calendar.strftime(user.inserted_at, "%b %d, %Y")}
                        </div>
                        <div class="text-sm opacity-50">
                          {Calendar.strftime(user.inserted_at, "%I:%M %p")}
                        </div>
                      </td>
                      <td>
                        <div class="flex gap-2">
                          <button
                            phx-click="edit_user"
                            phx-value-id={user.id}
                            class="btn btn-ghost btn-xs"
                          >
                            Edit
                          </button>
                          <%= if user.id != @current_scope.user.id do %>
                            <button
                              phx-click="delete_user"
                              phx-value-id={user.id}
                              data-confirm="Are you sure you want to delete this user?"
                              class="btn btn-error btn-xs"
                            >
                              Delete
                            </button>
                          <% end %>
                        </div>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_scope.user.is_admin do
      users = Accounts.list_users()

      create_changeset = Accounts.change_user_email(%Accounts.User{}, %{})
      edit_changeset = Accounts.change_user_email(%Accounts.User{}, %{})

      {:ok,
       socket
       |> assign(users: users)
       |> assign(create_form: to_form(create_changeset))
       |> assign(edit_form: to_form(edit_changeset))
       |> assign(editing_user: nil)}
    else
      {:ok,
       socket
       |> put_flash(:error, "You are not authorized to access this page")
       |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("validate_create", %{"user" => user_params}, socket) do
    changeset =
      %Accounts.User{}
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, create_form: to_form(changeset))}
  end

  @impl true
  def handle_event("create_user", %{"user" => user_params}, socket) do
    # Ensure boolean values
    user_params =
      user_params
      |> Map.put("is_admin", user_params["is_admin"] == "true")
      |> Map.put("is_vendor", user_params["is_vendor"] == "true")
      |> Map.put("is_cashier", user_params["is_cashier"] == "true")
      |> Map.put("confirmed_at", DateTime.utc_now(:second))

    case Accounts.create_or_update_user_with_roles(user_params["email"], user_params) do
      {:ok, _user} ->
        users = Accounts.list_users()

        {:noreply,
         socket
         |> assign(users: users)
         |> assign(create_form: to_form(Accounts.change_user_email(%Accounts.User{}, %{})))
         |> put_flash(:info, "User created successfully!")
         |> push_event("close_modal", %{id: "create_user_modal"})}

      {:error, changeset} ->
        {:noreply, assign(socket, create_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("edit_user", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    edit_changeset =
      Accounts.User.role_changeset(user, %{
        is_admin: user.is_admin,
        is_vendor: user.is_vendor,
        is_cashier: user.is_cashier
      })

    {:noreply,
     socket
     |> assign(editing_user: user)
     |> assign(edit_form: to_form(edit_changeset))
     |> push_event("open_modal", %{id: "edit_user_modal"})}
  end

  @impl true
  def handle_event("validate_edit", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.editing_user
      |> Accounts.User.role_changeset(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, edit_form: to_form(changeset))}
  end

  @impl true
  def handle_event("update_user", %{"user" => user_params, "user_id" => user_id}, socket) do
    user = Accounts.get_user!(user_id)

    # Ensure boolean values
    user_params =
      user_params
      |> Map.put("is_admin", user_params["is_admin"] == "true")
      |> Map.put("is_vendor", user_params["is_vendor"] == "true")
      |> Map.put("is_cashier", user_params["is_cashier"] == "true")

    user
    |> Accounts.User.role_changeset(user_params)
    |> Repo.update()
    |> case do
      {:ok, _user} ->
        users = Accounts.list_users()

        {:noreply,
         socket
         |> assign(users: users)
         |> assign(editing_user: nil)
         |> put_flash(:info, "User roles updated successfully!")
         |> push_event("close_modal", %{id: "edit_user_modal"})}

      {:error, changeset} ->
        {:noreply, assign(socket, edit_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete_user", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    case Repo.delete(user) do
      {:ok, _user} ->
        users = Accounts.list_users()

        {:noreply,
         socket
         |> assign(users: users)
         |> put_flash(:info, "User deleted successfully!")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete user. Please try again.")}
    end
  end

  defp count_by_role(users, role) do
    Enum.count(users, &Map.get(&1, role))
  end
end
