# AgroChat System Output & Module Documentation

This document contains the visual output representations, architecture descriptions, and test records of the core modules in the **AgroChat Digital Agriculture Advisory & Farmer–Officer Communication Platform**.

---

## 1. The Single Application URL

The single connected entry point for the entire application is:

👉 **http://127.0.0.1:3000**

- When you open this link in any browser, the **Flutter Frontend** automatically communicates with the **FastAPI Backend (`http://127.0.0.1:8000`)** and the **MySQL 8.0 Database (`agrochat_db`)**.
- No other ports or tools need to be opened by the user or evaluator.
- Interactive API documentation is available at **http://127.0.0.1:8000/docs**.

---

## 2. Main Module Output Screenshots

All high-resolution screenshot images are saved in `documentation/screenshots/`:

| No. | Screen Name | File Path | Key Features Shown |
| :---: | :--- | :--- | :--- |
| **01** | **System Health & DB Verification** | `documentation/screenshots/01_system_health_verification.png` | Diagnostic startup verification showing `AgroChat API Connected`, `MySQL Status: connected`, and supported user roles. |
| **02** | **Swagger REST API Documentation** | `documentation/screenshots/01_swagger_api_documentation.png` | Interactive OpenAPI / Swagger UI at `http://127.0.0.1:8000/docs` listing all 40+ endpoints. |
| **03** | **Farmer Login Portal** | `documentation/screenshots/02_farmer_login_page.png` | Farmer login screen with prefilled demo credentials (`farmer@agrochat.com` / `Farmer@123`), password masking, and role selector. |
| **04** | **Officer Login Portal** | `documentation/screenshots/02_officer_login_page.png` | Agricultural Officer login screen with prefilled credentials (`officer@agrochat.com` / `Officer@123`). |
| **05** | **Farmer Registration Page** | `documentation/screenshots/02_farmer_registration_page.png` | Farmer sign-up form with name, email, phone, 11 Indic language selector, password, and confirmation. |
| **06** | **Officer Registration Page** | `documentation/screenshots/02_officer_registration_page.png` | Agricultural Officer registration form with government officer attributes and language selection. |
| **07** | **Farmer Home Dashboard** | `documentation/screenshots/03_farmer_dashboard.png` | Personalized greetings ("Namaste, Ramesh Kisan"), farm metrics (4.5 Ac, 1 Crop), quick action shortcuts (Add Farm, Add Crop, Ask Officer, Govt Schemes, Shop & Machinery). |
| **08** | **Farm Land Management** | `documentation/screenshots/04_farmer_farm_management.png` | Registered land parcel cards ("Green Acres Farm", Baramati, Pune, 4.5 Acres, Black Cotton soil, Drip irrigation, Owned), search filter, and "+ Add Farm" button. |
| **09** | **Crop Lifecycle Tracking** | `documentation/screenshots/05_farmer_crop_management.png` | Active crops ("Wheat HD-2967"), season tags (Rabi, Kharif, Zaid), stage indicator ("Vegetative"), sowing & estimated harvest dates, and "+ Add Crop" button. |
| **10** | **Farmer Profile & 11 Indic Languages** | `documentation/screenshots/06_farmer_profile_and_language.png` | Personal farmer profile, agricultural location details, and the 11 Indic language selector dropdown. |
| **11** | **Officer Workstation Dashboard** | `documentation/screenshots/07_officer_dashboard.png` | Officer greetings ("Welcome, Officer Dr. Ananya Sharma!"), Senior Extension Officer designation, Consultation Availability toggle (ON), and pending review counters. |
| **12** | **Farmer Requests Management Queue** | `documentation/screenshots/08_officer_requests_management.png` | Officer ticket review queue with search bar and status filters (`All`, `Open / Pending`, `My Assigned`, `Pending`, `Accepted`, `In Progress`, `Resolved`). |
| **13** | **Officer In-App Notifications** | `documentation/screenshots/09_officer_notifications.png` | Real-time notifications center for newly assigned farmer queries and chat responses. |
| **14** | **Officer Profile & Credentials** | `documentation/screenshots/10_officer_profile.png` | Professional qualifications (Ph.D., M.Sc. Agronomy), 10 years experience, Government department, Baramati jurisdiction, and consultation availability hours. |

---

## 3. Direct Navigation URLs for College Demo

For seamless demonstration, each screen can also be directly opened via URL query parameters:

| Target Page | Direct URL |
| :--- | :--- |
| **Farmer Login Page** | `http://127.0.0.1:3000/?page=login&role=farmer` |
| **Officer Login Page** | `http://127.0.0.1:3000/?page=login&role=officer` |
| **Farmer Registration Page** | `http://127.0.0.1:3000/?page=register&role=farmer` |
| **Officer Registration Page** | `http://127.0.0.1:3000/?page=register&role=officer` |
| **Farmer Dashboard** | `http://127.0.0.1:3000/?role=farmer` |
| **Farm Management** | `http://127.0.0.1:3000/?role=farmer&tab=farms` |
| **Crop Lifecycle** | `http://127.0.0.1:3000/?role=farmer&tab=crops` |
| **Farmer Profile & Languages** | `http://127.0.0.1:3000/?role=farmer&tab=profile` |
| **Officer Dashboard** | `http://127.0.0.1:3000/?role=officer` |
| **Officer Requests Queue** | `http://127.0.0.1:3000/?role=officer&tab=requests` |
| **Officer Notifications** | `http://127.0.0.1:3000/?role=officer&tab=notifications` |
| **Officer Profile & Availability**| `http://127.0.0.1:3000/?role=officer&tab=profile` |
| **FastAPI Swagger API Docs** | `http://127.0.0.1:8000/docs` |

---

## 4. Relational Database Summary (MySQL 8.0)

- **Database Name:** `agrochat_db`
- **Total Relational Tables:** 25 Tables
- **Record Count Summary:**

| Table Name | Records | Description |
| :--- | :---: | :--- |
| `users` | 57 | Farmer & Agricultural Officer accounts |
| `notifications` | 15 | System notifications & alerts |
| `products` | 9 | Agricultural seeds, fertilizers, tools |
| `product_categories` | 9 | Marketplace product categories |
| `schemes` | 8 | Central and state welfare schemes |
| `farms` | 6 | Registered farm land parcels |
| `crops` | 6 | Active crop cycles and monitoring |
| `farmer_profiles` | 6 | Detailed farmer profiles & land size |
| `shopping_carts` | 6 | User shopping carts |
| `assistance_requests`| 5 | Farmer support queries with priority |
| `consultations` | 5 | Officer advisory consultation sessions |
| `messages` | 5 | Real-time chat dialogue messages |
| `request_attachments`| 5 | Photos of crop issues and pests |
| `subsidy_enquiries` | 5 | Applications for government subsidies |
| `equipment_rentals` | 5 | Available farm machinery registry |
| `rental_bookings` | 5 | Equipment rental bookings by farmers |
| `agricultural_services` | 5 | Soil testing, drone spraying services |
| `loan_enquiries` | 5 | Agri-credit and KCC inquiries |
| `orders` | 5 | Farmer marketplace orders |
| `order_items` | 5 | Order items and quantities |
| `livestock` | 5 | Farm livestock registry |
| `officer_profiles` | 1 | Agricultural officer profile & credentials |
| `cart_items` | 1 | Items in active shopping carts |
| `loan_documents` | 0 | Loan KYC documents |
| `subsidy_documents`| 0 | Subsidy proof attachments |
