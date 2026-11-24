-- ==============================================================================
-- AgroChat Database Migration: 003_marketplace_enquiries_attachments.sql
-- Description: Adds tables for Request Attachments, Loan & Subsidy Enquiries,
--              Marketplace Categories, Products, Carts, Orders, and Equipment Bookings.
-- Roles Supported: Farmer and Agricultural Officer (Strictly TWO roles).
-- Safety: Uses CREATE TABLE IF NOT EXISTS. Preserves all existing tables and data.
-- ==============================================================================

USE `agrochat_db`;

-- ------------------------------------------------------------------------------
-- 1. Table: request_attachments
-- Stores crop disease photos, test reports, and documents attached to assistance requests.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `request_attachments` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `request_id` INT NOT NULL,
    `uploader_id` INT NOT NULL,
    `file_name` VARCHAR(255) NOT NULL,
    `file_path` VARCHAR(500) NOT NULL,
    `file_type` VARCHAR(100) NOT NULL,
    `file_size_bytes` INT NOT NULL,
    `description` VARCHAR(255) NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    INDEX `idx_req_att_request` (`request_id`),
    INDEX `idx_req_att_uploader` (`uploader_id`),
    CONSTRAINT `fk_req_att_request` FOREIGN KEY (`request_id`)
        REFERENCES `assistance_requests` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_req_att_uploader` FOREIGN KEY (`uploader_id`)
        REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 2. Table: loan_enquiries
-- Advisory and assistance enquiry submitted by a Farmer for agricultural credit / loans.
-- (AgroChat facilitates advisory and application guidance, not a direct bank approval).
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `loan_enquiries` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `farmer_id` INT NOT NULL,
    `scheme_id` INT NULL,
    `loan_type` VARCHAR(100) NOT NULL,
    `preferred_bank` VARCHAR(150) NULL,
    `requested_amount_inr` DECIMAL(12, 2) NOT NULL,
    `purpose` TEXT NOT NULL,
    `annual_income_inr` DECIMAL(12, 2) NULL,
    `land_holding_acres` DECIMAL(8, 2) NULL,
    `status` VARCHAR(50) DEFAULT 'submitted' NOT NULL,
    `officer_guidance` TEXT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    INDEX `idx_loan_enq_farmer` (`farmer_id`),
    INDEX `idx_loan_enq_scheme` (`scheme_id`),
    INDEX `idx_loan_enq_status` (`status`),
    CONSTRAINT `fk_loan_enq_farmer` FOREIGN KEY (`farmer_id`)
        REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_loan_enq_scheme` FOREIGN KEY (`scheme_id`)
        REFERENCES `schemes` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 3. Table: loan_documents
-- Supporting documents for a loan enquiry (Land extract 7/12, Aadhaar, Bank passbook).
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `loan_documents` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `enquiry_id` INT NOT NULL,
    `document_name` VARCHAR(150) NOT NULL,
    `document_type` VARCHAR(100) NOT NULL,
    `file_path` VARCHAR(500) NOT NULL,
    `file_size_bytes` INT NOT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    INDEX `idx_loan_doc_enquiry` (`enquiry_id`),
    CONSTRAINT `fk_loan_doc_enquiry` FOREIGN KEY (`enquiry_id`)
        REFERENCES `loan_enquiries` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 4. Table: subsidy_enquiries
-- Enquiries for government agricultural subsidies (Micro-irrigation, solar pump, seed aid).
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `subsidy_enquiries` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `farmer_id` INT NOT NULL,
    `scheme_id` INT NULL,
    `subsidy_title` VARCHAR(200) NOT NULL,
    `farm_id` INT NULL,
    `enquiry_details` TEXT NOT NULL,
    `status` VARCHAR(50) DEFAULT 'submitted' NOT NULL,
    `officer_guidance` TEXT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    INDEX `idx_sub_enq_farmer` (`farmer_id`),
    INDEX `idx_sub_enq_scheme` (`scheme_id`),
    INDEX `idx_sub_enq_status` (`status`),
    CONSTRAINT `fk_sub_enq_farmer` FOREIGN KEY (`farmer_id`)
        REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_sub_enq_scheme` FOREIGN KEY (`scheme_id`)
        REFERENCES `schemes` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_sub_enq_farm` FOREIGN KEY (`farm_id`)
        REFERENCES `farms` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 5. Table: subsidy_documents
-- Supporting documents for subsidy applications (Land certificate, Quotation, ID).
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `subsidy_documents` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `enquiry_id` INT NOT NULL,
    `document_name` VARCHAR(150) NOT NULL,
    `document_type` VARCHAR(100) NOT NULL,
    `file_path` VARCHAR(500) NOT NULL,
    `file_size_bytes` INT NOT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    INDEX `idx_sub_doc_enquiry` (`enquiry_id`),
    CONSTRAINT `fk_sub_doc_enquiry` FOREIGN KEY (`enquiry_id`)
        REFERENCES `subsidy_enquiries` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 6. Table: product_categories
-- Marketplace product classification.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `product_categories` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL UNIQUE,
    `description` VARCHAR(255) NULL,
    `icon_name` VARCHAR(50) NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed verified standard categories if table is empty
