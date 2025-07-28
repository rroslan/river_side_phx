defmodule RiverSideWeb.Router do
  use RiverSideWeb, :router

  import RiverSideWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RiverSideWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self' 'unsafe-inline' 'unsafe-eval' https: data: blob: wss:; img-src 'self' data: blob: https:; font-src 'self' data: https:;"
    }

    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RiverSideWeb do
    pipe_through :browser

    live_session :public,
      on_mount: [{RiverSideWeb.UserAuth, :mount_guest_scope}] do
      live "/", TableLive.Index, :index
    end
  end

  # Customer routes - active customer session required
  scope "/customer", RiverSideWeb do
    pipe_through :browser

    # Checkin doesn't require customer scope
    live_session :customer_checkin,
      on_mount: [{RiverSideWeb.UserAuth, :mount_guest_scope}] do
      live "/checkin/:table_number", CustomerLive.Checkin, :new
    end

    # Other customer routes require active customer session
    live_session :customer,
      on_mount: [
        {RiverSideWeb.UserAuth, :mount_customer_scope},
        {RiverSideWeb.Hooks.RequireRole, :customer}
      ] do
      live "/menu", CustomerLive.Menu, :index
      live "/cart", CustomerLive.Cart, :index
      live "/orders", CustomerLive.OrderTracking, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", RiverSideWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:river_side, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RiverSideWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  # User settings routes (any authenticated user)
  scope "/", RiverSideWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated_user,
      on_mount: [
        {RiverSideWeb.UserAuth, :mount_current_scope},
        {RiverSideWeb.Hooks.RequireRole, :authenticated}
      ] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end
  end

  # Admin routes
  scope "/admin", RiverSideWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :admin,
      on_mount: [
        {RiverSideWeb.UserAuth, :mount_current_scope},
        {RiverSideWeb.Hooks.RequireRole, :admin}
      ] do
      live "/dashboard", AdminLive.Dashboard, :index
      live "/vendors", AdminLive.VendorList, :index
    end
  end

  # Vendor routes
  scope "/vendor", RiverSideWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :vendor,
      on_mount: [
        {RiverSideWeb.UserAuth, :mount_current_scope},
        {RiverSideWeb.Hooks.RequireRole, :vendor}
      ] do
      live "/dashboard", VendorLive.Dashboard, :index
      live "/profile/edit", VendorLive.ProfileEdit, :edit
      live "/menu/new", VendorLive.MenuItemForm, :new
      live "/menu/:id/edit", VendorLive.MenuItemForm, :edit
    end
  end

  # Cashier routes
  scope "/cashier", RiverSideWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :cashier,
      on_mount: [
        {RiverSideWeb.UserAuth, :mount_current_scope},
        {RiverSideWeb.Hooks.RequireRole, :cashier}
      ] do
      live "/dashboard", CashierLive.Dashboard, :index
    end
  end

  scope "/", RiverSideWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{RiverSideWeb.UserAuth, :mount_current_scope}] do
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
