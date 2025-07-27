# Vendor Cascade Deletion Documentation

## Overview

The River Side Food Court system implements comprehensive cascade deletion for vendor accounts to ensure data integrity and proper cleanup when vendors are removed from the system.

## Architecture

### Module: `RiverSide.Vendors.VendorCleanup`

This service module handles all vendor deletion operations with proper cascade handling.

### Key Features

1. **Transaction-based deletion** - All deletions occur within a database transaction to ensure consistency
2. **Comprehensive cleanup** - Removes all related data including orders, order items, and menu items
3. **Smart user handling** - Preserves user accounts with multiple roles, only removes vendor role
4. **Impact analysis** - Provides detailed information about what will be deleted before confirmation
5. **Logging** - Detailed logging of all deletion operations

## Database Schema

### Foreign Key Constraints

The system uses the following cascade rules:

- `vendors.user_id` → `users.id` (ON DELETE CASCADE)
- `menu_items.vendor_id` → `vendors.id` (ON DELETE CASCADE)
- `orders.vendor_id` → `vendors.id` (ON DELETE CASCADE)
- `order_items.order_id` → `orders.id` (ON DELETE CASCADE)
- `order_items.menu_item_id` → `menu_items.id` (ON DELETE CASCADE)

## Deletion Process

### 1. Standard Vendor Deletion

When a vendor is deleted, the following occurs in order:

1. **Order Items** - All order items associated with the vendor's orders are deleted
2. **Orders** - All orders for the vendor are deleted
3. **Menu Items** - All menu items for the vendor are deleted
4. **Vendor Profile** - The vendor record itself is deleted
5. **User Account** - Handled based on user's other roles:
   - If user has other roles (admin, cashier): Only vendor role is removed
   - If user has no other roles: User account is deleted

### 2. User Deletion from Admin Dashboard

When deleting a user who is a vendor:

1. System checks if user has vendor role
2. If yes, uses cascade deletion process
3. Shows confirmation dialog with impact analysis
4. Proceeds with comprehensive cleanup

## API Functions

### `delete_vendor_with_cascade/1`

```elixir
def delete_vendor_with_cascade(%Vendor{} = vendor)
```

Deletes a vendor and all associated data in a transaction.

**Returns:**
- `{:ok, deleted_info}` - Success with deletion summary
- `{:error, reason}` - Failure with reason

### `delete_vendor_user/1`

```elixir
def delete_vendor_user(%User{} = user)
```

Deletes a vendor user, handling vendor profile if exists.

### `check_vendor_deletion_impact/1`

```elixir
def check_vendor_deletion_impact(%Vendor{} = vendor)
```

Analyzes what would be deleted without performing deletion.

**Returns map with:**
- `vendor_id`, `vendor_name`, `user_email`
- `orders` - Total and active order counts
- `menu_items` - Count of menu items
- `order_items` - Count of order items
- `user_will_be_deleted` - Boolean indicating if user account will be removed
- `has_active_orders` - Boolean for UI warnings

### `archive_vendor/1`

```elixir
def archive_vendor(%Vendor{} = vendor)
```

Soft deletes a vendor by deactivating them and their menu items.

## UI Integration

### Admin Dashboard

1. **User Deletion**
   - Shows confirmation modal with impact analysis for vendor users
   - Displays counts of affected records
   - Warns about active orders
   - Shows whether user account will be preserved

2. **Success Feedback**
   - Detailed message showing what was deleted
   - Counts of all deleted records

### Vendor Management Page

1. **Delete Button** - Available for each vendor in the list
2. **Confirmation Modal** - Shows:
   - Vendor name and user email
   - Statistics on menu items, orders, and order items
   - Warning about active orders
   - User account preservation status
3. **Real-time Updates** - List refreshes after successful deletion

## Safety Features

1. **Transaction Rollback** - Any error during deletion rolls back all changes
2. **Impact Preview** - Always shows what will be deleted before confirmation
3. **Active Order Warnings** - Special warnings for vendors with active orders
4. **Role Preservation** - Never deletes users with multiple roles, only removes vendor role
5. **Comprehensive Logging** - All operations are logged for audit trail

## Error Handling

The system handles various error scenarios:

- `{:cascade_deletion_error, _}` - General cascade deletion failure
- `{:vendor_deletion_failed, _}` - Vendor profile deletion failure
- `{:user_deletion_failed, _}` - User account deletion failure
- `{:user_update_failed, _}` - Failed to update user roles

## Best Practices

1. **Always use VendorCleanup module** - Never delete vendors directly through Repo
2. **Check impact first** - Use `check_vendor_deletion_impact/1` for UI warnings
3. **Consider archiving** - For historical data, consider using `archive_vendor/1` instead
4. **Monitor logs** - Check application logs for deletion operations
5. **Test thoroughly** - Test deletion with various data scenarios

## Migration Notes

If upgrading from a system without cascade deletion:

1. Run migration `20250727000627_update_vendor_cascade_constraints.exs`
2. Test deletion on staging environment first
3. Backup database before applying to production
4. Monitor for any orphaned records after migration

## Future Enhancements

1. **Scheduled Cleanup** - Automatic cleanup of archived vendors after X days
2. **Bulk Operations** - Delete multiple vendors at once
3. **Export Before Delete** - Option to export vendor data before deletion
4. **Undo Operation** - Time-limited undo for accidental deletions
5. **Deletion Queue** - Queue deletions for off-peak processing