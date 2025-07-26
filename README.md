# River Side Food Court Management System

A comprehensive food court management system built with Phoenix LiveView, featuring role-based access control, vendor management, and real-time order processing.

## Features

### 🔐 Authentication & Authorization
- Passwordless authentication using magic links
- Three user roles: Admin, Vendor, and Cashier
- Role-based access control for different dashboards

### 👤 User Roles

#### Admin
- Complete user management (CRUD operations)
- Vendor management
- System-wide oversight
- Access to all system features

#### Vendor
- Manage vendor profile and branding
- Menu item management (add, edit, delete)
- Real-time order tracking
- Sales analytics and reporting
- Image upload for logos and menu items

#### Cashier
- Create new orders
- Process customer transactions
- View active orders across all vendors
- Daily sales summary

### 🍽️ Core Features
- **Vendor Management**: Multiple vendors with individual profiles
- **Menu Management**: Categories (food/drinks), pricing, availability
- **Order Processing**: Real-time order status updates
- **Image Uploads**: Support for vendor logos and menu item images
- **Responsive Design**: DaisyUI dark theme with mobile optimization

## Tech Stack

- **Backend**: Elixir/Phoenix 1.7.17
- **Frontend**: Phoenix LiveView
- **Database**: PostgreSQL
- **UI Framework**: TailwindCSS + DaisyUI
- **Real-time**: Phoenix PubSub
- **File Uploads**: Phoenix LiveView Uploads

## Prerequisites

- Elixir 1.18+ and Erlang/OTP 26+
- PostgreSQL 14+
- Node.js 18+ (for asset compilation)

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd river_side
```

2. Install dependencies:
```bash
mix deps.get
```

3. Set up the database:
```bash
mix ecto.setup
```

4. Install Node.js dependencies:
```bash
cd assets && npm install && cd ..
```

5. Start the Phoenix server:
```bash
mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Environment Variables

Create a `.env` file in the project root with the following variables:

```env
# Default admin user
ADMIN_EMAIL=admin@example.com

# Default vendor user
VENDOR_EMAIL=vendor1@example.com

# Default cashier user
CASHIER_EMAIL=cashier1@example.com
```

## Database Setup

Run the following commands to set up your database:

```bash
# Create and migrate database
mix ecto.create
mix ecto.migrate

# Seed with sample data
mix run priv/repo/seeds.exs
```

## Default Users

After running the seed file, you can log in with these default users:

- **Admin**: admin@example.com
- **Vendor**: vendor1@example.com
- **Cashier**: cashier1@example.com

Additional test users created by seeds:
- vendor2@example.com (Western Delights)
- vendor3@example.com (Japanese Express)
- cashier2@example.com
- cashier3@example.com

## Usage

### First Time Setup

1. Run the application and visit http://localhost:4000
2. Enter your email address to receive a magic link
3. Check your email (in development, check the terminal logs)
4. Click the magic link to log in

### Admin Dashboard

- Access at `/admin/dashboard`
- Manage all users and vendors
- Create new vendor accounts
- System-wide oversight

### Vendor Dashboard

- Access at `/vendor/dashboard`
- View real-time orders
- Manage menu items
- Update vendor profile
- Upload logo and menu item images
- Track sales statistics

### Cashier Dashboard

- Access at `/cashier/dashboard`
- Create new orders
- Select vendor and menu items
- Process customer transactions
- View order history

## Development

### Running Tests

```bash
mix test
```

### Code Quality

```bash
# Format code
mix format

# Run static analysis
mix credo

# Check for security issues
mix sobelow
```

### Asset Development

For active development with hot-reloading:

```bash
# Terminal 1 - Phoenix server
mix phx.server

# Terminal 2 - Asset watching (if needed)
cd assets && npm run watch
```

## Project Structure

```
river_side/
├── lib/
│   ├── river_side/           # Business logic
│   │   ├── accounts/         # User authentication
│   │   └── vendors/          # Vendor & order management
│   └── river_side_web/       # Web interface
│       ├── components/       # Reusable UI components
│       ├── controllers/      # HTTP controllers
│       └── live/            # LiveView modules
│           ├── admin_live/   # Admin dashboard
│           ├── vendor_live/  # Vendor dashboard
│           └── cashier_live/ # Cashier dashboard
├── priv/
│   ├── repo/                # Database migrations
│   └── static/              # Static assets
│       └── uploads/         # User uploaded files
└── test/                    # Test files
```

## Deployment Considerations

1. **File Storage**: Currently uses local file storage. For production, consider:
   - AWS S3
   - Cloudinary
   - Digital Ocean Spaces

2. **Email Service**: Configure a production email service:
   - SendGrid
   - Mailgun
   - AWS SES

3. **Security**:
   - Enable HTTPS
   - Set secure session cookies
   - Configure CORS properly
   - Rate limiting for authentication

4. **Environment Variables**:
   - `SECRET_KEY_BASE`
   - `DATABASE_URL`
   - `PHX_HOST`
   - Email service credentials

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email support@riverside-foodcourt.com or open an issue in the repository.