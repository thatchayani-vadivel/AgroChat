-- Milestone B Migration: Assistance Requests, Consultations, Chat/Voice Messages,
-- Notifications, Schemes (Subsidies/Loans/Insurance), Equipment Rentals, and Nearby Services.
-- Safe, idempotent migration script for agrochat_db.

CREATE TABLE IF NOT EXISTS assistance_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    farmer_id INT NOT NULL,
    officer_id INT NULL,
    farm_id INT NULL,
    crop_id INT NULL,
    title VARCHAR(200) NOT NULL,
    category VARCHAR(120) NOT NULL,
    description TEXT NOT NULL,
    priority ENUM('low', 'medium', 'high', 'urgent') NOT NULL DEFAULT 'medium',
    status ENUM('pending', 'accepted', 'in_progress', 'resolved', 'rejected', 'cancelled') NOT NULL DEFAULT 'pending',
    officer_notes TEXT NULL,
    rejection_reason TEXT NULL,
    accepted_at DATETIME NULL,
    resolved_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_requests_farmer_id (farmer_id),
    INDEX idx_requests_officer_id (officer_id),
    INDEX idx_requests_farm_id (farm_id),
    INDEX idx_requests_category (category),
    INDEX idx_requests_status (status),
    CONSTRAINT fk_requests_farmer
        FOREIGN KEY (farmer_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_requests_officer
        FOREIGN KEY (officer_id) REFERENCES users (id) ON DELETE SET NULL,
    CONSTRAINT fk_requests_farm
        FOREIGN KEY (farm_id) REFERENCES farms (id) ON DELETE SET NULL,
    CONSTRAINT fk_requests_crop
        FOREIGN KEY (crop_id) REFERENCES crops (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS consultations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL UNIQUE,
    farmer_id INT NOT NULL,
    officer_id INT NOT NULL,
    status ENUM('active', 'completed') NOT NULL DEFAULT 'active',
    guidance_summary TEXT NULL,
    recommendations TEXT NULL,
    started_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_consultations_request_id (request_id),
    INDEX idx_consultations_farmer_id (farmer_id),
    INDEX idx_consultations_officer_id (officer_id),
    INDEX idx_consultations_status (status),
    CONSTRAINT fk_consultations_request
        FOREIGN KEY (request_id) REFERENCES assistance_requests (id) ON DELETE CASCADE,
    CONSTRAINT fk_consultations_farmer
        FOREIGN KEY (farmer_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_consultations_officer
        FOREIGN KEY (officer_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    message_type ENUM('text', 'voice') NOT NULL DEFAULT 'text',
    content TEXT NULL,
    audio_file_name VARCHAR(255) NULL,
    audio_url VARCHAR(500) NULL,
    duration_seconds INT NULL,
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_messages_request_id (request_id),
    INDEX idx_messages_sender_id (sender_id),
    INDEX idx_messages_receiver_id (receiver_id),
    INDEX idx_messages_created_at (created_at),
    CONSTRAINT fk_messages_request
        FOREIGN KEY (request_id) REFERENCES assistance_requests (id) ON DELETE CASCADE,
    CONSTRAINT fk_messages_sender
        FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_messages_receiver
        FOREIGN KEY (receiver_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    notification_type ENUM('request_created', 'request_accepted', 'request_rejected', 'request_updated', 'new_message') NOT NULL,
    related_request_id INT NULL,
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_notifications_user_id (user_id),
    INDEX idx_notifications_is_read (is_read),
    INDEX idx_notifications_created_at (created_at),
    CONSTRAINT fk_notifications_user
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_notifications_request
        FOREIGN KEY (related_request_id) REFERENCES assistance_requests (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS schemes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(220) NOT NULL,
    category ENUM('scheme', 'subsidy', 'loan', 'insurance') NOT NULL,
    provider VARCHAR(180) NOT NULL,
    description TEXT NOT NULL,
    benefits TEXT NOT NULL,
    eligibility TEXT NOT NULL,
    required_documents TEXT NULL,
    application_process TEXT NULL,
    official_link VARCHAR(300) NULL,
    state VARCHAR(120) NOT NULL DEFAULT 'All India',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_schemes_category (category),
    INDEX idx_schemes_state (state)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS equipment_rentals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    equipment_name VARCHAR(180) NOT NULL,
    category VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    provider_name VARCHAR(150) NOT NULL,
    contact_phone VARCHAR(20) NOT NULL,
    location VARCHAR(220) NOT NULL,
    district VARCHAR(120) NOT NULL,
    state VARCHAR(120) NOT NULL,
    daily_rate_inr FLOAT NOT NULL,
    hourly_rate_inr FLOAT NULL,
    availability_status ENUM('available', 'booked', 'maintenance') NOT NULL DEFAULT 'available',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_equipment_category (category),
    INDEX idx_equipment_district (district),
    INDEX idx_equipment_state (state),
    INDEX idx_equipment_availability (availability_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS agricultural_services (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    service_type VARCHAR(120) NOT NULL,
    description TEXT NOT NULL,
    address VARCHAR(255) NOT NULL,
    district VARCHAR(120) NOT NULL,
    state VARCHAR(120) NOT NULL,
    pincode VARCHAR(12) NULL,
    contact_phone VARCHAR(20) NOT NULL,
    email VARCHAR(255) NULL,
    working_hours VARCHAR(120) NULL,
    latitude FLOAT NULL,
    longitude FLOAT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_services_type (service_type),
    INDEX idx_services_district (district),
    INDEX idx_services_state (state)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

