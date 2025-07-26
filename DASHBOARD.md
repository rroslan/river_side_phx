# River Side Dashboard Guide

This guide provides comprehensive documentation for using the River Side application dashboards. The system has three different dashboard types based on user roles: Admin, Vendor, and Cashier.

## Table of Contents

1. [Admin Dashboard](#admin-dashboard)
2. [Vendor Dashboard](#vendor-dashboard)
3. [Cashier Dashboard](#cashier-dashboard)
4. [Common Features](#common-features)

---

## Admin Dashboard

The Admin Dashboard is the control center for system administrators to manage users and monitor the overall system.

### Accessing the Admin Dashboard

1. Log in with your admin credentials
2. You'll be automatically redirected to `/admin/dashboard`

### Key Features

#### 1. User Statistics Overview
At the top of the dashboard, you'll see cards displaying:
- **Total Admins**: Number of administrator accounts
- **Total Vendors**: Number of vendor accounts
- **Total Cashiers**: Number of cashier accounts

#### 2. User Management

The main section contains a comprehensive user management table with the following capabilities:

**Creating New Users:**
1. Click the "Create User" button in the top-right of the user table
2. Fill in the modal form with:
   - Email address
   - Password (minimum 12 characters)
   - User role (Admin, Vendor, or Cashier)
3. Click "Create User" to save

**Editing Users:**
1. Find the user in the table
2. Click the "Edit" button (pencil icon) in the Actions column
3. Update the user's information in the modal
4. Click "Update User" to save changes

**Deleting Users:**
1. Find the user in the table
2. Click the "Delete" button (trash icon) in the Actions column
3. Confirm the deletion when prompted

**User Table Information:**
- Email address
- User role (with color-coded badges)
- Registration date
- Action buttons

### Navigation

The admin dashboard includes:
- User avatar dropdown in the top-right corner
- Settings and logout options in the dropdown menu

---

## Vendor Dashboard

The Vendor Dashboard allows restaurant vendors to manage their menu, process orders, and track sales.

### Accessing the Vendor Dashboard

1. Log in with your vendor credentials
2. You'll be automatically redirected to `/vendor/dashboard`

### Initial Setup

New vendors will see a warning banner prompting them to:
1. Update their vendor name
2. Upload a logo
3. Click "Update Profile" to complete setup

### Key Features

#### 1. Sales Statistics

Three stat cards at the top showing:
- **Today's Sales**: Total revenue and order count for today
- **This Month**: Total revenue and order count for the current month
- **Active Orders**: Number of orders currently pending or being prepared

#### 2. Tab Navigation

The dashboard has three main tabs:

##### Active Orders Tab
- View all pending and preparing orders
- Each order card displays:
  - Order number
  - Customer information
  - Order items with quantities
  - Total amount
  - Order time
  - Current status (color-coded badge)
- **Order Actions:**
  - Update order status (Pending → Preparing → Ready → Completed)
  - View detailed order information

##### Menu Items Tab
- View all menu items for your vendor
- Each item shows:
  - Item name and description
  - Category
  - Price
  - Availability toggle
- **Menu Actions:**
  - Toggle item availability on/off
  - Add new menu items
  - Edit existing menu items
  - Search and filter menu items

##### Analytics Tab
- View detailed sales analytics
- Track performance metrics
- Monitor popular items

#### 3. Real-time Updates

The dashboard automatically updates when:
- New orders are received
- Order statuses change
- Menu items are modified

### Order Processing Workflow

1. **New Order Arrives**: 
   - Notification appears
   - Order shows in "Active Orders" with "Pending" status

2. **Start Preparation**:
   - Click "Start Preparing" button
   - Status changes to "Preparing"

3. **Mark as Ready**:
   - Click "Mark as Ready" when food is prepared
   - Status changes to "Ready"
   - Customer is notified

4. **Complete Order**:
   - Click "Complete" when order is picked up
   - Order moves to completed orders history

### Navigation

The vendor dashboard includes:
- Vendor name display
- User avatar dropdown with:
  - Profile settings
  - Logout option

---

## Cashier Dashboard

The Cashier Dashboard provides a unified view of all vendor orders for efficient payment processing.

### Accessing the Cashier Dashboard

1. Log in with your cashier credentials
2. You'll be automatically redirected to `/cashier/dashboard`

### Key Features

#### 1. Today's Summary

Overview statistics showing:
- **Total Orders**: All orders processed today
- **Total Sales**: Combined revenue from all vendors

#### 2. Active Orders Section

Real-time view of all active orders across all vendors:
- Order cards display:
  - Order number
  - Vendor name
  - Order status (color-coded)
  - Total amount
  - Order time
- Click "View Details" to see full order information

#### 3. Recent Completed Orders

Table showing the last 10 completed orders with:
- Order number
- Vendor name
- Completion time
- Total amount
- Final status

#### 4. Order Details Modal

When viewing order details, you can see:
- Complete order information
- Vendor details
- Itemized list with quantities and prices
- Total amount
- Order timeline

### Order Processing for Cashiers

1. **Monitor Active Orders**: Watch for orders marked as "Ready"
2. **Process Payment**: When customer arrives, locate their order
3. **View Details**: Verify order contents and total
4. **Complete Transaction**: Process payment through your POS system
5. **Order Completion**: Vendor marks order as completed

### Real-time Updates

The dashboard automatically refreshes when:
- New orders are created
- Order statuses change
- Orders are completed

### Navigation

The cashier dashboard includes:
- Dashboard title
- User avatar dropdown with:
  - Account email display
  - Settings link
  - Logout option

---

## Common Features

### User Avatar Menu

All dashboards include a user avatar dropdown in the top-right corner:
- Displays the first letter of your email
- Click to reveal dropdown menu
- Access account settings
- Logout option

### Responsive Design

All dashboards are fully responsive and work on:
- Desktop computers
- Tablets
- Mobile devices

### Status Color Coding

Order statuses use consistent color coding:
- **Pending**: Yellow/Warning badge
- **Preparing**: Blue/Info badge
- **Ready**: Green/Success badge
- **Completed**: Gray/Neutral badge
- **Cancelled**: Red/Error badge

### Real-time Synchronization

All dashboards update in real-time:
- No manual refresh needed
- Instant notification of changes
- Synchronized across all users

### Security Features

- Session timeout after inactivity
- Secure authentication required
- Role-based access control
- Automatic redirection for unauthorized access

---

## Troubleshooting

### Common Issues

1. **Can't access dashboard**
   - Ensure you're logged in
   - Check your user role permissions
   - Clear browser cache and cookies

2. **Dashboard not updating**
   - Check internet connection
   - Refresh the page
   - Log out and back in

3. **Missing features**
   - Verify your user role
   - Contact admin for permission issues

### Getting Help

If you encounter issues:
1. Contact your system administrator
2. Check your user permissions
3. Ensure your account is active

---

## Best Practices

### For Admins
- Regularly review user accounts
- Remove inactive users
- Monitor system usage
- Keep user roles updated

### For Vendors
- Keep menu items updated
- Process orders promptly
- Monitor daily sales
- Maintain accurate inventory status

### For Cashiers
- Stay alert for new orders
- Process payments efficiently
- Communicate with vendors for order issues
- Keep track of daily totals

---

## Updates and Maintenance

The dashboard system receives regular updates:
- New features are added periodically
- Bug fixes are applied automatically
- No action needed from users
- Announcements for major changes

For the latest updates and feature announcements, check with your system administrator.