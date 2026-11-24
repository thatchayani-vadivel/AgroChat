"""Idempotent seed data for schemes, loans, insurance, equipment rentals, and nearby services."""

from decimal import Decimal
import logging

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.constants import EquipmentAvailability, SchemeCategory
from app.models.agricultural_service import AgriculturalService
from app.models.equipment_rental import EquipmentRental
from app.models.marketplace import Product, ProductCategory
from app.models.scheme import Scheme

logger = logging.getLogger("agrochat.db.seed")


def _seed_schemes(db: Session) -> None:
    count = db.scalar(select(func.count(Scheme.id))) or 0
    if count > 0:
        return

    items = [
        Scheme(
            title="Pradhan Mantri Kisan Samman Nidhi (PM-KISAN)",
            category=SchemeCategory.SCHEME,
            provider="Ministry of Agriculture & Farmers Welfare",
            description="Income support scheme providing direct financial assistance to landholding farmer families across India.",
            benefits="Rs. 6,000 per year transferred directly in three equal installments of Rs. 2,000 every four months.",
            eligibility="All landholding farmer families with cultivable landholding subject to institutional exclusion criteria.",
            required_documents="Aadhaar Card, Land Ownership Records (7/12 or Khatauni), Bank Passbook.",
            application_process="Register online via pmkisan.gov.in or through nearest Common Service Centre (CSC) / Village Patwari.",
            official_link="https://pmkisan.gov.in/",
            state="All India",
        ),
        Scheme(
            title="Soil Health Card Scheme",
            category=SchemeCategory.SCHEME,
            provider="Department of Agriculture & Cooperation",
            description="Provides crop-wise recommendations of nutrients and fertilizers required for individual farms to improve soil fertility.",
            benefits="Free soil sample testing every 2 years and customized fertilizer dosage guidance.",
            eligibility="All farmers owning or cultivating agricultural land.",
            required_documents="Aadhaar Card, Farm Survey Number, Mobile Number.",
            application_process="Submit soil sample through your local Agriculture Extension Officer or Krishi Vigyan Kendra.",
            official_link="https://soilhealth.dac.gov.in/",
            state="All India",
        ),
        Scheme(
            title="Per Drop More Crop (Micro Irrigation Subsidy)",
            category=SchemeCategory.SUBSIDY,
            provider="Pradhan Mantri Krishi Sinchayee Yojana (PMKSY)",
            description="Financial subsidy to promote drip and sprinkler irrigation systems for water conservation and higher crop productivity.",
            benefits="Up to 55% subsidy for small & marginal farmers and up to 45% for other farmers on drip/sprinkler equipment.",
            eligibility="Farmers with cultivable agricultural land and a valid irrigation water source.",
            required_documents="Aadhaar Card, 7/12 Land Extract, Bank Account Details, Quotation from approved micro-irrigation vendor.",
            application_process="Apply via your State Agriculture Portal or District Horticulture/Agriculture Office.",
            official_link="https://pmksy.gov.in/",
            state="All India",
        ),
        Scheme(
            title="Solar Pump Subsidy (PM-KUSUM Component B)",
            category=SchemeCategory.SUBSIDY,
            provider="Ministry of New and Renewable Energy",
            description="Supports installation of standalone off-grid solar agriculture water pumps for irrigation.",
            benefits="60% combined central and state subsidy on standalone solar pumps (up to 7.5 HP) plus up to 30% bank loan support.",
            eligibility="Individual farmers, Water User Associations, and Farmer Producer Organizations (FPOs).",
            required_documents="Aadhaar Card, Land Record, Bank Details, Passport Photo.",
            application_process="Apply through your State Nodal Agency (SNA) online portal.",
            official_link="https://pmkusum.mnre.gov.in/",
            state="All India",
        ),
        Scheme(
            title="Kisan Credit Card (KCC) Crop Loan",
            category=SchemeCategory.LOAN,
            provider="NABARD / Commercial & Cooperative Banks",
            description="Timely and affordable short-term credit for crop cultivation, post-harvest expenses, and allied livestock activities.",
            benefits="Revolving credit up to Rs. 3 lakh at subsidized 4% effective annual interest rate on prompt repayment.",
            eligibility="Owner-cultivators, tenant farmers, sharecroppers, and dairy/poultry/fishery farmers.",
            required_documents="KYC (Aadhaar/PAN), Land Cultivation Proof or Lease Agreement, Passport Photos.",
            application_process="Submit KCC application form at any nearby Public Sector, Regional Rural, or Cooperative Bank.",
            official_link="https://www.nabard.org/",
            state="All India",
        ),
        Scheme(
            title="Agriculture Infrastructure Fund (AIF) Term Loan",
            category=SchemeCategory.LOAN,
            provider="Department of Agriculture & Farmers Welfare",
            description="Medium-to-long-term debt financing for post-harvest management infrastructure, cold storage, and farm processing units.",
            benefits="3% interest subvention on loans up to Rs. 2 crore for up to 7 years plus credit guarantee coverage.",
            eligibility="Farmers, FPOs, Agri-entrepreneurs, Primary Agricultural Credit Societies (PACS).",
            required_documents="Project Report, KYC, Land/Site Lease Documents, Bank Statements.",
            application_process="Apply online on agriinfra.dac.gov.in and select your preferred lending bank.",
            official_link="https://agriinfra.dac.gov.in/",
            state="All India",
        ),
        Scheme(
            title="Pradhan Mantri Fasal Bima Yojana (PMFBY)",
            category=SchemeCategory.INSURANCE,
            provider="Ministry of Agriculture & Empanelled Insurers",
            description="Comprehensive crop insurance protecting farmers against non-preventable natural risks from pre-sowing to post-harvest.",
            benefits="Low farmer premium: max 2% for Kharif crops, 1.5% for Rabi crops, and 5% for commercial/horticultural crops.",
            eligibility="All farmers growing notified crops in notified areas (loanee and non-loanee farmers).",
            required_documents="Aadhaar Card, Land Record / Tenancy Certificate, Sowing Certificate, Bank Passbook.",
            application_process="Enroll via pmfby.gov.in, bank branch, CSC center, or insurance intermediary before cutoff date.",
            official_link="https://pmfby.gov.in/",
            state="All India",
        ),
        Scheme(
            title="Livestock Insurance Scheme",
            category=SchemeCategory.INSURANCE,
            provider="Department of Animal Husbandry & Dairying",
            description="Provides protection to dairy and livestock farmers against accidental or disease-related loss of cattle and animals.",
            benefits="Subsidized insurance premium (50% to 70% subsidy for eligible farmers) covering full market value of insured animals.",
            eligibility="Farmers owning milch cattle, buffaloes, sheep, goats, or draft animals.",
            required_documents="Owner Aadhaar, Veterinary Health Certificate, Ear Tagging ID of animal, Bank Passbook.",
            application_process="Contact your nearest Government Veterinary Hospital or District Animal Husbandry Office.",
            official_link="https://dahd.gov.in/",
            state="All India",
        ),
    ]
    db.add_all(items)


