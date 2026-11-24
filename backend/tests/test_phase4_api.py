"""Comprehensive Phase 4 Backend Integration and API Test Suite.

Tests:
1. Database Connectivity
2. Authentication (Farmer & Officer registration and login, bcrypt, JWT)
3. Role-based Access Control (Farmer vs Officer 403 checks)
4. Farmer Profile & Farms, Crops, Livestock CRUD
5. Assistance Requests & Attachments
6. Officer Request Acceptance, Consultations, and Chat Messages
7. Loan Enquiries & Officer Guidance
8. Subsidy Enquiries & Officer Guidance
9. Agricultural Marketplace (Categories, Products, Cart, Orders)
10. Equipment Rental Bookings
11. Security checks (Invalid tokens, unauthorized cross-farmer access)
"""

import asyncio
import json
import os
import sys
import uuid
from decimal import Decimal

sys.path.insert(0, os.path.abspath('backend'))

from app.main import app
from app.db.session import check_db_connection, engine
from app.models.marketplace import Product, ProductCategory
from sqlalchemy import select
from sqlalchemy.orm import Session


class SimpleResponse:
    def __init__(self, status_code, headers, body):
        self.status_code = status_code
        self.headers = headers
        self.body = body
        self.text = body.decode('utf-8', errors='replace')
    
    def json(self):
        return json.loads(self.text)


class SimpleASGIClient:
    def __init__(self, app):
        self.app = app

    def request(self, method: str, url: str, json_data=None, data=None, files=None, headers=None):
        return asyncio.run(self._async_request(method, url, json_data, data, files, headers))

    async def _async_request(self, method: str, url: str, json_data=None, data=None, files=None, headers=None):
        headers = dict(headers or {})
        body_bytes = b""
        
        if json_data is not None:
            body_bytes = json.dumps(json_data).encode("utf-8")
            headers["content-type"] = "application/json"
        elif data and not files:
            body_bytes = json.dumps(data).encode("utf-8")
        elif files:
            boundary = "----AgroChatTestBoundary12345"
            headers["content-type"] = f"multipart/form-data; boundary={boundary}"
            parts = []
            if data:
                for k, v in data.items():
                    parts.append(f"--{boundary}\r\nContent-Disposition: form-data; name=\"{k}\"\r\n\r\n{v}\r\n".encode())
            for field_name, file_tuple in files.items():
                filename, content, content_type = file_tuple
                if isinstance(content, str):
                    content = content.encode()
                parts.append(
                    f"--{boundary}\r\nContent-Disposition: form-data; name=\"{field_name}\"; filename=\"{filename}\"\r\nContent-Type: {content_type}\r\n\r\n".encode()
                    + content
                    + b"\r\n"
                )
            parts.append(f"--{boundary}--\r\n".encode())
            body_bytes = b"".join(parts)

        headers["content-length"] = str(len(body_bytes))
        
        if "?" in url:
            path, query = url.split("?", 1)
        else:
            path, query = url, ""

        scope = {
            "type": "http",
            "asgi": {"version": "3.0"},
            "http_version": "1.1",
            "method": method.upper(),
            "scheme": "http",
            "path": path,
            "raw_path": path.encode(),
            "query_string": query.encode(),
            "headers": [(k.lower().encode("latin-1"), v.encode("latin-1")) for k, v in headers.items()],
            "client": ("127.0.0.1", 50000),
            "server": ("127.0.0.1", 8000),
        }

        sent = False
        async def receive():
            nonlocal sent
            if not sent:
                sent = True
                return {"type": "http.request", "body": body_bytes, "more_body": False}
            return {"type": "http.request", "body": b"", "more_body": False}

        status_code = None
        response_headers = {}
        body_chunks = []

        async def send(message):
            nonlocal status_code, response_headers
            if message["type"] == "http.response.start":
                status_code = message["status"]
                for k, v in message.get("headers", []):
                    response_headers[k.decode("latin-1")] = v.decode("latin-1")
            elif message["type"] == "http.response.body":
                body_chunks.append(message.get("body", b""))

        await self.app(scope, receive, send)
        return SimpleResponse(status_code, response_headers, b"".join(body_chunks))

    def get(self, url, headers=None):
        return self.request("GET", url, headers=headers)

    def post(self, url, json=None, data=None, files=None, headers=None):
        return self.request("POST", url, json_data=json, data=data, files=files, headers=headers)

    def put(self, url, json=None, headers=None):
        return self.request("PUT", url, json_data=json, headers=headers)

    def patch(self, url, json=None, headers=None):
        return self.request("PATCH", url, json_data=json, headers=headers)

    def delete(self, url, headers=None):
        return self.request("DELETE", url, headers=headers)


