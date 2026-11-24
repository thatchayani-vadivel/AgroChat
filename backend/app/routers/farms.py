"""REST endpoints for Farms, Crops, and Livestock management."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_farmer, get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.farm import (
    CropPayload,
    CropResponse,
    FarmPayload,
    FarmResponse,
    LivestockPayload,
    LivestockResponse,
    MessageResponse,
)
from app.services.farm_service import (
    add_crop,
    add_livestock,
    create_farm,
    delete_crop,
    delete_farm,
    delete_livestock,
    get_farm_details,
    list_crops,
    list_farmer_farms,
    list_livestock,
    update_crop,
    update_farm,
    update_livestock,
)

router = APIRouter(prefix="/api/farms", tags=["Farms, Crops & Livestock"])


@router.post(
    "",
    response_model=FarmResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create Farm",
    description="Add a new farm under the authenticated Farmer's profile.",
)
def create_my_farm(
    payload: FarmPayload,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> FarmResponse:
    return create_farm(db, current_farmer, payload)


@router.get(
    "",
    response_model=list[FarmResponse],
    status_code=status.HTTP_200_OK,
    summary="List My Farms",
    description="List all farms, crops, and livestock owned by the authenticated Farmer.",
)
def read_my_farms(
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> list[FarmResponse]:
    return list_farmer_farms(db, current_farmer)


@router.get(
    "/{farm_id}",
    response_model=FarmResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Farm Details",
    description="Get details of a farm (accessible to the owning Farmer or an Agricultural Officer).",
)
def read_farm_details(
    farm_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FarmResponse:
    return get_farm_details(db, farm_id, current_user)


@router.put(
    "/{farm_id}",
    response_model=FarmResponse,
    status_code=status.HTTP_200_OK,
    summary="Update Farm",
    description="Update details of a farm owned by the authenticated Farmer.",
)
def update_my_farm(
    farm_id: int,
    payload: FarmPayload,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> FarmResponse:
    return update_farm(db, farm_id, current_farmer, payload)


@router.delete(
    "/{farm_id}",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Delete Farm",
    description="Delete a farm and its associated crops and livestock.",
)
def delete_my_farm(
    farm_id: int,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> MessageResponse:
    delete_farm(db, farm_id, current_farmer)
    return MessageResponse(message="Farm deleted successfully.")


@router.post(
    "/{farm_id}/crops",
    response_model=CropResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Add Crop to Farm",
    description="Add a cultivated crop entry to the Farmer's farm.",
)
def create_farm_crop(
    farm_id: int,
    payload: CropPayload,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> CropResponse:
    return add_crop(db, farm_id, current_farmer, payload)


@router.get(
    "/{farm_id}/crops",
    response_model=list[CropResponse],
    status_code=status.HTTP_200_OK,
    summary="List Farm Crops",
    description="List crops on a farm (accessible to the owning Farmer or an Agricultural Officer).",
)
def read_farm_crops(
    farm_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[CropResponse]:
    return list_crops(db, farm_id, current_user)


@router.put(
    "/{farm_id}/crops/{crop_id}",
    response_model=CropResponse,
    status_code=status.HTTP_200_OK,
    summary="Update Farm Crop",
    description="Update a crop entry on the Farmer's owned farm.",
)
def update_farm_crop(
    farm_id: int,
    crop_id: int,
    payload: CropPayload,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> CropResponse:
    return update_crop(db, farm_id, crop_id, current_farmer, payload)


@router.delete(
    "/{farm_id}/crops/{crop_id}",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Delete Farm Crop",
    description="Remove a crop entry from the Farmer's owned farm.",
)
def delete_farm_crop(
    farm_id: int,
    crop_id: int,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> MessageResponse:
    delete_crop(db, farm_id, crop_id, current_farmer)
    return MessageResponse(message="Crop deleted successfully.")


@router.post(
    "/{farm_id}/livestock",
    response_model=LivestockResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Add Livestock or Allied Activity",
    description="Add livestock or an allied agricultural activity to the Farmer's farm.",
)
def create_farm_livestock(
    farm_id: int,
    payload: LivestockPayload,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> LivestockResponse:
    return add_livestock(db, farm_id, current_farmer, payload)


@router.get(
    "/{farm_id}/livestock",
    response_model=list[LivestockResponse],
    status_code=status.HTTP_200_OK,
    summary="List Farm Livestock",
    description="List livestock and allied activities on a farm (owning Farmer or Officer).",
)
def read_farm_livestock(
    farm_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[LivestockResponse]:
    return list_livestock(db, farm_id, current_user)


@router.put(
    "/{farm_id}/livestock/{livestock_id}",
    response_model=LivestockResponse,
    status_code=status.HTTP_200_OK,
    summary="Update Farm Livestock",
    description="Update livestock or allied activity details on the Farmer's owned farm.",
)
def update_farm_livestock(
    farm_id: int,
    livestock_id: int,
    payload: LivestockPayload,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> LivestockResponse:
    return update_livestock(db, farm_id, livestock_id, current_farmer, payload)


@router.delete(
    "/{farm_id}/livestock/{livestock_id}",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Delete Farm Livestock",
    description="Remove a livestock or allied activity entry from the Farmer's owned farm.",
)
def delete_farm_livestock(
    farm_id: int,
    livestock_id: int,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> MessageResponse:
    delete_livestock(db, farm_id, livestock_id, current_farmer)
    return MessageResponse(message="Livestock entry deleted successfully.")

