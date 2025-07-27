# Malaysian Timezone Implementation

## Overview
The River Side Food Court system has been updated to display all times in Malaysian timezone (UTC+8) instead of UTC. This ensures that all timestamps shown to users reflect the local time in Malaysia.

## Implementation Details

### Timezone Helper Module
A new helper module `RiverSideWeb.Helpers.TimezoneHelper` has been created to handle all timezone conversions:

- **Location**: `lib/river_side_web/helpers/timezone_helper.ex`
- **Offset**: UTC+8 hours (Malaysian time)

### Key Functions

1. **`to_malaysian_time/1`** - Converts UTC datetime to Malaysian time
2. **`format_malaysian_time/2`** - Formats datetime in Malaysian time with custom format
3. **`format_malaysian_time_only/1`** - Shows only time portion (e.g., "02:30 PM")
4. **`format_malaysian_datetime/1`** - Shows full date and time
5. **`malaysian_now/0`** - Gets current Malaysian time
6. **`malaysian_today/0`** - Gets today's date in Malaysian timezone

### Updated Components

#### 1. Cashier Dashboard
- **File**: `lib/river_side_web/live/cashier_live/dashboard.ex`
- **Changes**: All order timestamps now display in Malaysian time
- **Display format**: Time only (e.g., "02:30 PM")

#### 2. Vendor Dashboard
- **File**: `lib/river_side_web/live/vendor_live/dashboard.ex`
- **Changes**: Order timestamps in completed orders list show Malaysian time
- **Display format**: Time only (e.g., "02:30 PM")

#### 3. Customer Order Tracking
- **File**: `lib/river_side_web/live/customer_live/order_tracking.ex`
- **Changes**: Completed order timestamps show Malaysian time
- **Display format**: Time only (e.g., "02:30 PM")

#### 4. Admin Dashboard
- **File**: `lib/river_side_web/live/admin_live/dashboard.ex`
- **Changes**: User registration dates and times show Malaysian time
- **Display format**: Date and time separately

#### 5. Order Generation
- **File**: `lib/river_side/vendors/order.ex`
- **Changes**: Order numbers now use Malaysian date (important for date rollover)
- **Format**: ORD-YYYYMMDD-XXXXX

#### 6. Daily Reports
- **File**: `lib/river_side/vendors.ex`
- **Changes**: "Today's orders" queries use Malaysian date for filtering

## Important Notes

### Database Storage
- All timestamps are still stored in UTC in the database (best practice)
- Conversion to Malaysian time happens only at display time
- This ensures data consistency and makes timezone changes easier in the future

### Date Rollover
- Malaysian time is 8 hours ahead of UTC
- This means the date rolls over at 4:00 PM UTC (12:00 AM Malaysian time)
- Order numbers and daily reports correctly reflect Malaysian dates

### Testing
To verify the timezone is working correctly, you can run:
```elixir
# In iex console
DateTime.utc_now() |> IO.inspect(label: "UTC Time")
RiverSideWeb.Helpers.TimezoneHelper.malaysian_now() |> IO.inspect(label: "Malaysian Time")
```

### Future Considerations
1. If the system expands to multiple timezones, consider using a proper timezone library like `tzdata`
2. User preferences for timezone display could be added
3. Consider adding timezone information to displays (e.g., "2:30 PM MYT")

## Migration Guide
No database migrations are required since all times are stored in UTC. The changes are purely display-related.

## Troubleshooting
If times appear incorrect:
1. Verify the server's system time is correct
2. Check that the UTC offset is set to 8 hours
3. Ensure all display functions use the TimezoneHelper module
4. Remember that database times remain in UTC