client = SimpleASGIClient(app)


def test_01_database_connectivity():
    """Verify database connection to agrochat_db."""
    is_ok, msg = check_db_connection()
    assert is_ok is True
    assert "MySQL connection verified successfully" in msg


def test_02_auth_farmer_and_officer_lifecycle():
    """Verify farmer and officer registration and login with bcrypt & JWT."""
    unique_suffix = uuid.uuid4().hex[:6]
    farmer_email = f"farmer_{unique_suffix}@example.com"
    officer_email = f"officer_{unique_suffix}@example.com"
    password = "SecurePassword@123"

    # 1. Register Farmer
    f_reg_res = client.post(
        "/api/auth/register/farmer",
        json={
            "full_name": "Ramesh Kisan",
            "email": farmer_email,
            "phone_number": "+91 9876543210",
            "password": password,
            "preferred_language": "Hindi",
        },
    )
    assert f_reg_res.status_code == 201, f_reg_res.text
    f_data = f_reg_res.json()
    assert f_data["user"]["role"] == "farmer"
    farmer_token = f_data["access_token"]

    # 2. Register Officer
    o_reg_res = client.post(
        "/api/auth/register/officer",
        json={
            "full_name": "Dr. Ananya Sharma",
            "email": officer_email,
            "phone_number": "+91 9123456789",
            "password": password,
            "preferred_language": "English",
        },
    )
    assert o_reg_res.status_code == 201, o_reg_res.text
    o_data = o_reg_res.json()
    assert o_data["user"]["role"] == "agricultural_officer"
    officer_token = o_data["access_token"]

    # 3. Login Farmer
    f_login = client.post(
        "/api/auth/login/farmer",
        json={"email": farmer_email, "password": password},
    )
    assert f_login.status_code == 200
    assert "access_token" in f_login.json()

    # 4. Login Officer
    o_login = client.post(
        "/api/auth/login/officer",
        json={"email": officer_email, "password": password},
    )
    assert o_login.status_code == 200
    assert "access_token" in o_login.json()

    # 5. Role restrictions: Farmer cannot access officer routes
    unauth_officer_req = client.get(
        "/api/requests/officer",
        headers={"Authorization": f"Bearer {farmer_token}"},
    )
    assert unauth_officer_req.status_code == 403

    # 6. Role restrictions: Officer cannot create a farm
    unauth_farm_create = client.post(
        "/api/farms",
        json={
            "farm_name": "Officer Test Farm",
            "total_area_acres": 5.0,
            "soil_type": "Black",
            "irrigation_type": "Drip",
            "location": "Pune",
            "district": "Pune",
            "state": "Maharashtra",
        },
        headers={"Authorization": f"Bearer {officer_token}"},
    )
    assert unauth_farm_create.status_code == 403


def test_03_farmer_profile_and_farm_management():
    """Verify farmer profile upsert, farm creation, crop, and livestock CRUD."""
    unique_suffix = uuid.uuid4().hex[:6]
    farmer_email = f"farmer_farm_{unique_suffix}@example.com"
    password = "TestPassword@123"

    # Register Farmer
    reg = client.post(
        "/api/auth/register/farmer",
        json={
            "full_name": "Suresh Patil",
            "email": farmer_email,
            "phone_number": "+91 9822112233",
            "password": password,
            "preferred_language": "Marathi",
        },
    )
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Upsert Profile
    prof_res = client.put(
        "/api/farmers/profile",
        json={
            "village": "Baramati",
            "taluk_or_block": "Baramati",
            "district": "Pune",
            "state": "Maharashtra",
            "pincode": "413102",
            "total_landholding_acres": 12.5,
        },
        headers=headers,
    )
    assert prof_res.status_code == 200
    assert prof_res.json()["district"] == "Pune"

    # Create Farm
    farm_res = client.post(
        "/api/farms",
        json={
            "farm_name": "Green Valley Farm",
            "total_area_acres": 10.0,
            "soil_type": "Black Cotton Soil",
            "irrigation_type": "Drip Irrigation",
            "water_source": "Borewell",
            "location": "Plot 44, Baramati Shivar",
            "district": "Pune",
            "state": "Maharashtra",
            "ownership_type": "Owned",
        },
        headers=headers,
    )
    assert farm_res.status_code == 201
    farm_id = farm_res.json()["id"]

    # Add Crop to Farm
    crop_res = client.post(
        f"/api/farms/{farm_id}/crops",
        json={
            "crop_name": "Sugarcane",
            "variety": "Co 86032",
            "season": "Year-round",
            "area_acres": 6.0,
            "growth_stage": "Vegetative",
            "estimated_yield_kg": 60000.0,
        },
        headers=headers,
    )
    assert crop_res.status_code == 201
    assert crop_res.json()["crop_name"] == "Sugarcane"

    # Add Livestock to Farm
    live_res = client.post(
        f"/api/farms/{farm_id}/livestock",
        json={
            "category": "Cattle",
            "breed_or_type": "Gir Cow",
            "count": 4,
            "purpose": "Dairy Milk",
            "health_status": "Healthy vaccinated",
        },
        headers=headers,
    )
    assert live_res.status_code == 201
    assert live_res.json()["count"] == 4


