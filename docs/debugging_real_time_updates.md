# Debugging Real-Time Updates in River Side Food Court

This guide helps troubleshoot issues with real-time order updates between vendors and customers.

## Common Issues and Solutions

### 1. Vendor Not Receiving New Order Notifications

#### Symptoms
- New orders don't appear on vendor dashboard without refresh
- No flash message "New order received! Table X"
- No notification sound

#### Debugging Steps

1. **Check Browser Console**
   ```javascript
   // Open browser console (F12) and look for:
   // - WebSocket connection errors
   // - JavaScript errors
   // - Network tab for WS connections
   ```

2. **Verify Vendor Subscription**
   - Check server logs for: `"Vendor Dashboard: Subscribed to vendor_orders:{id}"`
   - Ensure vendor ID matches the orders being placed

3. **Check Order Creation Logs**
   ```
   # Look for these log messages in order:
   "Order created successfully - ID: {id}, broadcasting updates..."
   "Broadcasting order update for order #{id} (status: pending) to vendor_orders:{vendor_id}"
   "Broadcast sent to vendor_orders:{vendor_id}"
   ```

4. **Verify PubSub Connection**
   ```elixir
   # In IEx console:
   Phoenix.PubSub.subscribe(RiverSide.PubSub, "vendor_orders:1")
   # Then create an order for vendor 1 and see if message is received
   ```

### 2. Customer Not Seeing New Orders on Order Tracking

#### Symptoms
- After placing additional orders, they don't appear on order tracking page
- Must refresh to see new orders

#### Debugging Steps

1. **Check Customer Session Subscription**
   - Look for log: `"Broadcasting order update for customer_session:{phone}:{table}"`
   - Verify phone and table match exactly

2. **Verify Order Tracking Mount**
   ```elixir
   # Should see subscription to:
   # - Individual order channels: "order:{id}"
   # - Session channel: "customer_session:{phone}:{table}"
   ```

3. **Check Order Creation Method**
   - Ensure orders are created using `create_order/1` (which broadcasts)
   - If using `create_order_with_items/2`, it now also broadcasts

### 3. Updates Not Working After Server Restart

#### Symptoms
- Real-time updates stop working
- Page refresh required after server restart

#### Solution
- WebSocket connections are lost on server restart
- Users need to refresh their browsers to reconnect
- Consider implementing automatic reconnection in JavaScript

### 4. Inconsistent Updates

#### Symptoms
- Some orders appear, others don't
- Updates work sometimes but not always

#### Debugging Steps

1. **Check for Multiple Tabs**
   - Multiple tabs can interfere with WebSocket connections
   - Try with single tab per user

2. **Verify Data Consistency**
   ```elixir
   # Check order has correct fields:
   order.customer_name  # Should be phone number
   order.table_number   # Should be string
   order.vendor_id      # Must match vendor subscription
   ```

3. **Check Scope Permissions**
   - Ensure `can?(scope, :view, order)` returns true
   - Customer scope should allow viewing their own orders

## Logging Configuration

### Enable Detailed Logging

Add to `config/dev.exs`:
```elixir
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id, :vendor_id]

config :phoenix, :logger, level: :debug
```

### Key Log Messages to Monitor

1. **Subscription Logs**
   - `"Subscribing to vendor_orders:{id}"`
   - `"Vendor Dashboard: Subscribed to vendor_orders:{id}"`

2. **Broadcast Logs**
   - `"Order created successfully - ID: {id}, broadcasting updates..."`
   - `"Broadcasting order update for order #{id} (status: {status}) to vendor_orders:{id}"`
   - `"Broadcast sent to {channel}"`

3. **Reception Logs**
   - `"Vendor Dashboard: Received order update for order #{id}"`
   - `"Vendor Dashboard: Processing order update for our vendor"`

## Testing Real-Time Updates

### Manual Testing Checklist

1. **Two Browser Test**
   - [ ] Open vendor dashboard in Browser A
   - [ ] Open customer interface in Browser B (incognito)
   - [ ] Place order in Browser B
   - [ ] Verify order appears in Browser A without refresh

2. **Multi-Vendor Test**
   - [ ] Open dashboards for Vendor 1 and Vendor 2
   - [ ] Place order for Vendor 1
   - [ ] Verify only Vendor 1 receives notification

3. **Customer Session Test**
   - [ ] Customer places initial order
   - [ ] Keep order tracking page open
   - [ ] Place another order using "New Order" button
   - [ ] Verify new order appears automatically

### Automated Testing

Run broadcast tests:
```bash
mix test test/river_side/vendors_broadcast_test.exs
```

## Common Fixes

### 1. Force Page Refresh
```javascript
// Add to app.js for development
window.addEventListener('phx:live_socket:connect', (info) => {
  console.log("LiveView connected", info);
});

window.addEventListener('phx:live_socket:disconnect', (info) => {
  console.log("LiveView disconnected", info);
  // Optional: Auto-reconnect after delay
  setTimeout(() => window.location.reload(), 5000);
});
```

### 2. Clear Browser Cache
- Hard refresh: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)
- Clear site data in browser developer tools

### 3. Verify Database State
```elixir
# In IEx console:
alias RiverSide.{Vendors, Repo}

# Check recent orders
Vendors.list_orders()
|> Enum.take(5)
|> Enum.map(fn o -> 
  %{
    id: o.id,
    vendor_id: o.vendor_id,
    customer: o.customer_name,
    table: o.table_number,
    status: o.status
  }
end)
```

## Architecture Overview

### PubSub Channels

1. **Vendor Orders**: `vendor_orders:{vendor_id}`
   - All orders for specific vendor
   - New orders, status updates

2. **Customer Session**: `customer_session:{phone}:{table_number}`
   - All orders for customer's dining session
   - New orders from any vendor

3. **Individual Order**: `order:{order_id}`
   - Updates to specific order
   - Status changes

4. **All Orders**: `orders:all`
   - Kitchen display system
   - Admin monitoring

### Message Format
```elixir
{:order_updated, order}
# where order is full Order struct with associations loaded
```

## Performance Considerations

1. **Connection Limits**
   - Each LiveView creates WebSocket connection
   - Monitor server resources with many concurrent users

2. **Message Size**
   - Full order with associations can be large
   - Consider pagination for order lists

3. **Broadcast Frequency**
   - Avoid rapid successive updates
   - Batch updates when possible

## Need More Help?

1. Check Phoenix LiveView logs
2. Verify Ecto queries are returning expected data
3. Use browser network inspector to monitor WebSocket frames
4. Test with `Phoenix.PubSub` directly in IEx console