def _seed_equipment(db: Session) -> None:
    count = db.scalar(select(func.count(EquipmentRental.id))) or 0
    if count > 0:
        return

    items = [
        EquipmentRental(
            equipment_name="John Deere 5050D 50HP Tractor",
            category="Tractor",
            description="Heavy-duty 50HP tractor suitable for ploughing, tilling, and trailer haulage.",
            provider_name="Baramati Krishi Custom Hiring Center",
            contact_phone="+91 9822011223",
            location="MIDC Agro Hub, Baramati",
            district="Pune",
            state="Maharashtra",
            daily_rate_inr=2200.0,
            hourly_rate_inr=450.0,
            availability_status=EquipmentAvailability.AVAILABLE,
        ),
        EquipmentRental(
            equipment_name="6-Feet Heavy Rotavator Attachment",
            category="Tillage",
            description="42-blade rotavator for rapid seedbed preparation in black cotton and loamy soils.",
            provider_name="Sahyadri Agro Machinery Bank",
            contact_phone="+91 9765022334",
            location="Taluka Krishi Kendra, Indapur",
            district="Pune",
            state="Maharashtra",
            daily_rate_inr=1200.0,
            hourly_rate_inr=250.0,
            availability_status=EquipmentAvailability.AVAILABLE,
        ),
        EquipmentRental(
            equipment_name="Agri-Spray 16L Agricultural Drone",
            category="Sprayer",
            description="Precision crop-spraying drone with 16-liter tank and trained operator for uniform pesticide/foliar spray.",
            provider_name="Kisan Tech Solutions",
            contact_phone="+91 9890033445",
            location="Agri Innovation Park, Nashik Road",
            district="Nashik",
            state="Maharashtra",
            daily_rate_inr=3500.0,
            hourly_rate_inr=700.0,
            availability_status=EquipmentAvailability.AVAILABLE,
        ),
        EquipmentRental(
            equipment_name="Multi-Crop Combine Harvester",
            category="Harvester",
            description="High-efficiency harvester suitable for wheat, paddy, soybean, and pulses.",
            provider_name="Narmada Custom Hiring Center",
            contact_phone="+91 9425044556",
            location="Mandi Yard Sector 2, Sehore",
            district="Sehore",
            state="Madhya Pradesh",
            daily_rate_inr=6500.0,
            hourly_rate_inr=1400.0,
            availability_status=EquipmentAvailability.AVAILABLE,
        ),
        EquipmentRental(
            equipment_name="Tractor-Mounted Seed Cum Fertilizer Drill",
            category="Seeder",
            description="9-row precision seed drill for simultaneous sowing and basal fertilizer placement.",
            provider_name="GreenField Farmers Cooperative",
            contact_phone="+91 9845055667",
            location="APMC Yard, Mandya",
            district="Mandya",
            state="Karnataka",
            daily_rate_inr=1100.0,
            hourly_rate_inr=220.0,
            availability_status=EquipmentAvailability.AVAILABLE,
        ),
    ]
    db.add_all(items)