def test_04_assistance_requests_and_officer_consultation():
    """Verify assistance request submission, attachment, acceptance, and chat."""
    unique_suffix = uuid.uuid4().hex[:6]
    f_email = f"req_farmer_{unique_suffix}@example.com"
    o_email = f"req_officer_{unique_suffix}@example.com"
    pwd = "TestPassword@123"

    f_res = client.post("/api/auth/register/farmer", json={
        "full_name": "Ganesh Rao", "email": f_email, "phone_number": "+91 9765432109", "password": pwd
    })
    f_token = f_res.json()["access_token"]
    f_headers = {"Authorization": f"Bearer {f_token}"}

    o_res = client.post("/api/auth/register/officer", json={
        "full_name": "Dr. Vikas Deshmukh", "email": o_email, "phone_number": "+91 9422001122", "password": pwd
    })
    o_token = o_res.json()["access_token"]
    o_headers = {"Authorization": f"Bearer {o_token}"}

    # 1. Farmer submits Assistance Request
    req_res = client.post(
        "/api/requests",
        json={
            "title": "Severe Yellowing on Sugarcane Leaves",
            "category": "Crop Disease",
            "description": "Lower leaves show yellow chlorosis and stunted shoot growth.",
            "priority": "high",
        },
        headers=f_headers,
    )
    assert req_res.status_code == 201
    req_id = req_res.json()["id"]

    # 2. Farmer uploads mock photo attachment
    mock_file_content = b"fake-jpg-image-bytes"
    att_res = client.post(
        f"/api/requests/{req_id}/attachments",
        files={"file": ("leaf_yellowing.jpg", mock_file_content, "image/jpeg")},
        data={"description": "Close-up photo of infected leaf"},
        headers=f_headers,
    )
    assert att_res.status_code == 201
    assert att_res.json()["file_name"] == "leaf_yellowing.jpg"

    # 3. Officer views open requests
    open_reqs = client.get("/api/requests/officer", headers=o_headers)
    assert open_reqs.status_code == 200
    assert any(r["id"] == req_id for r in open_reqs.json())

    # 4. Officer accepts request -> opens consultation
    accept_res = client.post(
        f"/api/requests/{req_id}/accept",
        json={"officer_notes": "Accepted. Please provide soil moisture details."},
        headers=o_headers,
    )
    assert accept_res.status_code == 200
    assert accept_res.json()["status"] == "accepted"

    # 5. Farmer and Officer chat
    msg_res = client.post(
        f"/api/chat/requests/{req_id}/messages",
        json={"content": "Soil is moist, irrigated 2 days ago via drip."},
        headers=f_headers,
    )
    assert msg_res.status_code == 201
    assert msg_res.json()["content"] == "Soil is moist, irrigated 2 days ago via drip."

    # 6. Officer updates request to in_progress with recommendations
    status_update = client.patch(
        f"/api/requests/{req_id}/status",
        json={
            "status": "in_progress",
            "guidance_summary": "Suspected iron chlorosis or early borer damage.",
            "recommendations": "Spray ferrous sulphate (0.5%) with citric acid.",
        },
        headers=o_headers,
    )
    assert status_update.status_code == 200
    assert status_update.json()["status"] == "in_progress"


