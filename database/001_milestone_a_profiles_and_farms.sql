-- Milestone A Migration: Core Profiles and Farm Management Tables
-- Safe, idempotent migration script for agrochat_db (preserves existing users and data)

CREATE TABLE IF NOT EXISTS farmer_profiles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    village VARCHAR(120) NULL,
    taluk_or_block VARCHAR(120) NULL,
    district VARCHAR(120) NOT NULL,
    state VARCHAR(120) NOT NULL,
    pincode VARCHAR(12) NULL,
    farming_experience_years INT NULL,
    education_level VARCHAR(100) NULL,
    primary_occupation VARCHAR(120) NOT NULL DEFAULT 'Farming',
    bio TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_farmer_profiles_user_id (user_id),
    INDEX idx_farmer_profiles_district (district),
    INDEX idx_farmer_profiles_state (state),
    CONSTRAINT fk_farmer_profiles_user
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS officer_profiles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    designation VARCHAR(150) NOT NULL,
    department VARCHAR(150) NULL,
    specialization VARCHAR(200) NOT NULL,
    qualifications VARCHAR(255) NULL,
    experience_years INT NOT NULL DEFAULT 0,
    languages_spoken VARCHAR(255) NOT NULL DEFAULT 'English',
    office_location VARCHAR(200) NULL,
    district VARCHAR(120) NOT NULL,
    state VARCHAR(120) NOT NULL,
    is_available TINYINT(1) NOT NULL DEFAULT 1,
    availability_hours VARCHAR(120) NULL,
    bio TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_officer_profiles_user_id (user_id),
    INDEX idx_officer_profiles_specialization (specialization),
    INDEX idx_officer_profiles_district (district),
    INDEX idx_officer_profiles_state (state),
    INDEX idx_officer_profiles_is_available (is_available),
    CONSTRAINT fk_officer_profiles_user
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS farms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    farmer_profile_id INT NOT NULL,
    farm_name VARCHAR(150) NOT NULL,
    total_area_acres FLOAT NOT NULL,
    soil_type VARCHAR(100) NOT NULL,
    irrigation_type VARCHAR(100) NOT NULL,
    water_source VARCHAR(120) NULL,
    location VARCHAR(255) NOT NULL,
    district VARCHAR(120) NOT NULL,
    state VARCHAR(120) NOT NULL,
    ownership_type VARCHAR(80) NULL,
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_farms_farmer_profile_id (farmer_profile_id),
    INDEX idx_farms_district (district),
    CONSTRAINT fk_farms_farmer_profile
        FOREIGN KEY (farmer_profile_id) REFERENCES farmer_profiles (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS crops (
    id INT AUTO_INCREMENT PRIMARY KEY,
    farm_id INT NOT NULL,
    crop_name VARCHAR(120) NOT NULL,
    variety VARCHAR(120) NULL,
    season VARCHAR(80) NOT NULL,
    area_acres FLOAT NOT NULL,
    sowing_date DATE NULL,
    expected_harvest_date DATE NULL,
    growth_stage VARCHAR(100) NULL,
    estimated_yield_kg FLOAT NULL,
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_crops_farm_id (farm_id),
    INDEX idx_crops_crop_name (crop_name),
    CONSTRAINT fk_crops_farm
        FOREIGN KEY (farm_id) REFERENCES farms (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS livestock (
    id INT AUTO_INCREMENT PRIMARY KEY,
    farm_id INT NOT NULL,
    category VARCHAR(100) NOT NULL,
    breed_or_type VARCHAR(120) NULL,
    count INT NOT NULL DEFAULT 1,
    purpose VARCHAR(150) NULL,
    health_status VARCHAR(100) NOT NULL DEFAULT 'Healthy',
    notes TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_livestock_farm_id (farm_id),
    INDEX idx_livestock_category (category),
    CONSTRAINT fk_livestock_farm
        FOREIGN KEY (farm_id) REFERENCES farms (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