def _seed_services(db: Session) -> None:
    count = db.scalar(select(func.count(AgriculturalService.id))) or 0
    if count > 0:
        return

    items = [
        AgriculturalService(
            name="Krishi Vigyan Kendra (KVK), Baramati",
            service_type="Krishi Vigyan Kendra",
            description="Agricultural extension, farmer training, crop demonstrations, and pest advisory center.",
            address="Shardanagar, Malegaon Khurd, Baramati",
            district="Pune",
            state="Maharashtra",
            pincode="413115",
            contact_phone="+91 2112255207",
            email="kvkbaramati@example.org",
            working_hours="Mon-Sat, 9:30 AM - 5:30 PM",
            latitude=18.1492,
            longitude=74.5136,
        ),
        AgriculturalService(
            name="District Soil & Water Testing Laboratory, Pune",
            service_type="Soil Testing Lab",
            description="NPK, pH, electrical conductivity, micronutrient soil testing and irrigation water quality analysis.",
            address="Shivajinagar Agriculture Campus, Pune",
            district="Pune",
            state="Maharashtra",
            pincode="411005",
            contact_phone="+91 2025537120",
            email="soiltestpune@example.org",
            working_hours="Mon-Fri, 10:00 AM - 5:30 PM",
            latitude=18.5308,
            longitude=73.8475,
        ),
        AgriculturalService(
            name="Taluka Agriculture Office & Seed Distribution Center",
            service_type="District Agriculture Office",
            description="Subsidized certified seeds, scheme verification, PMFBY helpdesk, and extension officer support.",
            address="Station Road, Near Tehsil Office, Nashik",
            district="Nashik",
            state="Maharashtra",
            pincode="422001",
            contact_phone="+91 2532578410",
            email="daonashik@example.org",
            working_hours="Mon-Sat, 9:45 AM - 5:30 PM",
            latitude=19.9975,
            longitude=73.7898,
        ),
        AgriculturalService(
            name="Government Veterinary Polyclinic & Dairy Aid Center",
            service_type="Veterinary Clinic",
            description="Livestock vaccination, artificial insemination, mastitis care, and animal health certification.",
            address="Hospital Road, Mandya",
            district="Mandya",
            state="Karnataka",
            pincode="571401",
            contact_phone="+91 8232224108",
            email="vetmandya@example.org",
            working_hours="Mon-Sat, 9:00 AM - 4:30 PM",
            latitude=12.5218,
            longitude=76.8951,
        ),
        AgriculturalService(
            name="Kisan Cold Storage & Agro Warehousing Hub",
            service_type="Cold Storage",
            description="Temperature-controlled storage chambers for fruits, vegetables, onions, and seed potatoes.",
            address="NH-46 Agro Logistics Park, Sehore",
            district="Sehore",
            state="Madhya Pradesh",
            pincode="466001",
            contact_phone="+91 7562226700",
            email="coldhubsehore@example.org",
            working_hours="Daily, 7:00 AM - 8:00 PM",
            latitude=23.2032,
            longitude=77.0844,
        ),
    ]
    db.add_all(items)


