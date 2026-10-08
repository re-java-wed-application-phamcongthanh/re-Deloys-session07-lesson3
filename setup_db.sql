-- ==============================================================================
-- Script SQL: setup_db.sql
-- Mo ta: Khoi tao database va user MySQL cho ung dung Spring Boot
# Khoa hoc: DevOps Fundamentals - Session 07 - Bai 3
-- ==============================================================================

-- 1. Tao Database springboot_db
CREATE DATABASE IF NOT EXISTS springboot_db 
  CHARACTER SET utf8mb4 
  COLLATE utf8mb4_unicode_ci;

-- 2. Tao User spring-admin va dat mat khau bao mat
CREATE USER IF NOT EXISTS 'spring-admin'@'localhost' IDENTIFIED BY 'SpringSecure@123';

-- 3. Cap toan quyen (ALL PRIVILEGES) tren database springboot_db cho user spring-admin
GRANT ALL PRIVILEGES ON springboot_db.* TO 'spring-admin'@'localhost';

-- 4. Lam moi bang quyen han
FLUSH PRIVILEGES;

-- 5. Kiem tra danh sach user va quyen han
SHOW GRANTS FOR 'spring-admin'@'localhost';
