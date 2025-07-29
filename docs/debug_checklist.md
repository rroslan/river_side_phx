# Real-Time Updates Debug Checklist

## Quick Diagnosis Steps

### 1. Verify Flash Message Appears
- [x] Flash message "New order received! Table X" appears
- This confirms PubSub broadcast is working

### 2. Check Browser Console (F12)
```javascript
// Look for these console logs:
"Vendor Dashboard: Subscribed to vendor_orders:X"
"NotificationSound hook mounted"
"Received play-notification-sound event"
"Sound not yet enabled - waiting for user interaction"
```

### 3. Check Server Logs
```
# Look for these log messages:
"Order created successfully - ID: X, broadcasting updates..."
"Broadcasting order update for order #X (status: pending) to vendor_orders:X"
"Vendor Dashboard: Received order update for order #X"
"Vendor Dashboard: Processing order update for our vendor"
"Vendor Dashboard: Refreshed active orders list, now have X active orders"
```

## Common Issues and Solutions

### Issue 1: Orders Not Appearing in Real-Time
**Symptom**: Flash message appears but order list doesn't update

**Quick Fix**:
1. Hard refresh the page (Ctrl+Shift+R)
2. Check if multiple browser tabs are open (close extras)
3. Verify WebSocket connection in Network tab (WS)

**Debug Steps**:
```elixir
# In IEx console, check if orders are actually created:
alias RiverSide.Vendors
Vendors.list_active_orders(vendor_id)
```

### Issue 2: Sound Not Playing
**Symptom**: "Sound not yet enabled" in console

**Quick Fix**:
1. Click the speaker icon in the vendor dashboard navbar
2. Or interact with any button on the page first
3. Check browser allows sound for this site

**Browser Settings**:
- Chrome: Settings → Privacy → Site Settings → Sound
- Firefox: Page Info → Permissions → Play Audio
- Safari: Safari → Settings → Websites → Auto-Play

### Issue 3: Intermittent Updates
**Symptom**: Some orders appear, others don't

**Debug Steps**:
1. Check vendor ID matches:
   ```
   # In logs, verify:
   "vendor_id: X, my vendor_id: X"  # Should match
   ```

2. Check order status:
   ```
   # Only "pending", "preparing", "ready" orders show in active list
   ```

3. Verify subscription:
   ```elixir
   # Test subscription directly:
   Phoenix.PubSub.subscribe(RiverSide.PubSub, "vendor_orders:VENDOR_ID")
   ```

## Manual Testing Procedure

### Step 1: Prepare Two Windows
1. Window A: Vendor Dashboard (logged in as vendor)
2. Window B: Customer Interface (incognito/different browser)

### Step 2: Enable Console Logging
```javascript
// In both windows, open console (F12)
// Set log level to "Verbose" or "All"
```

### Step 3: Place Test Order
1. In Window B (Customer):
   - Check in with phone/table
   - Add items from the vendor
   - Go to cart and checkout

2. In Window A (Vendor):
   - Watch for flash message
   - Check if order appears in list
   - Note console messages

### Step 4: Check Results
- [ ] Flash message appeared
- [ ] Order shows in active orders list
- [ ] Console shows broadcast received
- [ ] No JavaScript errors in console

## Advanced Debugging

### Enable Detailed Phoenix Logging
Add to `config/dev.exs`:
```elixir
config :logger, :console,
  level: :debug,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :module, :function]
```

### Monitor PubSub in IEx
```elixir
# Start IEx session
iex -S mix phx.server

# Subscribe to vendor channel
Phoenix.PubSub.subscribe(RiverSide.PubSub, "vendor_orders:1")

# Place an order for vendor 1
# You should see: {:order_updated, %Order{...}}
```

### Check LiveView Process
```elixir
# Find LiveView processes
Process.list()
|> Enum.filter(fn pid ->
  case Process.info(pid, :dictionary) do
    {:dictionary, dict} ->
      Keyword.get(dict, :"$initial_call") == {Phoenix.LiveView.Channel, :init, 1}
    _ -> false
  end
end)
```

## Performance Checks

### 1. Check Active Connections
```bash
# Count WebSocket connections
netstat -an | grep :4000 | grep ESTABLISHED | wc -l
```

### 2. Monitor Memory Usage
```elixir
# In IEx
:observer.start()
# Go to "Processes" tab and sort by memory
```

### 3. Check PubSub Performance
```elixir
# Test broadcast speed
{time, _} = :timer.tc(fn ->
  Phoenix.PubSub.broadcast(
    RiverSide.PubSub,
    "vendor_orders:1",
    {:test, "message"}
  )
end)
IO.puts("Broadcast took #{time} microseconds")
```

## When All Else Fails

1. **Clear Browser Data**:
   - Clear cookies and site data
   - Disable browser extensions
   - Try incognito mode

2. **Restart Services**:
   ```bash
   # Stop server
   Ctrl+C twice
   
   # Clear build
   mix deps.clean --all
   mix clean
   
   # Rebuild
   mix deps.get
   mix compile
   mix phx.server
   ```

3. **Check Database**:
   ```sql
   -- Check recent orders
   SELECT id, vendor_id, status, inserted_at 
   FROM orders 
   ORDER BY inserted_at DESC 
   LIMIT 10;
   ```

4. **Enable LiveView Debug Mode**:
   Add to `config/dev.exs`:
   ```elixir
   config :phoenix_live_view,
     debug_heex_annotations: true,
     enable_expensive_runtime_checks: true
   ```

## Contact Support If

- WebSocket disconnects immediately
- No logs appear despite orders being created
- JavaScript errors persist after refresh
- Orders appear in database but not in UI
- Multiple vendors affected simultaneously