def _seed_products(db: Session) -> None:
    count = db.scalar(select(func.count(Product.id))) or 0
    if count > 1:
        return

    items = [
        Product(
            category_id=2,
            product_name="IFFCO Neem Coated Urea (45 kg)",
            brand_or_manufacturer="IFFCO",
            description="Govt subsidized 46% nitrogen slow-release neem-coated urea for balanced vegetative crop growth.",
            price_inr=Decimal("266.50"),
            unit="45 kg bag",
            stock_quantity=100,
            is_available=True,
        ),
        Product(
            category_id=2,
            product_name="DAP (Di-Ammonium Phosphate 18:46:0)",
            brand_or_manufacturer="KRIBHCO",
            description="High-phosphorus fertilizer essential for rapid root development and flowering in cereals and pulses.",
            price_inr=Decimal("1350.00"),
            unit="50 kg bag",
            stock_quantity=80,
            is_available=True,
        ),
        Product(
            category_id=3,
            product_name="Pure Organic Vermicompost Fertilizer",
            brand_or_manufacturer="Kisan Agro Organics",
            description="Earthworm compost enriched with beneficial microbes, humic acid, and micronutrients for soil health.",
            price_inr=Decimal("350.00"),
            unit="25 kg bag",
            stock_quantity=60,
            is_available=True,
        ),
        Product(
            category_id=4,
            product_name="Neem Baan 10,000 PPM Botanical Bio-Pesticide",
            brand_or_manufacturer="PestGuard Agri",
            description="Cold-pressed azadirachtin formulation effective against sucking pests, bollworms, and whiteflies.",
            price_inr=Decimal("480.00"),
            unit="1 Liter bottle",
            stock_quantity=45,
            is_available=True,
        ),
        Product(
            category_id=6,
            product_name="Heavy-Duty Forged Steel Garden Spade & Shovel",
            brand_or_manufacturer="Tata Agrico",
            description="Tempered carbon-steel spade with wooden grip for canal maintenance, weeding, and soil turning.",
            price_inr=Decimal("420.00"),
            unit="Piece",
            stock_quantity=30,
            is_available=True,
        ),
        Product(
            category_id=7,
            product_name="Drip Irrigation Inline Lateral Kit (0.5 Acre)",
            brand_or_manufacturer="Jain Irrigation",
            description="16mm ISI-marked drip lateral pipe with 40cm emitter spacing, screen filter, and joiners.",
            price_inr=Decimal("4200.00"),
            unit="Kit",
            stock_quantity=20,
            is_available=True,
        ),
        Product(
            category_id=8,
            product_name="16L 12V Battery-Operated Knapsack Sprayer",
            brand_or_manufacturer="Aspee",
            description="Rechargeable electric backpack sprayer with pressure regulator, brass lance, and multiple nozzle heads.",
            price_inr=Decimal("2250.00"),
            unit="Piece",
            stock_quantity=25,
            is_available=True,
        ),
        Product(
            category_id=9,
            product_name="High-Yield Dairy Cattle Feed Mash (20% Protein)",
            brand_or_manufacturer="Godrej Agrovet",
            description="Balanced compound cattle feed with bypass protein, calcium, and minerals for sustained milk yield.",
            price_inr=Decimal("1480.00"),
            unit="50 kg bag",
            stock_quantity=50,
            is_available=True,
        ),
    ]
    db.add_all(items)


def seed_reference_data(db: Session) -> None:
    """Populate initial schemes, equipment rentals, services, and products if tables are empty."""
    _seed_schemes(db)
    _seed_equipment(db)
    _seed_services(db)
    _seed_products(db)
    db.commit()
    logger.info("Reference data check/seeding completed.")

