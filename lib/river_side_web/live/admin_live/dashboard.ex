defmodule RiverSideWeb.AdminLive.Dashboard do
  use RiverSideWeb, :live_view

  alias RiverSide.Accounts
  alias RiverSide.Repo
  alias RiverSideWeb.Helpers.TimezoneHelper
  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <!-- Debug info -->
      <div class="hidden">
        Total users: {@users |> length()} Vendors: {@users |> Enum.filter(& &1.is_vendor) |> length()}
      </div>
      
    <!-- Delete Confirmation Modal -->
      <%= if @show_delete_modal do %>
        <div class="modal modal-open">
          <div class="modal-box">
            <h3 class="font-bold text-lg">Confirm User Deletion</h3>

            <%= if @delete_user do %>
              <div class="py-4 space-y-4">
                <p class="text-sm sm:text-base">
                  Are you sure you want to delete <strong class="break-all">{@delete_user.email}</strong>?
                </p>

                <%= if @delete_user.is_vendor and @delete_impact do %>
                  <div class="alert alert-warning mb-4">
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
                        d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                      />
                    </svg>
                    <span>This vendor has associated data that will also be deleted!</span>
                  </div>

                  <div class="stats stats-vertical sm:stats-horizontal shadow w-full mb-4">
                    <div class="stat">
                      <div class="stat-title text-xs sm:text-sm">Menu Items</div>
                      <div class="stat-value text-base sm:text-lg">{@delete_impact.menu_items}</div>
                    </div>
                    <div class="stat">
                      <div class="stat-title text-xs sm:text-sm">Orders</div>
                      <div class="stat-value text-base sm:text-lg">{@delete_impact.orders.total}</div>
                      <%= if @delete_impact.orders.active > 0 do %>
                        <div class="stat-desc text-error text-xs">
                          {@delete_impact.orders.active} active!
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>

                <div class="text-sm">
                  <p>User roles:</p>
                  <div class="flex gap-2 mt-1">
                    <%= if @delete_user.is_admin do %>
                      <span class="badge badge-success badge-sm">Admin</span>
                    <% end %>
                    <%= if @delete_user.is_vendor do %>
                      <span class="badge badge-warning badge-sm">Vendor</span>
                    <% end %>
                    <%= if @delete_user.is_cashier do %>
                      <span class="badge badge-info badge-sm">Cashier</span>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>

            <div class="modal-action">
              <button type="button" class="btn" phx-click="cancel_delete">Cancel</button>
              <button
                type="button"
                class="btn btn-error"
                phx-click="confirm_delete"
                phx-value-id={@delete_user && @delete_user.id}
              >
                Delete User
              </button>
            </div>
          </div>
        </div>
      <% end %>
      
    <!-- Create User Modal -->
      <%= if @show_create_modal do %>
        <div class="modal modal-open">
          <div class="modal-box w-11/12 max-w-md">
            <h3 class="font-bold text-lg">Create New User</h3>
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
                <div class="space-y-2">
                  <label class="cursor-pointer flex items-center gap-2">
                    <.input
                      field={@create_form[:is_admin]}
                      type="checkbox"
                      class="checkbox checkbox-success"
                    />
                    <span class="label-text">Admin</span>
                  </label>
                  <label class="cursor-pointer flex items-center gap-2">
                    <.input
                      field={@create_form[:is_vendor]}
                      type="checkbox"
                      class="checkbox checkbox-warning"
                    />
                    <span class="label-text">Vendor</span>
                  </label>
                  <label class="cursor-pointer flex items-center gap-2">
                    <.input
                      field={@create_form[:is_cashier]}
                      type="checkbox"
                      class="checkbox checkbox-info"
                    />
                    <span class="label-text">Cashier</span>
                  </label>
                </div>
              </div>
              
    <!-- Show vendor name field when vendor checkbox is checked -->
              <div :if={@create_form[:is_vendor].value == true} class="form-control">
                <label class="label">
                  <span class="label-text">Vendor Name (optional)</span>
                </label>
                <input
                  type="text"
                  name="user[vendor_name]"
                  placeholder="e.g., Mama's Kitchen"
                  class="input input-bordered w-full"
                />
                <label class="label">
                  <span class="label-text-alt">Leave empty to generate from email</span>
                </label>
              </div>

              <div class="modal-action">
                <button type="button" class="btn" phx-click="close_create_modal">Cancel</button>
                <button type="submit" class="btn btn-primary" phx-disable-with="Creating...">
                  Create User
                </button>
              </div>
            </.form>
          </div>
          <div class="modal-backdrop" phx-click="close_create_modal"></div>
        </div>
      <% end %>
      
    <!-- Edit User Modal -->
      <%= if @show_edit_modal && @editing_user do %>
        <div class="modal modal-open">
          <div class="modal-box w-11/12 max-w-md">
            <h3 class="font-bold text-lg">Edit User Roles</h3>
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
                <div class="space-y-2">
                  <label class="cursor-pointer flex items-center gap-2">
                    <.input
                      field={@edit_form[:is_admin]}
                      type="checkbox"
                      class="checkbox checkbox-success"
                    />
                    <span class="label-text">Admin</span>
                  </label>
                  <label class="cursor-pointer flex items-center gap-2">
                    <.input
                      field={@edit_form[:is_vendor]}
                      type="checkbox"
                      class="checkbox checkbox-warning"
                    />
                    <span class="label-text">Vendor</span>
                  </label>
                  <label class="cursor-pointer flex items-center gap-2">
                    <.input
                      field={@edit_form[:is_cashier]}
                      type="checkbox"
                      class="checkbox checkbox-info"
                    />
                    <span class="label-text">Cashier</span>
                  </label>
                </div>
              </div>

              <div class="modal-action">
                <button type="button" class="btn" phx-click="close_edit_modal">Cancel</button>
                <button type="submit" class="btn btn-primary" phx-disable-with="Updating...">
                  Update Roles
                </button>
              </div>
            </.form>
          </div>
          <div class="modal-backdrop" phx-click="close_edit_modal"></div>
        </div>
      <% end %>
      <div class="navbar bg-base-300 shadow-lg">
        <div class="flex-1">
          <h1 class="text-lg sm:text-2xl font-bold text-base-content px-2 sm:px-4">Admin</h1>
        </div>
        <div class="flex-none">
          <div class="dropdown dropdown-end">
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
                <.link href={~p"/admin/vendors"} class="gap-3">
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
                  Vendor Management
                </.link>
              </li>
              <li>
                <.link href={~p"/"} class="gap-3">
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
                      d="M3.375 19.5h17.25m-17.25 0a1.125 1.125 0 01-1.125-1.125M3.375 19.5h7.5c.621 0 1.125-.504 1.125-1.125m-9.75 0V5.625m0 12.75v-1.5c0-.621.504-1.125 1.125-1.125m18.375 2.625V5.625m0 12.75c0 .621-.504 1.125-1.125 1.125m1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125m0 3.75h-7.5A1.125 1.125 0 0112 18.375m9.75-12.75c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125m19.5 0v1.5c0 .621-.504 1.125-1.125 1.125M2.25 5.625v1.5c0 .621.504 1.125 1.125 1.125m0 0h17.25m-17.25 0h7.5c.621 0 1.125.504 1.125 1.125M3.375 8.25c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125m17.25-3.75h-7.5c-.621 0-1.125.504-1.125 1.125m8.625-1.125c.621 0 1.125.504 1.125 1.125v1.5c0 .621-.504 1.125-1.125 1.125m-17.25 0h7.5m-7.5 0c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125M12 10.875v-1.5m0 1.5c0 .621-.504 1.125-1.125 1.125M12 10.875c0 .621.504 1.125 1.125 1.125m-2.25 0c.621 0 1.125.504 1.125 1.125M13.125 12h7.5m-7.5 0c-.621 0-1.125.504-1.125 1.125M20.625 12c.621 0 1.125.504 1.125 1.125v1.5c0 .621-.504 1.125-1.125 1.125m-17.25 0h7.5M12 14.625v-1.5m0 1.5c0 .621-.504 1.125-1.125 1.125M12 14.625c0 .621.504 1.125 1.125 1.125m-2.25 0c.621 0 1.125.504 1.125 1.125m0 1.5v-1.5m0 0c0-.621.504-1.125 1.125-1.125m0 0h7.5"
                    />
                  </svg>
                  Table Management
                </.link>
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
            <div class="stat-desc">
              <a href="/admin/vendors" class="link link-primary">Manage vendors →</a>
            </div>
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
        
    <!-- Quick Actions -->
        <div class="card bg-base-100 shadow-xl mb-4 sm:mb-8">
          <div class="card-body p-4 sm:p-6">
            <h2 class="card-title text-lg sm:text-xl mb-4">Quick Actions</h2>
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4">
              <div class="card bg-base-200">
                <div class="card-body p-3 sm:p-4">
                  <h3 class="font-semibold text-sm sm:text-base">Table Management</h3>
                  <p class="text-xs sm:text-sm text-base-content/70 mb-3">
                    Reset all tables to available status
                  </p>
                  <div class="mb-3">
                    <p class="text-xs text-base-content/60">
                      Occupied: {@occupied_tables}/{@total_tables} tables
                    </p>
                  </div>
                  <button
                    phx-click="reset_all_tables"
                    data-confirm="Are you sure you want to reset all tables? This will clear all table occupancy data."
                    class="btn btn-warning btn-sm"
                  >
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
                  <a href="/" class="btn btn-ghost btn-sm mt-2">
                    Go to Table Management →
                  </a>
                </div>
              </div>

              <div class="card bg-base-200">
                <div class="card-body p-3 sm:p-4">
                  <h3 class="font-semibold text-sm sm:text-base">Vendor Management</h3>
                  <p class="text-xs sm:text-sm text-base-content/70 mb-3">
                    Manage vendor accounts and profiles
                  </p>
                  <a href="/admin/vendors" class="btn btn-primary btn-sm">
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
                    Manage Vendors
                  </a>
                  <p class="text-xs text-base-content/60 mt-2">
                    {count_by_role(@users, :is_vendor)} vendor accounts
                  </p>
                </div>
              </div>

              <div class="card bg-base-200">
                <div class="card-body p-3 sm:p-4">
                  <h3 class="font-semibold text-sm sm:text-base">System Reports</h3>
                  <p class="text-xs sm:text-sm text-base-content/70 mb-3">
                    View sales and order reports
                  </p>
                  <button class="btn btn-ghost btn-sm" disabled>
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
                        d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z"
                      />
                    </svg>
                    Coming Soon
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Users Table -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body p-4 sm:p-6">
            <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-3 mb-4">
              <div>
                <h2 class="card-title text-lg sm:text-xl">System Users</h2>
                <p class="text-xs sm:text-sm text-base-content/70">
                  {length(@users)} users • {count_by_role(@users, :is_vendor)} vendors
                </p>
              </div>
              <div>
                <button class="btn btn-primary btn-sm" phx-click="open_create_modal">
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
                  <span class="hidden sm:inline">Create User</span>
                  <span class="sm:hidden">Add</span>
                </button>
              </div>
            </div>
            <div class="overflow-x-auto -mx-4 sm:mx-0">
              <table class="table table-zebra table-xs sm:table-sm">
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
                  <%= for user <- Enum.sort_by(@users, & &1.inserted_at, {:desc, DateTime}) do %>
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
                        <div class="flex gap-1 sm:gap-2 flex-wrap">
                          <%= if user.is_admin do %>
                            <span class="badge badge-success badge-xs sm:badge-sm">Admin</span>
                          <% end %>
                          <%= if user.is_vendor do %>
                            <span class="badge badge-warning badge-xs sm:badge-sm">Vendor</span>
                          <% end %>
                          <%= if user.is_cashier do %>
                            <span class="badge badge-info badge-xs sm:badge-sm">Cashier</span>
                          <% end %>
                          <%= if !user.is_admin && !user.is_vendor && !user.is_cashier do %>
                            <span class="badge badge-ghost badge-xs sm:badge-sm">User</span>
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
                          {TimezoneHelper.format_malaysian_time(user.inserted_at, "%b %d, %Y")}
                        </div>
                        <div class="text-sm opacity-50">
                          {TimezoneHelper.format_malaysian_time_only(user.inserted_at)}
                        </div>
                      </td>
                      <td>
                        <div class="flex gap-1 sm:gap-2 justify-end">
                          <button
                            phx-click="edit_user"
                            phx-value-id={user.id}
                            class="btn btn-ghost btn-xs"
                          >
                            <span class="hidden sm:inline">Edit</span>
                            <svg
                              xmlns="http://www.w3.org/2000/svg"
                              fill="none"
                              viewBox="0 0 24 24"
                              stroke-width="1.5"
                              stroke="currentColor"
                              class="w-3 h-3 sm:hidden"
                            >
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0115.75 21H5.25A2.25 2.25 0 013 18.75V8.25A2.25 2.25 0 015.25 6H10"
                              />
                            </svg>
                          </button>
                          <%= if user.id != @current_scope.user.id do %>
                            <button
                              phx-click="request_delete_user"
                              phx-value-id={user.id}
                              class="btn btn-error btn-xs"
                            >
                              <span class="hidden sm:inline">Delete</span>
                              <svg
                                xmlns="http://www.w3.org/2000/svg"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke-width="1.5"
                                stroke="currentColor"
                                class="w-3 h-3 sm:hidden"
                              >
                                <path
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                  d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0"
                                />
                              </svg>
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

      # Get table statistics
      tables = RiverSide.Tables.list_tables()
      occupied_tables = Enum.count(tables, &(&1.status == "occupied"))
      total_tables = length(tables)

      {:ok,
       socket
       |> assign(users: users)
       |> assign(create_form: to_form(create_changeset))
       |> assign(edit_form: to_form(edit_changeset))
       |> assign(editing_user: nil)
       |> assign(show_create_modal: false)
       |> assign(show_edit_modal: false)
       |> assign(show_delete_modal: false)
       |> assign(delete_user: nil)
       |> assign(delete_impact: nil)
       |> assign(total_tables: total_tables)
       |> assign(occupied_tables: occupied_tables)}
    else
      {:ok,
       socket
       |> put_flash(:error, "You are not authorized to access this page")
       |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("open_create_modal", _params, socket) do
    {:noreply, assign(socket, show_create_modal: true)}
  end

  def handle_event("close_create_modal", _params, socket) do
    {:noreply, assign(socket, show_create_modal: false)}
  end

  def handle_event("close_edit_modal", _params, socket) do
    {:noreply, assign(socket, show_edit_modal: false, editing_user: nil)}
  end

  def handle_event("validate_create", %{"user" => user_params}, socket) do
    changeset =
      %Accounts.User{}
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, create_form: to_form(changeset))}
  end

  @impl true
  def handle_event("create_user", %{"user" => user_params}, socket) do
    # Debug: log the incoming params
    require Logger
    Logger.debug("Creating user with params: #{inspect(user_params)}")

    # Debug: log raw checkbox values
    Logger.debug("Raw is_admin: #{inspect(user_params["is_admin"])}")
    Logger.debug("Raw is_vendor: #{inspect(user_params["is_vendor"])}")
    Logger.debug("Raw is_cashier: #{inspect(user_params["is_cashier"])}")

    # Convert checkbox values - they come as "true"/"false" strings or may be missing
    user_params =
      user_params
      |> Map.put("is_admin", user_params["is_admin"] == "true")
      |> Map.put("is_vendor", user_params["is_vendor"] == "true")
      |> Map.put("is_cashier", user_params["is_cashier"] == "true")

    Logger.debug("Processed params: #{inspect(user_params)}")

    # Don't include confirmed_at in the params passed to create_or_update_user_with_roles
    # as it's added in that function
    role_params = Map.take(user_params, ["is_admin", "is_vendor", "is_cashier"])

    case Accounts.create_or_update_user_with_roles(user_params["email"], role_params) do
      {:ok, user} ->
        Logger.info("User created successfully: #{inspect(user)}")

        Logger.info(
          "User roles - Admin: #{user.is_admin}, Vendor: #{user.is_vendor}, Cashier: #{user.is_cashier}"
        )

        # If creating a vendor user, also create vendor profile
        vendor_creation_result =
          if user.is_vendor == true do
            # Extract vendor name from email or use provided name
            vendor_name =
              case user_params["vendor_name"] do
                nil ->
                  # Generate name from email
                  email_prefix = String.split(user.email, "@") |> List.first()

                  email_prefix
                  |> String.split(".")
                  |> Enum.map(&String.capitalize/1)
                  |> Enum.join(" ")
                  |> then(fn name -> "#{name}'s Kitchen" end)

                "" ->
                  # Empty string, generate from email
                  email_prefix = String.split(user.email, "@") |> List.first()

                  email_prefix
                  |> String.split(".")
                  |> Enum.map(&String.capitalize/1)
                  |> Enum.join(" ")
                  |> then(fn name -> "#{name}'s Kitchen" end)

                name ->
                  # Use provided name
                  name
              end

            case RiverSide.Vendors.create_vendor(%{
                   name: vendor_name,
                   description: "Welcome to #{vendor_name}!",
                   user_id: user.id,
                   is_active: true
                 }) do
              {:ok, vendor} ->
                Logger.info("Vendor profile created: #{inspect(vendor)}")
                {:ok, vendor}

              {:error, vendor_changeset} ->
                Logger.error(
                  "Failed to create vendor profile: #{inspect(vendor_changeset.errors)}"
                )

                # Try to provide more specific error message
                error_msg =
                  Ecto.Changeset.traverse_errors(vendor_changeset, fn {msg, opts} ->
                    Enum.reduce(opts, msg, fn {key, value}, acc ->
                      String.replace(acc, "%{#{key}}", to_string(value))
                    end)
                  end)
                  |> Enum.map(fn {field, messages} ->
                    "#{field}: #{Enum.join(messages, ", ")}"
                  end)
                  |> Enum.join("; ")

                {:error, error_msg}
            end
          else
            {:ok, nil}
          end

        # Refresh the users list from database
        fresh_users = Accounts.list_users()
        Logger.info("Total users after creation: #{length(fresh_users)}")
        Logger.info("New user in list: #{Enum.any?(fresh_users, &(&1.id == user.id))}")

        # Prepare flash message
        flash_message =
          case vendor_creation_result do
            {:ok, vendor} when not is_nil(vendor) ->
              "User created successfully! Vendor profile '#{vendor.name}' also created."

            {:error, error_msg} ->
              "User created but vendor profile failed: #{error_msg}"

            _ ->
              "User created successfully! Email: #{user.email}"
          end

        {:noreply,
         socket
         |> put_flash(:info, flash_message)
         |> assign(users: fresh_users)
         |> assign(create_form: to_form(Accounts.change_user_email(%Accounts.User{}, %{})))
         |> assign(show_create_modal: false)}

      {:error, changeset} ->
        Logger.error("Failed to create user: #{inspect(changeset.errors)}")

        {:noreply,
         socket
         |> put_flash(:error, "Failed to create user. Please check the form.")
         |> assign(create_form: to_form(changeset))}
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
     |> assign(show_edit_modal: true)}
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
         |> assign(show_edit_modal: false)
         |> assign(editing_user: nil)
         |> put_flash(:info, "User roles updated successfully!")}

      {:error, changeset} ->
        {:noreply, assign(socket, edit_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("request_delete_user", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    # If vendor, get deletion impact
    delete_impact =
      if user.is_vendor do
        case Repo.get_by(RiverSide.Vendors.Vendor, user_id: user.id) do
          nil -> nil
          vendor -> RiverSide.Vendors.VendorCleanup.check_vendor_deletion_impact(vendor)
        end
      else
        nil
      end

    {:noreply,
     socket
     |> assign(show_delete_modal: true)
     |> assign(delete_user: user)
     |> assign(delete_impact: delete_impact)}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply,
     socket
     |> assign(show_delete_modal: false)
     |> assign(delete_user: nil)
     |> assign(delete_impact: nil)}
  end

  def handle_event("confirm_delete", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    # Use cascade deletion for vendor users
    result =
      if user.is_vendor do
        RiverSide.Vendors.VendorCleanup.delete_vendor_user(user)
      else
        Repo.delete(user)
      end

    case result do
      {:ok, deleted_info} when is_map(deleted_info) ->
        # Vendor was deleted with cascade
        users = Accounts.list_users()

        message =
          "Vendor '#{deleted_info.vendor_name}' and all associated data deleted successfully! " <>
            "Deleted: #{deleted_info.menu_items_count} menu items, " <>
            "#{deleted_info.orders_count} orders, " <>
            "#{deleted_info.order_items_count} order items."

        {:noreply,
         socket
         |> assign(users: users)
         |> put_flash(:info, message)}

      {:ok, _user} ->
        # Regular user deletion
        users = Accounts.list_users()

        {:noreply,
         socket
         |> assign(users: users)
         |> put_flash(:info, "User deleted successfully!")}

      {:error, reason} ->
        error_message =
          case reason do
            {:cascade_deletion_error, _} -> "Failed to delete vendor data. Please try again."
            {:vendor_deletion_failed, _} -> "Failed to delete vendor profile. Please try again."
            {:user_deletion_failed, _} -> "Failed to delete user account. Please try again."
            _ -> "Failed to delete user. Please try again."
          end

        {:noreply,
         socket
         |> put_flash(:error, error_message)}
    end
    |> then(fn {:noreply, socket} ->
      {:noreply,
       socket
       |> assign(show_delete_modal: false)
       |> assign(delete_user: nil)
       |> assign(delete_impact: nil)}
    end)
  end

  def handle_event("reset_all_tables", _params, socket) do
    # Reset all tables using the Tables context
    RiverSide.Tables.reset_all_tables()

    # Update table statistics
    tables = RiverSide.Tables.list_tables()
    occupied_tables = Enum.count(tables, &(&1.status == "occupied"))
    total_tables = length(tables)

    {:noreply,
     socket
     |> assign(total_tables: total_tables)
     |> assign(occupied_tables: occupied_tables)
     |> put_flash(:info, "All tables have been reset to available status.")}
  end

  defp count_by_role(users, role) do
    Enum.count(users, &Map.get(&1, role, false))
  end
end
