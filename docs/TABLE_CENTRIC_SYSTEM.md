# Table-Centric System Documentation

## Overview
The River Side Food Court system has been enhanced to be table-centric, meaning that the table is the central entity that ties together customer sessions, cart data, and orders. This approach provides a more realistic representation of how food courts operate, where customers sit at a table and may order from multiple vendors.

## Key Features

### 1. Cart Persistence at Table Level
- Cart data is stored in the `tables` table as a JSON field (`cart_data`)
- Multiple customers at the same table share the same cart
- Cart persists even if customers navigate away and return
- Cart is automatically cleared when the table is released

### 2. Multi-Vendor Order Support
- When a customer orders from multiple vendors, each vendor receives a separate order with its own order number
- Each order is tracked independently for preparation status
- All orders are associated with the same table number

### 3. Unified Payment at Cashier
- The cashier can view all orders for a table together
- Two view modes available:
  - **Order View**: Traditional view showing individual orders
  - **Table View**: Groups orders by table number with aggregated totals
- Cashier can process payment for all orders at once
- Table is only released after all orders are paid and completed

## Implementation Details

### Database Schema

#### Tables Table
```sql
tables
- id (primary key)
- number (integer, unique)
- status (string: "available", "occupied", "reserved")
- occupied_at (timestamp)
- customer_phone (string)
- customer_name (string)
- cart_data (jsonb/map) -- NEW: Stores cart items as {item_id: quantity}
```

### Cart Management Functions

#### In `RiverSide.Tables` context:
- `update_table_cart/2` - Updates entire cart data
- `get_table_cart/1` - Retrieves cart data
- `add_to_cart/3` - Adds item to cart
- `remove_from_cart/2` - Removes item from cart
- `update_cart_item/3` - Updates item quantity
- `clear_cart/1` - Clears all cart data

### Customer Flow

1. **Table Selection**: Customer enters phone number and selects table
2. **Menu Browsing**: 
   - Cart is loaded from table data
   - Table number is displayed in the navigation bar
   - Multiple customers can add items to the same table's cart
   - Cart updates are broadcast to all connected sessions for that table
3. **Cart View**:
   - Shows "Your Cart - Table #X" in the header
   - Displays order summary with:
     - Table number (prominently)
     - Customer phone
     - Total items count
     - Number of vendors
   - Items grouped by vendor with:
     - Vendor name with avatar
     - Item name, description, and unit price
     - Quantity controls (+/-)
     - Line item total (price × quantity)
     - Vendor subtotal
   - Grand total displayed prominently
4. **Checkout**: 
   - Creates separate orders for each vendor
   - Each order has its own order number
   - Cart is cleared from table after successful order placement
5. **Order Tracking**: Customer can track all their orders on one page

### Cashier Flow

1. **Dashboard Views**:
   - **Table View** (Default): Shows tables with aggregated order information
     - Total amount for all orders at the table
     - Payment status (X/Y orders paid)
     - Quick actions to view details
   - **Order View**: Traditional individual order cards

2. **Table Order Management**:
   - Click "View Table" or "View Details" to see all orders for a table
   - Modal shows:
     - All active orders with individual statuses
     - Total amount for the table
     - Payment status for each order
     - Actions:
       - "Pay All Orders" - Marks all unpaid orders as paid
       - "Release Table" - Available when all orders are paid

3. **Order Processing**:
   - Individual orders can still be managed (view details, mark as paid)
   - Table release only available when all orders are completed and paid

### Vendor Flow
- No changes to vendor workflow
- Each vendor still receives and manages their orders independently
- Order numbers include date in Malaysian timezone

## Benefits

1. **Realistic Workflow**: Matches real-world food court operations
2. **Shared Cart**: Multiple people at a table can collaborate on ordering
3. **Unified Payment**: Customers pay once for all vendors
4. **Better Table Management**: Clear association between tables and orders
5. **Data Persistence**: Cart survives page refreshes and navigation
6. **Clear Information Display**: 
   - Table number always visible
   - Detailed pricing breakdowns
   - Item descriptions and quantities
   - Multi-vendor order aggregation

## Technical Considerations

### Real-time Updates
- Uses Phoenix PubSub for real-time cart synchronization
- Table updates broadcast to all connected clients
- Order status changes reflect immediately

### Timezone Handling
- All timestamps stored in UTC
- Display times converted to Malaysian timezone (UTC+8)
- Order numbers use Malaysian date

### Error Handling
- Graceful handling of concurrent cart updates
- Table validation prevents orphaned orders
- Payment verification before table release

## Future Enhancements

1. **Cart Conflict Resolution**: Handle simultaneous updates more gracefully
2. **Order History**: Link historical orders to table sessions
3. **Table Reservation**: Pre-order for reserved tables
4. **Split Payment**: Allow partial payments per vendor
5. **QR Code Integration**: Generate QR codes for easy table/cart sharing

## Recent Fixes

### Admin User Management Modal Fix
**Issue**: The create user modal was disappearing when typing in the email field.

**Cause**: The form was using HTML5 `<dialog>` element with `phx-change` validation, which caused the modal to lose its open state during LiveView re-renders.

**Solution**: Converted from HTML5 dialog to LiveView-controlled modal:
- Added `show_create_modal` and `show_edit_modal` assigns to track modal state
- Replaced `<dialog>` elements with conditional rendering using `<%= if @show_modal do %>`
- Changed from JavaScript `onclick` handlers to Phoenix event handlers (`phx-click`)
- Modal state is now preserved during form validation and re-renders

**Implementation**:
- Create user: `phx-click="open_create_modal"` and `phx-click="close_create_modal"`
- Edit user: `phx-click="edit_user"` opens modal with `show_edit_modal: true`
- Form validation (`phx-change="validate_create"`) no longer affects modal visibility