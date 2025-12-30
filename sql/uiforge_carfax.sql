CREATE TABLE IF NOT EXISTS carfax_vehicles (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  plate VARCHAR(12) NOT NULL,
  vin VARCHAR(32) NOT NULL,
  report_id VARCHAR(32) NOT NULL,
  registration_status VARCHAR(32) NOT NULL,
  created_at INT NOT NULL,
  updated_at INT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_carfax_plate (plate),
  UNIQUE KEY uk_carfax_vin (vin),
  UNIQUE KEY uk_carfax_report (report_id),
  KEY idx_carfax_reg (registration_status),
  KEY idx_carfax_updated (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS carfax_service_records (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  vehicle_id INT UNSIGNED NOT NULL,
  service_type VARCHAR(32) NOT NULL,
  custom_label VARCHAR(64) DEFAULT NULL,
  notes TEXT NOT NULL,
  job_label VARCHAR(64) DEFAULT NULL,
  author_identifier VARCHAR(64) DEFAULT NULL,
  created_at INT NOT NULL,
  mileage INT DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_service_vehicle (vehicle_id),
  KEY idx_service_created (created_at),
  CONSTRAINT fk_service_vehicle FOREIGN KEY (vehicle_id) REFERENCES carfax_vehicles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS carfax_incident_records (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  vehicle_id INT UNSIGNED NOT NULL,
  incident_type VARCHAR(32) NOT NULL,
  custom_label VARCHAR(64) DEFAULT NULL,
  notes TEXT NOT NULL,
  job_label VARCHAR(64) DEFAULT NULL,
  author_identifier VARCHAR(64) DEFAULT NULL,
  created_at INT NOT NULL,
  is_private TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_incident_vehicle (vehicle_id),
  KEY idx_incident_created (created_at),
  KEY idx_incident_private (is_private),
  CONSTRAINT fk_incident_vehicle FOREIGN KEY (vehicle_id) REFERENCES carfax_vehicles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS carfax_ownerships (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  vehicle_id INT UNSIGNED NOT NULL,
  owner_index INT NOT NULL,
  owner_identifier VARCHAR(64) DEFAULT NULL,
  author_identifier VARCHAR(64) DEFAULT NULL,
  registration_status VARCHAR(32) NOT NULL,
  notes TEXT DEFAULT NULL,
  created_at INT NOT NULL,
  PRIMARY KEY (id),
  KEY idx_owner_vehicle (vehicle_id),
  KEY idx_owner_index (owner_index),
  KEY idx_owner_created (created_at),
  CONSTRAINT fk_owner_vehicle FOREIGN KEY (vehicle_id) REFERENCES carfax_vehicles(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
