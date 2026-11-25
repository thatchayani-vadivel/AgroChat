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

## 2. Android Mobile Emulator Output Screenshots (412 × 915 Portrait)

The following screenshots represent the native Android Mobile Emulator output rendered in full smartphone portrait aspect ratio (`412 × 915`):

| No. | Screen Name | File Path | Mobile Features & Layout |
| :---: | :--- | :--- | :--- |
| **M01** | **Mobile Farmer Login** | `documentation/emulator_screenshots/01_mobile_farmer_login.png` | Native Android mobile app bar, role toggle pill (`Farmer` / `Agricultural Officer`), prefilled credentials, secure password masking. |
| **M02** | **Mobile Farmer Registration** | `documentation/emulator_screenshots/02_mobile_farmer_register.png` | Vertical mobile scrolling form with name, email, phone, location fields, 11 Indic language selector, and register button. |
| **M03** | **Mobile Farmer Dashboard** | `documentation/emulator_screenshots/03_mobile_farmer_dashboard.png` | Mobile cards: Namaste welcome banner, farm acreage & active crop counter cards, quick action tiles, bottom navigation bar (`Home`, `Farms`, `Crops`, `Profile`). |
| **M04** | **Mobile My Farms Management** | `documentation/emulator_screenshots/04_mobile_farmer_farms.png` | Touch-optimized farm cards ("Green Acres Farm", 4.5 Ac, Black Cotton soil, Drip irrigation, Baramati location), mobile search bar, and "+ Add Farm" button. |
| **M05** | **Mobile Crop Management** | `documentation/emulator_screenshots/05_mobile_farmer_crops.png` | Crop lifecycle cards ("Wheat HD-2967", Rabi season, Vegetative growth stage, sowing & harvest timeline) with status badges and "+ Add Crop" button. |
| **M06** | **Mobile Farmer Profile & Languages** | `documentation/emulator_screenshots/06_mobile_farmer_profile.png` | Profile avatar card, contact details, agricultural land size, 11 Indic language dropdown selector, and mobile logout action. |
| **M07** | **Mobile Officer Login** | `documentation/emulator_screenshots/07_mobile_officer_login.png` | Dedicated Agricultural Officer login screen on mobile viewport with prefilled demo officer credentials. |
| **M08** | **Mobile Officer Registration** | `documentation/emulator_screenshots/08_mobile_officer_register.png` | Mobile registration portal for agricultural extension officers with employee code, department, jurisdiction, and language selection. |
| **M09** | **Mobile Officer Dashboard** | `documentation/emulator_screenshots/09_mobile_officer_dashboard.png` | Officer greeting card ("Dr. Ananya Sharma"), Senior Extension Officer badge, consultation availability toggle (ON), pending review metrics, and bottom nav. |
| **M10** | **Mobile Officer Requests Queue** | `documentation/emulator_screenshots/10_mobile_officer_requests.png` | Touch-friendly filter pills (`All`, `Open / Pending`, `My Assigned`, `Resolved`), query search bar, farmer inquiry cards with priority tags. |
| **M11** | **Mobile Officer Notifications** | `documentation/emulator_screenshots/11_mobile_officer_notifications.png` | Mobile notifications center with unread message badges, farmer consultation assignment alerts, and timestamped updates. |
| **M12** | **Mobile Officer Profile** | `documentation/emulator_screenshots/12_mobile_officer_profile.png` | Officer professional credentials, Ph.D./M.Sc. qualifications, government jurisdiction, contact info, and availability hours. |
| **M13** | **Mobile Schemes & Subsidies** | `documentation/emulator_screenshots/13_mobile_schemes_and_subsidies.png` | Touch-optimized mobile schemes & subsidies portal with category filter chips (`ALL`, `SCHEME`, `SUBSIDY`, `LOAN`, `INSURANCE`), subsidy details, and officer enquiry tracking. |
| **M14** | **Mobile Farmer–Officer Chat** | `documentation/emulator_screenshots/14_mobile_farmer_officer_chat.png` | Direct consultation chat between Farmer Ramesh Kisan and Officer Dr. Ananya Sharma with timestamps, sent/received message bubbles, dosage instructions, and text input box. |
| **M15** | **Mobile Loan & Insurance Info** | `documentation/emulator_screenshots/15_mobile_loan_and_insurance.png` | Mobile view of KCC crop loan (7% subvention), AIF term loans, PMFBY crop insurance, and Livestock insurance with eligibility criteria. |
| **M16** | **Mobile Agricultural Marketplace** | `documentation/emulator_screenshots/16_mobile_agricultural_marketplace.png` | Mobile e-commerce catalog featuring certified seeds, fertilizers, neem biopesticides, tools, prices in INR, Add to Cart buttons, and rentals tab. |

---

## 3. Desktop Application Output Screenshots (1280 × 900)

All high-resolution desktop view screenshot images are saved in `documentation/screenshots/`:

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
| **15** | **Government Schemes & Subsidies** | `documentation/screenshots/11_government_schemes_and_subsidies.png` | Central & State agricultural schemes (PM-KISAN, PM-KUSUM 60% solar pump subsidy, Soil Health Card, Micro Irrigation, KCC 7% loan, PMFBY crop insurance), category filter chips, search bar, and direct enquiry submission. |
| **16** | **Farmer–Officer Chat Screen** | `documentation/screenshots/12_farmer_officer_chat_screen.png` | Real-time advisory conversation interface between Farmer Ramesh Kisan and Officer Dr. Ananya Sharma regarding pest control (Ashwini aphids/whiteflies), treatment prescriptions (Neem Baan 10,000 ppm, Imidacloprid), and chat message history. |
| **17** | **Loan and Insurance Information** | `documentation/screenshots/13_loan_and_insurance_screen.png` | Agricultural financial advisory showing Kisan Credit Card (KCC 7% subvention), Agriculture Infrastructure Fund (AIF), PM Fasal Bima Yojana (PMFBY), and Livestock Insurance Scheme details. |
| **18** | **Agricultural Marketplace Screen** | `documentation/screenshots/14_agricultural_marketplace_screen.png` | Agricultural product marketplace with certified seeds (Wheat HD-2967), IFFCO urea, DAP fertilizers, bio-pesticides, tools, prices, stock quantities, cart counters, and machinery rental portal. |

---

## 4. Direct Navigation URLs for College Demo

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
| **Government Schemes & Subsidies** | `http://127.0.0.1:3000/?role=farmer&tab=schemes` |
| **Farmer–Officer Advisory Chat** | `http://127.0.0.1:3000/?role=farmer&tab=chat` |
| **Loan & Insurance Information** | `http://127.0.0.1:3000/?role=farmer&tab=loans&cat=loan` |
| **Agricultural Marketplace** | `http://127.0.0.1:3000/?role=farmer&tab=marketplace` |
| **Officer Dashboard** | `http://127.0.0.1:3000/?role=officer` |
| **Officer Requests Queue** | `http://127.0.0.1:3000/?role=officer&tab=requests` |
| **Officer Notifications** | `http://127.0.0.1:3000/?role=officer&tab=notifications` |
| **Officer Profile & Availability**| `http://127.0.0.1:3000/?role=officer&tab=profile` |
| **FastAPI Swagger API Docs** | `http://127.0.0.1:8000/docs` |

---

## 5. Relational Database Summary (MySQL 8.0)

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