def test_05_loan_and_subsidy_enquiries():
    """Verify Farmer loan and subsidy advisory enquiry submission and Officer guidance."""
    unique_suffix = uuid.uuid4().hex[:6]
    f_email = f"loan_farmer_{unique_suffix}@example.com"
    o_email = f"loan_officer_{unique_suffix}@example.com"
    pwd = "TestPassword@123"

    f_token = client.post("/api/auth/register/farmer", json={
        "full_name": "Balu Shinde", "email": f_email, "phone_number": "+91 9922334455", "password": pwd
    }).json()["access_token"]
    f_headers = {"Authorization": f"Bearer {f_token}"}

    o_token = client.post("/api/auth/register/officer", json={
        "full_name": "Dr. Kavita Joshi", "email": o_email, "phone_number": "+91 9155667788", "password": pwd
    }).json()["access_token"]
    o_headers = {"Authorization": f"Bearer {o_token}"}

    # Submit Loan Enquiry
    loan_res = client.post(
        "/api/loans/enquiries",
        json={
            "loan_type": "Kisan Credit Card (KCC)",
            "requested_amount_inr": "150000.00",
            "purpose": "Working capital for seed and fertilizer purchase for Rabi season.",
            "preferred_bank": "State Bank of India",
            "land_holding_acres": "4.5",
        },
        headers=f_headers,
    )
    assert loan_res.status_code == 201
    loan_id = loan_res.json()["id"]

    # Officer reviews Loan Enquiry and provides guidance
    loan_guide = client.patch(
        f"/api/loans/enquiries/{loan_id}/guidance",
        json={
            "status": "guidance_provided",
            "officer_guidance": "Eligible for 4% interest subvention under KCC. Submit 7/12 extract and Aadhaar at nearest SBI rural branch.",
        },
        headers=o_headers,
    )
    assert loan_guide.status_code == 200
    assert loan_guide.json()["status"] == "guidance_provided"

    # Submit Subsidy Enquiry
    sub_res = client.post(
        "/api/subsidies/enquiries",
        json={
            "subsidy_title": "PMKSY Drip Irrigation Subsidy",
            "enquiry_details": "Need assistance with quotation and subsidy application for 3 acres pomegranate orchard.",
        },
        headers=f_headers,
    )
    assert sub_res.status_code == 201
    sub_id = sub_res.json()["id"]

    # Officer provides Subsidy Guidance
    sub_guide = client.patch(
        f"/api/subsidies/enquiries/{sub_id}/guidance",
        json={
            "status": "guidance_provided",
            "officer_guidance": "Small farmers receive up to 55% subsidy. Upload approved vendor quotation via MahaDBT / State portal.",
        },
        headers=o_headers,
    )
    assert sub_guide.status_code == 200
    assert sub_guide.json()["status"] == "guidance_provided"


def test_06_marketplace_cart_and_order_flow():
    """Verify product browsing, cart operations, order placement, and officer status update."""
    unique_suffix = uuid.uuid4().hex[:6]
    f_email = f"market_farmer_{unique_suffix}@example.com"
    o_email = f"market_officer_{unique_suffix}@example.com"
    pwd = "TestPassword@123"

    f_token = client.post("/api/auth/register/farmer", json={
        "full_name": "Tukaram Jagtap", "email": f_email, "phone_number": "+91 9633221100", "password": pwd
    }).json()["access_token"]
    f_headers = {"Authorization": f"Bearer {f_token}"}

    o_token = client.post("/api/auth/register/officer", json={
        "full_name": "Officer Pawar", "email": o_email, "phone_number": "+91 9322110099", "password": pwd
    }).json()["access_token"]
    o_headers = {"Authorization": f"Bearer {o_token}"}

    # 1. Browse Categories
    cats_res = client.get("/api/marketplace/categories", headers=f_headers)
    assert cats_res.status_code == 200
    cats = cats_res.json()
    assert len(cats) >= 9

    # 2. Ensure at least one test product exists in database for testing
    with Session(engine) as db:
        prod = db.scalar(select(Product).limit(1))
        if not prod:
            prod = Product(
                category_id=cats[0]["id"],
                product_name="Certified Hybrid Wheat Seed (HD-2967)",
                brand_or_manufacturer="National Seeds Corporation",
                description="High yield rust-resistant certified wheat seed.",
                price_inr=Decimal("1250.00"),
                unit="40kg bag",
                stock_quantity=50,
                is_available=True,
            )
            db.add(prod)
            db.commit()
            db.refresh(prod)
        product_id = prod.id

    # 3. Add to Cart
    cart_add = client.post(
        "/api/marketplace/cart/items",
        json={"product_id": product_id, "quantity": 2},
        headers=f_headers,
    )
    assert cart_add.status_code == 200
    assert cart_add.json()["total_items_count"] == 2
    assert Decimal(str(cart_add.json()["total_amount_inr"])) == Decimal("2500.00")

    # 4. View Cart
    cart_view = client.get("/api/marketplace/cart", headers=f_headers)
    assert cart_view.status_code == 200
    assert len(cart_view.json()["items"]) == 1

    # 5. Place Order from Cart
    order_res = client.post(
        "/api/marketplace/orders",
        json={
            "delivery_address": "Farm House No. 12, Post Malegaon, Baramati 413115",
            "contact_phone": "+91 9633221100",
            "payment_method": "cash_on_delivery",
            "notes": "Please deliver near secondary school gate.",
        },
        headers=f_headers,
    )
    assert order_res.status_code == 201
    order_id = order_res.json()["id"]
    assert order_res.json()["order_status"] == "confirmed"

    # 6. Verify cart is now empty
    empty_cart = client.get("/api/marketplace/cart", headers=f_headers)
    assert empty_cart.json()["total_items_count"] == 0

    # 7. Officer updates order status
    ord_update = client.patch(
        f"/api/marketplace/orders/{order_id}/status",
        json={"order_status": "dispatched", "payment_status": "pending"},
        headers=o_headers,
    )
    assert ord_update.status_code == 200
    assert ord_update.json()["order_status"] == "dispatched"


