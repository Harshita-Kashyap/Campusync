CREATE DATABASE IF NOT EXISTS campusync
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE campusync;

CREATE TABLE IF NOT EXISTS water_incidents (
  id CHAR(36) NOT NULL PRIMARY KEY,
  location_name VARCHAR(255) NOT NULL,
  issue_type ENUM('leaking_tap', 'overflow', 'pipe_leak', 'other') NOT NULL,
  estimated_litres_per_hour DECIMAL(12, 2) NOT NULL,
  reported_at DATETIME(6) NOT NULL,
  estimated_duration_hours DECIMAL(10, 2) NOT NULL DEFAULT 0,
  severity ENUM('low', 'medium', 'high', 'critical') NOT NULL,
  description TEXT NOT NULL,
  status ENUM('open', 'in_progress', 'resolved', 'dismissed') NOT NULL DEFAULT 'open',
  analysis_source ENUM('ai', 'fallback', 'manual') NOT NULL DEFAULT 'manual',
  image_filename VARCHAR(255) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  INDEX idx_water_incidents_reported_at (reported_at),
  INDEX idx_water_incidents_status (status)
) ENGINE=InnoDB
  DEFAULT CHARACTER SET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;
