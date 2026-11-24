# AgroChat System Output & Module Documentation

This document contains the visual output representations, architecture descriptions, and test records of the core modules in the **AgroChat Digital Agriculture Advisory & Farmer–Officer Communication Platform**.

---

## 1. System Modules Overview

AgroChat is built with a strictly **two-role** architecture:

```
                          ┌─────────────────────────────┐
                          │    AgroChat Mobile / Web    │
                          │    (Flutter 3.x Frontend)   │
                          └──────────────┬──────────────┘
                                         │
                                         ▼
                    ┌────────────────────────────────────────┐
                    │       Role Selection & Login           │
                    ├────────────────────┬───────────────────┤
                    │   Farmer Portal    │   Officer Portal  │
                    └─────────┬──────────┴─────────┬─────────┘
                              │                    │
              ┌───────────────┴──────┐      ┌──────┴────────────────┐
              │ • Farm Management    │      │ • Request Review      │
              │ • Crop Advisory      │      │ • Consultations       │
              │ • Assistance Request │      │ • Issue Advisory      │
              │ • Schemes/Subsidies  │      │ • Availability Status │
              │ • Equipment Rental   │      │ • Farmer Notifications│
              └───────────────┬──────┘      └──────┬────────────────┘
                              │                    │
                              ▼                    ▼
                    ┌────────────────────────────────────────┐
                    │      FastAPI REST API (Port 8000)      │
                    │      JWT Authentication & PyMySQL      │
                    └────────────────────┬───────────────────┘
                                         │
                                         ▼
                    ┌────────────────────────────────────────┐
                    │      MySQL 8.0 Database (25 Tables)    │
                    │      `agrochat_db` on Port 3306        │
                    └────────────────────────────────────────┘
```

---

## 2. Main Output Screens & Image Assets

The following verified output screenshots are located in `documentation/screenshots/`:

| No. | Screen Name | File Path | Description |
| :--- | :--- | :--- | :--- |
| **01** | **Backend API Swagger Documentation** | `documentation/screenshots/01_swagger_api_documentation.png` | Complete interactive OpenAPI/Swagger specification testing UI at `http://127.0.0.1:8000/docs` with all endpoints categorized. |
| **02** | **Role Selection & Authentication** | `documentation/screenshots/02_login_and_role_selection.png` | AgroChat unified login screen showing Farmer and Agricultural Officer tabs, prefilled credentials, and role selector. |
| **03** | **System Health & Connectivity Verification** | `documentation/screenshots/01_system_health_verification.png` | Splash screen diagnostic check verifying FastAPI availability (`/health`) and MySQL database connectivity. |

---

## 3. Detailed Module Functionality for Project Documentation

### Module 1: Role-Based Authentication & Access Control
- **Purpose:** Secure JWT-based entry point enforcing strict separation between **Farmer** and **Agricultural Officer** accounts.
- **Key Features:**
  - Role-specific login endpoints (`/api/auth/login/farmer`, `/api/auth/login/officer`).
  - Passwords hashed using standard `bcrypt` algorithms.
  - JWT tokens issued with 24-hour expiration (`expires_in: 86400`).
  - Form validation with real-time error indicators.
- **Demo Credentials:**
  - **Farmer:** `farmer@agrochat.com` / `Farmer@123`
  - **Agricultural Officer:** `officer@agrochat.com` / `Officer@123`

---

### Module 2: Farmer Advisory & Farm/Crop Management
- **Purpose:** Enables registered farmers to record their land holdings, track crops across growth stages, and view personalized agricultural advisories.
- **Key Features:**
  - **Farm Registration:** Land area in acres, soil type (Alluvial, Black, Clay, Red), irrigation sources (Borewell, Canal, Drip).
  - **Crop Lifecycle Tracking:** Sowing date, estimated harvest date, growth stage (Vegetative, Flowering, Ripening).
  - **Indic Advisory:** Personalized advisory feeds rendered in English and 11 Indic languages (Hindi, Tamil, Telugu, Kannada, Marathi, Punjabi, Gujarati, Malayalam, Bengali, Odia, Assamese).

---

### Module 3: Farmer Assistance Request & Officer Consultations
- **Purpose:** Direct digital communication channel between farmers facing pest/disease/crop issues and government agricultural officers.
- **Key Features:**
  - **Create Request:** Select farm and crop, describe issue, attach field photographs.
  - **Urgency Levels:** Low, Medium, High, and Critical alerts.
  - **Status Lifecycle:** `SUBMITTED` &rarr; `UNDER_REVIEW` &rarr; `ACCEPTED` / `REJECTED` &rarr; `RESOLVED`.
  - **Consultation Thread:** Interactive chat messages between farmer and assigned officer with attachment uploads.

