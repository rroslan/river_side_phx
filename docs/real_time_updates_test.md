# Real-Time Order Updates Testing Guide

This document describes how to test the real-time order update functionality between vendors and customers.

## Overview

The system now supports real-time updates for:
1. **Vendors** - Receive notifications when new orders are placed
2. **Customers** - See new orders appear automatically on their order tracking page

## Implementation Details

### Subscription Channels

1. **Vendor Channel**: `vendor_orders:{vendor_id}`
   - Vendors subscribe to this channel in their dashboard
   - Receives all order updates for that specific vendor

2. **Customer Session Channel**: `customer_session:{phone}:{table_number}`
   - Customers subscribe to this channel on the order tracking page
   - Receives updates for all orders in their current dining session

3. **Individual Order Channel**: `order:{order_id}`
   - Used for updates to specific orders (status changes, etc.)

### Broadcast Points

Orders are broadcast when:
- New order is created
- Order status is updated
- Order is marked as paid

## Testing Steps

### Prerequisites
1. Start the Phoenix server: `mix phx.server`
2. Ensure you have at least one vendor account and the vendor is logged in

### Test Scenario 1: New Order Notification to Vendor

1. **Open Vendor Dashboard**
   - Log in as a vendor
   - Navigate to the vendor dashboard
   - Keep this window open

2. **Place a Customer Order**
   - In a different browser/incognito window
   - Go to the customer check-in page
   - Enter phone and table number
   - Navigate to menu
   - Add items from the vendor's menu
   - Go to cart and checkout

3. **Verify Real-Time Update**
   - The vendor dashboard should immediately show the new order
   - No page refresh should be needed
   - A flash message "New order received! Table X" should appear

### Test Scenario 2: Customer Sees New Orders

1. **Initial Customer Session**
   - Check in as a customer
   - Place an order
   - You'll be redirected to order tracking page
   - Keep this page open

2. **Place Another Order**
   - Click "New Order" button
   - Add items from any vendor
   - Complete checkout

3. **Verify Real-Time Update**
   - Return to the order tracking tab (don't refresh)
   - The new order should appear automatically
   - Orders should be sorted with newest first

### Test Scenario 3: Multi-Vendor Orders

1. **Customer Setup**
   - Check in and navigate to order tracking
   - Note any existing orders

2. **Place Orders from Multiple Vendors**
   - Use "New Order" to add items from Vendor A
   - Checkout
   - Use "New Order" again to add items from Vendor B
   - Checkout

3. **Verify Updates**
   - Both orders should appear in real-time on the tracking page
   - Each vendor should only see their own orders
   - The vendor summary section should update automatically

### Test Scenario 4: Order Status Updates

1. **Setup**
   - Have a customer with active orders on the tracking page
   - Have the respective vendor dashboards open

2. **Update Order Status**
   - In vendor dashboard, change order status to "preparing"
   - Then to "ready"

3. **Verify Real-Time Updates**
   - Customer should see status changes immediately
   - No refresh needed on either side

## Troubleshooting

### Orders Not Appearing in Real-Time

1. **Check Browser Console**
   - Open developer tools (F12)
   - Look for WebSocket connection errors
   - Check for JavaScript errors

2. **Verify Subscriptions**
   - Check server logs for subscription messages
   - Look for "Subscribing to vendor_orders:X" messages
   - Verify broadcast messages are being sent

3. **Common Issues**
   - Browser blocking WebSocket connections
   - Multiple tabs causing connection conflicts
   - Server not running or restarted

### Sound Notifications Not Working

1. **Browser Permissions**
   - Ensure site has permission to play audio
   - Some browsers require user interaction first

2. **Volume Settings**
   - Check system volume
   - Check browser tab isn't muted

## Technical Details

### PubSub Topics

```elixir
# Vendor subscription
Phoenix.PubSub.subscribe(RiverSide.PubSub, "vendor_orders:#{vendor_id}")

# Customer session subscription
Phoenix.PubSub.subscribe(RiverSide.PubSub, "customer_session:#{phone}:#{table_number}")

# Order-specific subscription
Phoenix.PubSub.subscribe(RiverSide.PubSub, "order:#{order_id}")
```

### Broadcast Format

```elixir
{:order_updated, order}
```

Where `order` is the complete order struct with associations loaded.

## Expected Behavior

1. **Instant Updates**: Changes should appear within 1-2 seconds
2. **No Refresh Required**: All updates happen via WebSocket
3. **Consistent State**: All connected clients see the same data
4. **Resilient**: Reconnects automatically if connection is lost

## Performance Considerations

- Each subscription creates a persistent WebSocket connection
- Large numbers of concurrent users may require scaling considerations
- PubSub is handled in-memory by default (can be configured for clustering)