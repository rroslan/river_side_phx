defmodule RiverSide.Accounts.ScopeTest do
  use RiverSide.DataCase, async: true

  alias RiverSide.Accounts.Scope

  import RiverSide.AccountsFixtures
  import RiverSide.VendorsFixtures

  describe "for_user/1" do
    test "creates admin scope for admin user" do
      user = user_fixture(%{is_admin: true})
      scope = Scope.for_user(user)

      assert scope.user.id == user.id
      assert scope.role == :admin
      assert scope.vendor == nil
      assert Scope.admin?(scope)
      refute Scope.vendor?(scope)
      refute Scope.cashier?(scope)
      assert Scope.authenticated?(scope)
    end

    test "creates vendor scope with preloaded vendor data" do
      user = user_fixture(%{is_vendor: true})
      vendor = vendor_fixture(%{user_id: user.id})

      scope = Scope.for_user(user)

      assert scope.user.id == user.id
      assert scope.role == :vendor
      assert scope.vendor.id == vendor.id
      assert Scope.vendor?(scope)
      refute Scope.admin?(scope)
      refute Scope.cashier?(scope)
      assert Scope.authenticated?(scope)
    end

    test "creates cashier scope for cashier user" do
      user = user_fixture(%{is_cashier: true})
      scope = Scope.for_user(user)

      assert scope.user.id == user.id
      assert scope.role == :cashier
      assert scope.vendor == nil
      assert Scope.cashier?(scope)
      refute Scope.admin?(scope)
      refute Scope.vendor?(scope)
      assert Scope.authenticated?(scope)
    end

    test "creates guest scope for regular user with no roles" do
      user = user_fixture(%{is_admin: false, is_vendor: false, is_cashier: false})
      scope = Scope.for_user(user)

      assert scope.user.id == user.id
      assert scope.role == :guest
      assert scope.vendor == nil
      assert Scope.guest?(scope)
      refute Scope.admin?(scope)
      refute Scope.vendor?(scope)
      refute Scope.cashier?(scope)
      assert Scope.authenticated?(scope)
    end

    test "returns guest scope for nil user" do
      scope = Scope.for_user(nil)

      assert scope.user == nil
      assert scope.role == :guest
      assert scope.vendor == nil
      assert Scope.guest?(scope)
      refute Scope.authenticated?(scope)
    end
  end

  describe "for_customer/2" do
    test "creates customer scope with phone and table info" do
      phone = "0123456789"
      table_number = 5

      scope = Scope.for_customer(phone, table_number)

      assert scope.user == nil
      assert scope.role == :customer
      assert scope.customer_info.phone == phone
      assert scope.customer_info.table_number == table_number
      assert scope.customer_info.session_started
      assert scope.expires_at
      assert Scope.customer?(scope)
      assert Scope.active_customer?(scope)
      assert Scope.customer_phone(scope) == phone
      assert Scope.customer_table(scope) == table_number
      refute Scope.authenticated?(scope)
    end

    test "customer session expires after 4 hours" do
      scope = Scope.for_customer("0123456789", 5)

      # Check that expires_at is approximately 4 hours from now
      diff = DateTime.diff(scope.expires_at, DateTime.utc_now(), :hour)
      # Allow for small timing differences
      assert diff in [3, 4]
    end
  end

  describe "for_guest/0" do
    test "creates guest scope with minimal permissions" do
      scope = Scope.for_guest()

      assert scope.user == nil
      assert scope.role == :guest
      assert scope.vendor == nil
      assert scope.customer_info == nil
      assert Scope.guest?(scope)
      refute Scope.authenticated?(scope)
      refute Scope.admin?(scope)
      refute Scope.vendor?(scope)
      refute Scope.cashier?(scope)
      refute Scope.customer?(scope)
    end
  end

  describe "permissions" do
    test "admin has all permissions" do
      user = user_fixture(%{is_admin: true})
      scope = Scope.for_user(user)

      assert Scope.can?(scope, :view_all_vendors)
      assert Scope.can?(scope, :manage_vendors)
      assert Scope.can?(scope, :view_all_orders)
      assert Scope.can?(scope, :manage_orders)
      assert Scope.can?(scope, :process_payments)
      assert Scope.can?(scope, :manage_menu)
      assert Scope.can_manage_orders?(scope)
      assert Scope.can_process_payments?(scope)
      assert Scope.can_manage_menu?(scope)
      assert Scope.can_view_all_vendors?(scope)
      assert Scope.can_manage_vendors?(scope)
    end

    test "vendor has vendor-specific permissions" do
      user = user_fixture(%{is_vendor: true})
      _vendor = vendor_fixture(%{user_id: user.id})
      scope = Scope.for_user(user)

      assert Scope.can?(scope, :view_own_menu)
      assert Scope.can?(scope, :manage_menu)
      assert Scope.can?(scope, :create_menu_item)
      assert Scope.can?(scope, :view_own_orders)
      assert Scope.can?(scope, :manage_orders)
      assert Scope.can_manage_menu?(scope)
      assert Scope.can_manage_orders?(scope)

      refute Scope.can?(scope, :view_all_vendors)
      refute Scope.can?(scope, :process_payments)
      refute Scope.can_process_payments?(scope)
      refute Scope.can_view_all_vendors?(scope)
    end

    test "cashier has payment permissions" do
      user = user_fixture(%{is_cashier: true})
      scope = Scope.for_user(user)

      assert Scope.can?(scope, :process_payments)
      assert Scope.can?(scope, :mark_orders_paid)
      assert Scope.can?(scope, :view_payment_queue)
      assert Scope.can?(scope, :view_all_orders)
      assert Scope.can_process_payments?(scope)

      refute Scope.can?(scope, :manage_menu)
      refute Scope.can?(scope, :manage_vendors)
      refute Scope.can_manage_menu?(scope)
      refute Scope.can_manage_vendors?(scope)
    end

    test "customer has limited permissions" do
      scope = Scope.for_customer("0123456789", 5)

      assert Scope.can?(scope, :view_menu)
      assert Scope.can?(scope, :place_order)
      assert Scope.can?(scope, :view_own_orders)
      assert Scope.can?(scope, :track_orders)

      refute Scope.can?(scope, :manage_menu)
      refute Scope.can?(scope, :process_payments)
      refute Scope.can?(scope, :manage_vendors)
    end

    test "guest has minimal permissions" do
      scope = Scope.for_guest()

      assert Scope.can?(scope, :view_menu)
      assert Scope.can?(scope, :view_table_availability)

      refute Scope.can?(scope, :place_order)
      refute Scope.can?(scope, :manage_menu)
      refute Scope.can?(scope, :process_payments)
    end
  end

  describe "owns_vendor?/2" do
    test "vendor owns their own vendor" do
      user = user_fixture(%{is_vendor: true})
      vendor = vendor_fixture(%{user_id: user.id})
      scope = Scope.for_user(user)

      assert Scope.owns_vendor?(scope, vendor.id)
      assert Scope.owns_vendor?(scope, %{vendor_id: vendor.id})
    end

    test "vendor doesn't own other vendors" do
      user = user_fixture(%{is_vendor: true})
      _vendor = vendor_fixture(%{user_id: user.id})
      other_vendor = vendor_fixture()
      scope = Scope.for_user(user)

      refute Scope.owns_vendor?(scope, other_vendor.id)
      refute Scope.owns_vendor?(scope, %{vendor_id: other_vendor.id})
    end

    test "admin owns all vendors" do
      admin = user_fixture(%{is_admin: true})
      vendor = vendor_fixture()
      scope = Scope.for_user(admin)

      assert Scope.owns_vendor?(scope, vendor.id)
      assert Scope.owns_vendor?(scope, %{vendor_id: vendor.id})
    end

    test "non-vendor users don't own any vendors" do
      cashier = user_fixture(%{is_cashier: true})
      vendor = vendor_fixture()
      scope = Scope.for_user(cashier)

      refute Scope.owns_vendor?(scope, vendor.id)
      refute Scope.owns_vendor?(scope, %{vendor_id: vendor.id})
    end
  end

  describe "customer helpers" do
    test "active_customer? returns true for valid session" do
      scope = Scope.for_customer("0123456789", 5)
      assert Scope.active_customer?(scope)
    end

    test "active_customer? returns false for expired session" do
      scope = Scope.for_customer("0123456789", 5)
      # Manually set expired time
      expired_scope = %{scope | expires_at: DateTime.add(DateTime.utc_now(), -1, :hour)}
      refute Scope.active_customer?(expired_scope)
    end

    test "active_customer? returns false for non-customer scopes" do
      admin = user_fixture(%{is_admin: true})
      scope = Scope.for_user(admin)
      refute Scope.active_customer?(scope)
    end

    test "customer_phone and customer_table return correct values" do
      phone = "0123456789"
      table = 5
      scope = Scope.for_customer(phone, table)

      assert Scope.customer_phone(scope) == phone
      assert Scope.customer_table(scope) == table
    end

    test "customer_phone and customer_table return nil for non-customer scopes" do
      admin = user_fixture(%{is_admin: true})
      scope = Scope.for_user(admin)

      assert Scope.customer_phone(scope) == nil
      assert Scope.customer_table(scope) == nil
    end
  end

  describe "vendor_id/1" do
    test "returns vendor id for vendor scope" do
      user = user_fixture(%{is_vendor: true})
      vendor = vendor_fixture(%{user_id: user.id})
      scope = Scope.for_user(user)

      assert Scope.vendor_id(scope) == vendor.id
    end

    test "returns nil for non-vendor scopes" do
      admin = user_fixture(%{is_admin: true})
      scope = Scope.for_user(admin)

      assert Scope.vendor_id(scope) == nil
    end
  end

  describe "session_id" do
    test "generates unique session ids" do
      scope1 = Scope.for_guest()
      scope2 = Scope.for_guest()
      scope3 = Scope.for_customer("0123456789", 5)

      assert scope1.session_id != scope2.session_id
      assert scope1.session_id != scope3.session_id
      assert scope2.session_id != scope3.session_id
    end

    test "all scope types get session ids" do
      admin_scope = Scope.for_user(user_fixture(%{is_admin: true}))
      customer_scope = Scope.for_customer("0123456789", 5)
      guest_scope = Scope.for_guest()

      assert admin_scope.session_id
      assert customer_scope.session_id
      assert guest_scope.session_id
    end
  end
end
