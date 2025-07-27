# River Side Food Court System Documentation

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [Technology Stack](#technology-stack)
4. [Core Features](#core-features)
5. [User Roles](#user-roles)
6. [Database Schema](#database-schema)
7. [Real-time Features](#real-time-features)
8. [Security](#security)
9. [API Endpoints](#api-endpoints)
10. [Deployment](#deployment)
11. [Maintenance](#maintenance)

## System Overview

River Side Food Court is a modern, real-time food ordering system designed for food courts. It enables customers to order from multiple vendors through a QR code-based table ordering system, with integrated payment processing and real-time order tracking.

### Key Benefits

- **For Customers**: Convenient ordering from table, real-time tracking, multi-vendor cart
- **For Vendors**: Real-time order notifications, menu management, order analytics
- **For Cashiers**: Centralized payment processing, order verification
- **For Admins**: Complete system control, user management, analytics

## Architecture

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Load Balancer                             │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Phoenix Web Server                           │
│  ┌────────────┐  ┌────────────┐  ┌──────────────┐             │
│  │   Router   │  │ Controllers│  │  LiveViews   │             │
│  └────────────┘  └────────────┘  └──────────────┘             │
│                                                                 │
│  ┌────────────┐  ┌────────────┐  ┌──────────────┐             │
│  │  Contexts  │  │   PubSub   │  │   Channels   │             │
│  └────────────┘  └────────────┘  └──────────────┘             │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                        PostgreSQL                                │
│  ┌────────────┐  ┌────────────┐  ┌──────────────┐             │
│  │   Tables   │  │   Orders   │  │    Users     │             │
│  │            │  │            │  │              │             │
│  │  Vendors   │  │ OrderItems │  │   Sessions   │             │
│  │            │  │            │  │              │             │
│  │ MenuItems  │  │  Payments  │  │    Tokens    │             │
│  └────────────┘  └────────────┘  └──────────────┘             │
└─────────────────────────────────────────────────────────────────┘
```

### Component Overview

1. **Web Layer**
   - Phoenix Framework handles HTTP requests
   - LiveView provides real-time UI updates
   - Controllers manage traditional request/response

2. **Business Logic Layer**
   - Contexts encapsulate domain logic
   - PubSub enables real-time communication
   - Background jobs handle async operations

3. **Data Layer**
   - PostgreSQL for persistent storage
   - Ecto for database abstraction
   - Migrations manage schema evolution

## Technology Stack

### Backend
- **Language**: Elixir 1.17.2
- **Framework**: Phoenix 1.7.14
- **Database**: PostgreSQL
- **Real-time**: Phoenix PubSub
- **Authentication**: Magic Links (passwordless)
- **Email**: Swoosh with Finch adapter

### Frontend
- **LiveView**: Server-rendered reactive UI
- **CSS Framework**: Tailwind CSS + DaisyUI
- **JavaScript**: Alpine.js for interactivity
- **Icons**: Heroicons
- **Build Tool**: Esbuild

### Development Tools
- **Code Quality**: Credo
- **Security**: Sobelow
- **Testing**: ExUnit
- **Documentation**: ExDoc

## Core Features

### 1. QR Code Table Management
- Each table has a unique QR code
- Customers scan to access ordering system
- Automatic table occupation tracking
- Session management per table

### 2. Multi-Vendor Ordering
- Browse menus from multiple vendors
- Add items to unified cart
- Place orders to different vendors simultaneously
- Individual order tracking per vendor

### 3. Real-time Order Management
- Instant order notifications to vendors
- Live status updates for customers
- PubSub-based communication
- WebSocket connections for real-time updates

### 4. Payment Processing
- Centralized cashier interface
- Multiple payment method support
- Order verification before payment
- Receipt generation

### 5. Menu Management
- Dynamic menu items with images
- Category organization
- Availability toggling
- Price management
- Image upload and cropping

## User Roles

### 1. Customer (No Account Required)
- Scan QR code to start session
- Browse menus and place orders
- Track order status
- Make payment at cashier

### 2. Vendor
- Manage menu items
- Receive and process orders
- Update order status
- View analytics

### 3. Cashier
- Process payments
- Verify orders
- Generate receipts
- Handle refunds

### 4. Admin
- User management
- Vendor management
- System configuration
- Analytics and reports

## Database Schema

### Core Tables

#### users
- `id`: UUID primary key
- `email`: Unique email address
- `is_vendor`: Boolean flag
- `is_admin`: Boolean flag
- `is_cashier`: Boolean flag
- `confirmed_at`: Timestamp
- `timestamps`: Created/updated at

#### vendors
- `id`: UUID primary key
- `name`: Vendor name
- `description`: Vendor description
- `cuisine_type`: Type of cuisine
- `logo_url`: Logo image path
- `is_active`: Boolean flag
- `user_id`: Foreign key to users
- `timestamps`: Created/updated at

#### menu_items
- `id`: UUID primary key
- `name`: Item name
- `description`: Item description
- `price`: Decimal price
- `category`: Item category
- `image_url`: Item image path
- `is_available`: Boolean flag
- `vendor_id`: Foreign key to vendors
- `timestamps`: Created/updated at

#### orders
- `id`: UUID primary key
- `customer_name`: Customer name
- `customer_phone`: Customer phone
- `table_number`: Table number
- `status`: Order status enum
- `total`: Total amount
- `notes`: Special instructions
- `paid`: Boolean flag
- `vendor_id`: Foreign key to vendors
- `timestamps`: Created/updated at

#### order_items
- `id`: UUID primary key
- `quantity`: Item quantity
- `unit_price`: Price per unit
- `subtotal`: Line total
- `notes`: Item-specific notes
- `order_id`: Foreign key to orders
- `menu_item_id`: Foreign key to menu_items
- `timestamps`: Created/updated at

#### tables
- `id`: UUID primary key
- `number`: Unique table number
- `status`: Table status enum
- `occupied_at`: Occupation timestamp
- `customer_phone`: Current customer phone
- `customer_name`: Current customer name
- `cart_data`: JSONB cart storage
- `timestamps`: Created/updated at

## Real-time Features

### PubSub Topics

1. **Vendor Orders**: `vendor:#{vendor_id}:orders`
   - New order notifications
   - Order cancellations
   - Payment confirmations

2. **Customer Orders**: `customer:#{phone}:orders`
   - Status updates
   - Preparation progress
   - Ready notifications

3. **Cashier Dashboard**: `cashier:orders`
   - Orders ready for payment
   - Payment completions
   - Cancellations

### WebSocket Channels

- LiveView maintains persistent connections
- Automatic reconnection on disconnect
- Presence tracking for active users
- Optimized payload sizes

## Security

### Authentication
- Magic link (passwordless) authentication
- 20-minute token expiration
- Single-use tokens
- Session management with remember me option

### Authorization
- Role-based access control (RBAC)
- Route-level protection
- LiveView mount authorization
- Scope-based permissions

### Data Protection
- HTTPS only in production
- CSRF protection
- SQL injection prevention via Ecto
- XSS protection in templates
- File upload sanitization

### Security Headers
- Content Security Policy
- X-Frame-Options
- X-Content-Type-Options
- Strict-Transport-Security

## API Endpoints

### Public Endpoints
- `GET /` - Home page
- `GET /table/:number` - Table check-in
- `POST /users/log-in` - Request magic link

### Authenticated Endpoints

#### Customer
- `GET /customer/menu` - Browse menus
- `GET /customer/cart` - View cart
- `POST /customer/orders` - Place order
- `GET /customer/orders/:id` - Track order

#### Vendor
- `GET /vendor/dashboard` - Vendor dashboard
- `GET /vendor/menu-items` - Manage menu
- `PUT /vendor/orders/:id` - Update order status
- `GET /vendor/analytics` - View analytics

#### Cashier
- `GET /cashier/dashboard` - Payment dashboard
- `PUT /cashier/orders/:id/pay` - Process payment
- `GET /cashier/reports` - Daily reports

#### Admin
- `GET /admin/dashboard` - Admin dashboard
- `POST /admin/users` - Create user
- `DELETE /admin/users/:id` - Delete user
- `POST /admin/tables/reset` - Reset tables

## Deployment

### Requirements
- Elixir 1.17+
- PostgreSQL 14+
- Node.js 18+ (for assets)
- 2GB+ RAM recommended
- SSL certificate for production

### Environment Variables
```bash
# Database
DATABASE_URL=postgresql://user:pass@host/db

# Phoenix
SECRET_KEY_BASE=64-character-secret
PHX_HOST=your-domain.com

# Email
SMTP_SERVER=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your-email
SMTP_PASSWORD=your-password

# Uploads
UPLOAD_PATH=/path/to/uploads
```

### Production Checklist
1. Set `MIX_ENV=prod`
2. Generate secret key base
3. Configure database URL
4. Set up SSL certificates
5. Configure email service
6. Set up file storage
7. Enable monitoring
8. Configure backups

### Deployment Steps
```bash
# Build release
mix deps.get --only prod
MIX_ENV=prod mix compile
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release

# Run migrations
_build/prod/rel/river_side/bin/river_side eval "RiverSide.Release.migrate"

# Start application
_build/prod/rel/river_side/bin/river_side start
```

## Maintenance

### Regular Tasks

#### Daily
- Monitor error logs
- Check system performance
- Verify backup completion
- Review security alerts

#### Weekly
- Update dependencies
- Run security scans
- Clean old sessions
- Archive completed orders

#### Monthly
- Performance optimization
- Database maintenance
- Security audit
- User feedback review

### Monitoring

#### Application Metrics
- Request response times
- WebSocket connections
- Error rates
- Memory usage

#### Business Metrics
- Orders per day
- Average order value
- Vendor performance
- Payment success rate

### Backup Strategy
1. **Database**: Daily automated backups
2. **Uploads**: Weekly file system backups
3. **Configuration**: Version controlled
4. **Retention**: 30 days minimum

### Troubleshooting

#### Common Issues
1. **WebSocket Disconnections**
   - Check load balancer configuration
   - Verify WebSocket timeout settings
   - Monitor client network stability

2. **Slow Performance**
   - Check database query performance
   - Monitor N+1 queries
   - Verify proper indexing
   - Check connection pool size

3. **Email Delivery**
   - Verify SMTP configuration
   - Check spam folders
   - Monitor bounce rates
   - Review email logs

### Scaling Considerations

#### Horizontal Scaling
- Phoenix supports clustering
- PostgreSQL read replicas
- Load balancer configuration
- Shared storage for uploads

#### Performance Optimization
- Database indexing strategy
- Query optimization
- Caching strategy
- CDN for static assets

## Support

### Documentation
- This system documentation
- API documentation (ExDoc)
- User guides
- Video tutorials

### Contact
- Technical Support: tech@riverside.com
- Business Support: support@riverside.com
- Emergency: +60-123-456-789

### License
Copyright (c) 2024 River Side Food Court
All rights reserved.