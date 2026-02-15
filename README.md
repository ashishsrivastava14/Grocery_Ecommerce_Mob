# Grocery eCommerce - Multi-Vendor Platform

A production-ready multi-vendor grocery eCommerce platform built with **Flutter** (Web + Mobile) and **FastAPI** backend with **PostgreSQL**.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                    Nginx Proxy                   │
│              (Rate Limiting, SSL, Cache)          │
├────────────────────┬────────────────────────────┤
│  Flutter Web App   │     FastAPI Backend          │
│  (Static Files)    │     /api/v1/*               │
│                    │     /ws/*                    │
├────────────────────┴────────────────────────────┤
│              PostgreSQL + Redis                   │
└─────────────────────────────────────────────────┘
```

## Tech Stack

| Layer       | Technology                                        |
|-------------|--------------------------------------------------|
| Frontend    | Flutter 3.16+, Riverpod, GoRouter, Dio           |
| Backend     | FastAPI, SQLAlchemy 2.0 (async), Pydantic v2     |
| Database    | PostgreSQL 16, Redis 7                           |
| Auth        | JWT (access + refresh tokens), bcrypt             |
| Payments    | Stripe, Razorpay, Cash on Delivery, Wallet       |
| Real-time   | WebSockets (order tracking, vendor notifications) |
| Deployment  | Docker Compose, Nginx reverse proxy              |

## Features

### Multi-Vendor System
- Vendor registration with KYC verification
- Vendor dashboard (orders, products, analytics)
- Store timings & delivery zone management
- Commission tracking & automated payouts

### Customer Experience
- Browse products by category with full-text search
- Product detail with images, ratings, nutritional info
- Cart with vendor-separated items
- Order tracking with real-time WebSocket updates
- Favorites, reviews, wallet system

### Order Management
- Multi-vendor order splitting
- Coupon & promotion system
- Status tracking timeline (pending → delivered)
- Reorder functionality

### Admin Panel
- Vendor approval/rejection workflow
- Platform analytics dashboard
- Coupon management
- Payout management

---

## Project Structure

```
GroceryeCommerce/
├── backend/
│   ├── app/
│   │   ├── api/v1/          # API route handlers
│   │   ├── core/            # Security, permissions, exceptions
│   │   ├── models/          # SQLAlchemy ORM models
│   │   ├── schemas/         # Pydantic request/response schemas
│   │   ├── utils/           # Helper utilities
│   │   ├── config.py        # Settings (env-based)
│   │   ├── database.py      # Async DB engine & session
│   │   └── main.py          # FastAPI app entry point
│   ├── alembic/             # Database migrations
│   ├── Dockerfile
│   ├── requirements.txt
│   └── .env.example
├── frontend/
│   ├── lib/
│   │   ├── config/          # Theme, routes, constants
│   │   ├── models/          # Dart data models
│   │   ├── providers/       # Riverpod state management
│   │   ├── screens/         # UI screens
│   │   │   ├── auth/        # Login, Register
│   │   │   ├── cart/        # Cart screen
│   │   │   ├── favorites/   # Favorites screen
│   │   │   ├── home/        # Home, Main shell
│   │   │   ├── onboarding/  # Onboarding flow
│   │   │   ├── orders/      # Order list, Order detail
│   │   │   ├── product/     # Product list, Product detail
│   │   │   ├── profile/     # Profile screen
│   │   │   ├── search/      # Search screen
│   │   │   └── widgets/     # Shared components
│   │   └── services/        # API, Auth, WebSocket services
│   └── pubspec.yaml
├── nginx/
│   └── nginx.conf
├── docker-compose.yml
└── README.md
```

---

## Getting Started

### Prerequisites

- **Docker** & **Docker Compose** (for full-stack deployment)
- **Python 3.12+** (for backend development)
- **Flutter 3.16+** (for frontend development)
- **PostgreSQL 16** (if running locally without Docker)

### Quick Start with Docker

```bash
# 1. Clone the repository
git clone <repo-url>
cd GroceryeCommerce

# 2. Create backend environment file
cp backend/.env.example backend/.env
# Edit backend/.env with your settings

# 3. Start all services
docker-compose up -d

# 4. Run database migrations
docker-compose exec backend alembic upgrade head

# 5. Access the application
# Backend API:  http://localhost:8000
# API Docs:     http://localhost:8000/docs
# Frontend:     http://localhost (after Flutter web build)
```

### Local Backend Development

```bash
cd backend

# Create virtual environment
python -m venv .venv  # execute this only at first time
.venv\Scripts\activate  # Windows
# source .venv/bin/activate  # Linux/Mac

# Install dependencies
pip install -r requirements.txt

# Setup environment
cp .env.example .env
# Edit .env with your database connection

# Run migrations
alembic upgrade head

# Start development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Local Frontend Development

```bash
cd frontend

# Get dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Run on connected device
flutter run

# Build for web
flutter build web
```

---

## API Endpoints

### Authentication
| Method | Endpoint                  | Description          |
|--------|--------------------------|----------------------|
| POST   | `/api/v1/auth/register`  | Register new user    |
| POST   | `/api/v1/auth/login`     | Login (get tokens)   |
| POST   | `/api/v1/auth/refresh`   | Refresh access token |

### Products
| Method | Endpoint                         | Description            |
|--------|----------------------------------|------------------------|
| GET    | `/api/v1/products/`              | List products (filter) |
| GET    | `/api/v1/products/{id}`          | Product detail         |
| GET    | `/api/v1/products/search`        | Full-text search       |
| GET    | `/api/v1/products/categories`    | List categories        |
| POST   | `/api/v1/products/`              | Create product (vendor)|

### Orders
| Method | Endpoint                         | Description           |
|--------|----------------------------------|-----------------------|
| POST   | `/api/v1/orders/`                | Create order          |
| GET    | `/api/v1/orders/`                | List user orders      |
| GET    | `/api/v1/orders/{id}`            | Order detail          |
| PUT    | `/api/v1/orders/{id}/status`     | Update status         |
| POST   | `/api/v1/orders/{id}/cancel`     | Cancel order          |

### Vendors
| Method | Endpoint                         | Description           |
|--------|----------------------------------|-----------------------|
| POST   | `/api/v1/vendors/register`       | Register vendor       |
| GET    | `/api/v1/vendors/dashboard`      | Vendor dashboard      |
| GET    | `/api/v1/vendors/`               | Public vendor listing |

### Payments
| Method | Endpoint                         | Description           |
|--------|----------------------------------|-----------------------|
| POST   | `/api/v1/payments/initiate`      | Start payment         |
| POST   | `/api/v1/payments/webhook/*`     | Payment webhooks      |
| GET    | `/api/v1/payments/wallet`        | Wallet balance        |

### WebSocket
| Endpoint                          | Description              |
|-----------------------------------|--------------------------|
| `/ws/orders/{order_id}`          | Real-time order tracking |
| `/ws/vendor/{vendor_id}`         | Vendor notifications     |

> Full interactive API docs available at `/docs` (Swagger UI) and `/redoc`.

---

## Database Schema

### Core Tables
- **users** — Customers, vendors, admins with role-based access
- **addresses** — Multiple delivery addresses per user
- **vendors** — Store info, KYC, bank details, commission rates
- **vendor_documents** — KYC document uploads

### Product Tables
- **product_categories** — Hierarchical categories (self-referential)
- **products** — Full product catalog with TSVECTOR search
- **product_variants** — Size/weight variants
- **product_images** — Multiple images per product

### Order Tables
- **orders** — Orders with multi-vendor support, commission tracking
- **order_items** — Line items with snapshot pricing
- **order_status_history** — Full audit trail

### Payment Tables
- **payments** — Transaction records (Stripe, Razorpay, COD, wallet)
- **wallets** — User wallet balances
- **wallet_transactions** — Credit/debit history
- **vendor_payouts** — Vendor payment records

### Engagement Tables
- **reviews** — Product reviews with verified purchase flag
- **promotions** — Platform promotions
- **coupons** — Discount coupons with usage tracking

---

## Environment Variables

See [backend/.env.example](backend/.env.example) for the complete list. Key variables:

| Variable          | Description                    | Default              |
|-------------------|--------------------------------|----------------------|
| `DATABASE_URL`    | PostgreSQL connection string   | Required             |
| `SECRET_KEY`      | JWT signing key                | Required             |
| `REDIS_URL`       | Redis connection string        | `redis://localhost`  |
| `STRIPE_SECRET`   | Stripe API key                 | Optional             |
| `RAZORPAY_KEY`    | Razorpay key                   | Optional             |
| `CORS_ORIGINS`    | Allowed frontend origins       | `http://localhost:*` |

---

## Design System

The UI follows a warm, modern grocery app aesthetic:

| Token            | Value                  |
|------------------|------------------------|
| Primary          | `#FF6B2C` (warm orange)|
| Background       | `#FFF5F2` (soft pink)  |
| Surface          | `#FFE0D6` (peach)      |
| Success          | `#4CAF50`              |
| Font             | Poppins                |
| Border Radius    | 16px (cards), 24px (nav)|

---

## License

This project is proprietary. All rights reserved.
