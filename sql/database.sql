-- Tạo database
CREATE DATABASE IF NOT EXISTS quan_ly_dien_nang CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE quan_ly_dien_nang;

-- Bảng phòng
CREATE TABLE rooms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    room_code VARCHAR(20) NOT NULL UNIQUE,          -- Ví dụ: P101, KT-A201
    room_name VARCHAR(100) NOT NULL,
    building VARCHAR(50),
    room_type ENUM('phong_hoc', 'ky_tuc_xa', 'phong_may') DEFAULT 'phong_hoc',
    baseline_power FLOAT DEFAULT 800,               -- Công suất nền (W)
    max_power FLOAT DEFAULT 3000,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bảng dữ liệu công suất thô (quan trọng nhất)
CREATE TABLE power_readings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    room_id INT NOT NULL,
    recorded_at DATETIME NOT NULL,
    power_w FLOAT NOT NULL,                         -- Công suất tức thời (W)
    energy_kwh FLOAT NOT NULL,                       -- Điện năng tích lũy (kWh)
    is_missing TINYINT(1) DEFAULT 0,                -- Đánh dấu dữ liệu bị thiếu
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
    INDEX idx_room_time (room_id, recorded_at)
);

-- Bảng cảnh báo bất thường
CREATE TABLE anomalies (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    room_id INT NOT NULL,
    reading_id BIGINT,
    detected_at DATETIME NOT NULL,
    anomaly_type ENUM('zscore', 'moving_avg', 'night_high', 'sudden_spike', 'missing_data') NOT NULL,
    power_value FLOAT,
    z_score FLOAT,
    description VARCHAR(255),
    is_resolved TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
    INDEX idx_detected (detected_at)
);

-- Bảng cấu hình ngưỡng (để dễ thay đổi)
CREATE TABLE settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(50) NOT NULL UNIQUE,
    setting_value VARCHAR(100) NOT NULL,
    description VARCHAR(255)
);

-- Thêm dữ liệu mẫu phòng
INSERT INTO rooms (room_code, room_name, building, room_type, baseline_power, max_power) VALUES
('P101', 'Phòng học 101', 'A', 'phong_hoc', 950, 2500),
('P102', 'Phòng học 102', 'A', 'phong_hoc', 880, 2400),
('P201', 'Phòng máy 201', 'B', 'phong_may', 1800, 4500),
('KT-A101', 'Ký túc xá A101', 'KT-A', 'ky_tuc_xa', 450, 1800),
('KT-A102', 'Ký túc xá A102', 'KT-A', 'ky_tuc_xa', 420, 1700),
('KT-B205', 'Ký túc xá B205', 'KT-B', 'ky_tuc_xa', 480, 1900);

-- Thêm cấu hình mặc định
INSERT INTO settings (setting_key, setting_value, description) VALUES
('zscore_threshold', '2.5', 'Ngưỡng Z-score để cảnh báo'),
('moving_avg_window', '12', 'Số điểm dùng tính trung bình trượt (12 điểm = 1 giờ nếu lấy mẫu 5 phút)'),
('moving_avg_threshold', '0.35', 'Ngưỡng sai lệch so với trung bình trượt (35%)'),
('night_start', '22:00', 'Giờ bắt đầu ban đêm'),
('night_end', '06:00', 'Giờ kết thúc ban đêm'),
('night_max_power', '300', 'Công suất tối đa cho phép ban đêm (W)');