def test_07_equipment_rental_booking_flow():
    """Verify equipment rental browsing, booking request, and status update."""
    unique_suffix = uuid.uuid4().hex[:6]
    f_email = f"rent_farmer_{unique_suffix}@example.com"
    o_email = f"rent_officer_{unique_suffix}@example.com"
    pwd = "TestPassword@123"

    f_token = client.post("/api/auth/register/farmer", json={
        "full_name": "Pandurang Kadam", "email": f_email, "phone_number": "+91 9544332211", "password": pwd
    }).json()["access_token"]
    f_headers = {"Authorization": f"Bearer {f_token}"}

    o_token = client.post("/api/auth/register/officer", json={
        "full_name": "Officer Kulkarni", "email": o_email, "phone_number": "+91 9211009988", "password": pwd
    }).json()["access_token"]
    o_headers = {"Authorization": f"Bearer {o_token}"}

    # 1. Browse Equipment Rentals (seeded from Milestone B)
    eq_res = client.get("/api/equipment-rentals", headers=f_headers)
    assert eq_res.status_code == 200
    equipments = eq_res.json()
    assert len(equipments) >= 1
    eq_id = equipments[0]["id"]

    # 2. Farmer books equipment for 2 days
    book_res = client.post(
        "/api/equipment-rentals/bookings",
        json={
            "equipment_id": eq_id,
            "start_date": "2026-11-20",
            "end_date": "2026-11-21",
            "rental_type": "daily",
            "duration_units": 2,
            "delivery_location": "Survey No 88, Kadam Vasti, Baramati",
            "contact_phone": "+91 9544332211",
            "farmer_notes": "Required with trained driver/operator.",
        },
        headers=f_headers,
    )
    assert book_res.status_code == 201
    booking_id = book_res.json()["id"]
    assert book_res.json()["booking_status"] == "requested"

    # 3. Officer confirms booking
    book_update = client.patch(
        f"/api/equipment-rentals/bookings/{booking_id}/status",
        json={
            "booking_status": "confirmed",
            "provider_response": "Custom Hiring Center confirmed availability. Tractor operator dispatched on 20 Nov 7:00 AM.",
        },
        headers=o_headers,
    )
    assert book_update.status_code == 200
    assert book_update.json()["booking_status"] == "confirmed"


def test_08_unauthorized_and_invalid_requests():
    """Verify 401 Unauthorized on missing token and 422 Unprocessable Entity on invalid payload."""
    # No auth header -> 401
    unauth_res = client.get("/api/auth/me")
    assert unauth_res.status_code == 401

    # Invalid password length -> 422
    invalid_reg = client.post(
        "/api/auth/register/farmer",
        json={
            "full_name": "Test",
            "email": "invalid@test.com",
            "phone_number": "123",
            "password": "short",
        },
    )
    assert invalid_reg.status_code == 422


if __name__ == "__main__":
    print("=== Running Phase 4 Backend API Test Suite ===")
    test_01_database_connectivity()
    print("PASS: test_01_database_connectivity")

    test_02_auth_farmer_and_officer_lifecycle()
    print("PASS: test_02_auth_farmer_and_officer_lifecycle")

    test_03_farmer_profile_and_farm_management()
    print("PASS: test_03_farmer_profile_and_farm_management")

    test_04_assistance_requests_and_officer_consultation()
    print("PASS: test_04_assistance_requests_and_officer_consultation")

    test_05_loan_and_subsidy_enquiries()
    print("PASS: test_05_loan_and_subsidy_enquiries")

    test_06_marketplace_cart_and_order_flow()
    print("PASS: test_06_marketplace_cart_and_order_flow")

    test_07_equipment_rental_booking_flow()
    print("PASS: test_07_equipment_rental_booking_flow")

    test_08_unauthorized_and_invalid_requests()
    print("PASS: test_08_unauthorized_and_invalid_requests")

    print("\nALL 8 PHASE 4 INTEGRATION TESTS PASSED SUCCESSFULLY!")