---

### Module 4: Government Schemes & Subsidies Portal
- **Purpose:** Digital repository of state and national welfare schemes for farmers.
- **Key Features:**
  - **Scheme Directory:** PM-KISAN, Pradhan Mantri Fasal Bima Yojana (PMFBY), Sub-Mission on Agricultural Mechanization (SMAM), Micro Irrigation schemes.
  - **Eligibility Calculator:** Automated check against farmer's landholding size, crop type, and state.
  - **Subsidy Enquiries:** Submission of subsidy requests with document verification tracking.

---

### Module 5: Agricultural Equipment Rental & Services
- **Purpose:** Transparent marketplace connecting farmers with nearby machinery providers.
- **Key Features:**
  - **Equipment Catalog:** Tractors, Combine Harvesters, Power Tillers, Drones, Laser Levelers.
  - **Rental Booking:** Transparent daily and hourly rates with booking confirmation.
  - **Cash on Delivery / UPI on Delivery:** Practical offline rural payment workflow.

---

### Module 6: Agricultural Officer Dashboard & Queue Management
- **Purpose:** Administrative workstation for agricultural extension officers.
- **Key Features:**
  - **Pending Requests Queue:** Real-time counter and filter for unassigned farmer queries.
  - **Action Center:** Single-click request acceptance, rejection with reason, or status escalation.
  - **Officer Availability Toggle:** Online/offline toggle for dynamic field assignment.

---

### Module 7: Database Architecture (MySQL 8.0)
- **Database Name:** `agrochat_db`
- **Total Relational Tables:** 25 Tables
- **Record Count Summary:**

| Table Name | Record Count | Description |
| :--- | :--- | :--- |
| `users` | 57 records | Farmer & Agricultural Officer user accounts |
| `farmer_profiles` | 6 records | Land size, experience, and profile attributes |
| `officer_profiles` | 1 record | Government designation, department, specialization |
| `farms` | 6 records | Geo-located agricultural land parcels |
| `crops` | 6 records | Active crop cycles and stage monitoring |
| `livestock` | 5 records | Farm animal registry |
| `assistance_requests` | 5 records | Farmer support tickets with priority levels |
| `consultations` | 5 records | Officer-farmer advisory consultation sessions |
| `messages` | 5 records | Real-time chat dialogue messages |
| `request_attachments`| 5 records | Photographic evidence of crop/pest issues |
| `schemes` | 8 records | Government agricultural subsidies and schemes |
| `subsidy_enquiries` | 5 records | Farmer applications for government aid |
| `equipment_rentals` | 5 records | Farm machinery rental registry |
| `rental_bookings` | 5 records | Bookings made by farmers for equipment |
| `products` | 9 records | Seeds, fertilizers, tools catalog |
| `product_categories`| 9 records | Hierarchical marketplace categories |
| `orders` | 5 records | Farmer purchase orders |
| `order_items` | 5 records | Order line items |
| `shopping_carts` | 6 records | Active shopping carts per user |
| `cart_items` | 1 record | Saved cart items |
| `agricultural_services` | 5 records | Soil testing, drone spraying, vet visits |
| `loan_enquiries` | 5 records | Agri-finance and Kisan Credit Card enquiries |
| `notifications` | 15 records | In-app alerts for status updates and messages |
| `loan_documents` | 0 records | Uploaded loan KYC files |
| `subsidy_documents`| 0 records | Uploaded subsidy proof files |

---

## 4. How to Capture Live High-Resolution Screenshots for Your Final Report

Since the application is running live in your browser:

1. **Farmer Screens:**
   - In Chrome at `http://127.0.0.1:3000`, click **Sign In as Farmer** (credentials are prefilled).
   - Press **Windows Key + Shift + S** (Windows Snipping Tool).
   - Capture:
     - **Farmer Home Dashboard**
     - **Farm Management Tab** (click bottom bar icon 2)
     - **Crop Management Tab** (click bottom bar icon 3)
     - **Profile & Language Tab** (click bottom bar icon 4)
2. **Officer Screens:**
   - Click **Logout** in Farmer Profile.
   - Select **Agricultural Officer** tab and click **Sign In as Agricultural Officer**.
   - Capture:
     - **Officer Dashboard**
     - **Requests Review Queue** (click bottom bar icon 2)
     - **Notifications Tab** (click bottom bar icon 3)
3. **Save Screenshots:**
   - Paste or save each screenshot into your documentation report under `Results and Output Screens`.
