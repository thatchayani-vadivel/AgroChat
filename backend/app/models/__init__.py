"""SQLAlchemy ORM models package covering all 25 database tables."""

from app.models.agricultural_service import AgriculturalService
from app.models.assistance_request import AssistanceRequest
from app.models.consultation import Consultation
from app.models.crop import Crop
from app.models.equipment_rental import EquipmentRental
from app.models.farm import Farm
from app.models.farmer_profile import FarmerProfile
from app.models.livestock import Livestock
from app.models.loan_enquiry import LoanDocument, LoanEnquiry
from app.models.marketplace import (
    CartItem,
    Order,
    OrderItem,
    Product,
    ProductCategory,
    ShoppingCart,
)
from app.models.message import Message
from app.models.notification import Notification
from app.models.officer_profile import OfficerProfile
from app.models.rental_booking import RentalBooking
from app.models.request_attachment import RequestAttachment
from app.models.scheme import Scheme
from app.models.subsidy_enquiry import SubsidyDocument, SubsidyEnquiry
from app.models.user import User

__all__ = [
    "User",
    "FarmerProfile",
    "OfficerProfile",
    "Farm",
    "Crop",
    "Livestock",
    "AssistanceRequest",
    "RequestAttachment",
    "Consultation",
    "Message",
    "Notification",
    "Scheme",
    "EquipmentRental",
    "RentalBooking",
    "AgriculturalService",
    "LoanEnquiry",
    "LoanDocument",
    "SubsidyEnquiry",
    "SubsidyDocument",
    "ProductCategory",
    "Product",
    "ShoppingCart",
    "CartItem",
    "Order",
    "OrderItem",
]