INSERT IGNORE INTO `product_categories` (`id`, `name`, `description`, `icon_name`) VALUES
(1, 'Seeds', 'Certified hybrid and traditional crop seeds', 'grass'),
(2, 'Fertilizers', 'Chemical and bio-fertilizers for crop nutrition', 'science'),
(3, 'Organic Manure', 'Compost, vermicompost, and neem cake', 'eco'),
(4, 'Pesticides & Bio-Pesticides', 'Targeted pest and disease protection', 'bug_report'),
(5, 'Herbicides & Weedicides', 'Weed control formulations for farm plots', 'spa'),
(6, 'Agricultural Tools', 'Hand tools, pruning shears, spades, sickles', 'handyman'),
(7, 'Irrigation Equipment', 'Drip laterals, drippers, sprinklers, filters', 'water_drop'),
(8, 'Farming Machinery', 'Mini-tillers, power weeders, knapsack sprayers', 'precision_manufacturing'),
(9, 'Animal Feed & Supplements', 'Cattle feed, mineral mixtures, poultry mesh', 'pets');

-- ------------------------------------------------------------------------------
-- 7. Table: products
-- Agricultural supplies in the farmer marketplace.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `products` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `category_id` INT NOT NULL,
    `product_name` VARCHAR(200) NOT NULL,
    `brand_or_manufacturer` VARCHAR(150) NULL,
    `description` TEXT NOT NULL,
    `price_inr` DECIMAL(10, 2) NOT NULL,
    `unit` VARCHAR(50) NOT NULL,
    `stock_quantity` INT DEFAULT 0 NOT NULL,
    `is_available` BOOLEAN DEFAULT TRUE NOT NULL,
    `image_url` VARCHAR(500) NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    INDEX `idx_products_cat` (`category_id`),
    INDEX `idx_products_avail` (`is_available`),
    INDEX `idx_products_name` (`product_name`),
    CONSTRAINT `fk_products_cat` FOREIGN KEY (`category_id`)
        REFERENCES `product_categories` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 8. Table: shopping_carts
-- Exactly one shopping cart per farmer.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `shopping_carts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `farmer_id` INT NOT NULL UNIQUE,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    INDEX `idx_cart_farmer` (`farmer_id`),
    CONSTRAINT `fk_cart_farmer` FOREIGN KEY (`farmer_id`)
        REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 9. Table: cart_items
-- Items stored inside the farmer's shopping cart.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `cart_items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `cart_id` INT NOT NULL,
    `product_id` INT NOT NULL,
    `quantity` INT DEFAULT 1 NOT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    UNIQUE KEY `uk_cart_product` (`cart_id`, `product_id`),
    INDEX `idx_cart_items_cart` (`cart_id`),
    INDEX `idx_cart_items_prod` (`product_id`),
    CONSTRAINT `fk_cart_items_cart` FOREIGN KEY (`cart_id`)
        REFERENCES `shopping_carts` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_cart_items_prod` FOREIGN KEY (`product_id`)
        REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 10. Table: orders
-- Orders placed by Farmers for marketplace supplies.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `orders` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `order_number` VARCHAR(50) NOT NULL UNIQUE,
    `farmer_id` INT NOT NULL,
    `total_amount_inr` DECIMAL(12, 2) NOT NULL,
    `delivery_address` TEXT NOT NULL,
    `contact_phone` VARCHAR(20) NOT NULL,
    `order_status` VARCHAR(50) DEFAULT 'confirmed' NOT NULL,
    `payment_method` VARCHAR(50) DEFAULT 'cash_on_delivery' NOT NULL,
    `payment_status` VARCHAR(50) DEFAULT 'pending' NOT NULL,
    `notes` TEXT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    INDEX `idx_orders_farmer` (`farmer_id`),
    INDEX `idx_orders_num` (`order_number`),
    INDEX `idx_orders_status` (`order_status`),
    CONSTRAINT `fk_orders_farmer` FOREIGN KEY (`farmer_id`)
        REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 11. Table: order_items
-- Order line items preserving price and snapshot product name.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `order_items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `order_id` INT NOT NULL,
    `product_id` INT NOT NULL,
    `product_name` VARCHAR(200) NOT NULL,
    `unit_price_inr` DECIMAL(10, 2) NOT NULL,
    `quantity` INT NOT NULL,
    `total_price_inr` DECIMAL(12, 2) NOT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    INDEX `idx_ord_items_order` (`order_id`),
    INDEX `idx_ord_items_prod` (`product_id`),
    CONSTRAINT `fk_ord_items_order` FOREIGN KEY (`order_id`)
        REFERENCES `orders` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ord_items_prod` FOREIGN KEY (`product_id`)
        REFERENCES `products` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 12. Table: rental_bookings
-- Booking requests placed by Farmers for rental equipment (Tractors, Drones, Harvesters).
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `rental_bookings` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `equipment_id` INT NOT NULL,
    `farmer_id` INT NOT NULL,
    `start_date` DATE NOT NULL,
    `end_date` DATE NOT NULL,
    `rental_type` VARCHAR(20) NOT NULL,
    `duration_units` INT NOT NULL,
    `total_cost_inr` DECIMAL(10, 2) NOT NULL,
    `delivery_location` VARCHAR(255) NOT NULL,
    `contact_phone` VARCHAR(20) NOT NULL,
    `booking_status` VARCHAR(50) DEFAULT 'requested' NOT NULL,
    `farmer_notes` TEXT NULL,
    `provider_response` TEXT NULL,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    INDEX `idx_rent_book_eq` (`equipment_id`),
    INDEX `idx_rent_book_farmer` (`farmer_id`),
    INDEX `idx_rent_book_status` (`booking_status`),
    CONSTRAINT `fk_rent_book_eq` FOREIGN KEY (`equipment_id`)
        REFERENCES `equipment_rentals` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_rent_book_farmer` FOREIGN KEY (`farmer_id`)
        REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
