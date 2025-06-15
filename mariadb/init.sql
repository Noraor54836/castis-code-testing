-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS apiapp;

-- Use the database
USE apiapp;

-- Create records table
CREATE TABLE IF NOT EXISTS records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO records (name, value) VALUES 
    ('Sample Record 1', 'This is the first sample record'),
    ('Sample Record 2', 'This is the second sample record'),
    ('Configuration Data', '{"key": "value", "enabled": true}'),
    ('User Preferences', '{"theme": "dark", "language": "en"}');

-- Create users table for demonstration
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample users
INSERT INTO users (username, email) VALUES 
    ('admin', 'admin@example.com'),
    ('user1', 'user1@example.com'),
    ('user2', 'user2@example.com');

-- Create api_keys table for authentication
CREATE TABLE IF NOT EXISTS api_keys (
    id INT AUTO_INCREMENT PRIMARY KEY,
    key_name VARCHAR(100) NOT NULL,
    api_key VARCHAR(255) UNIQUE NOT NULL,
    user_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Insert sample API keys
INSERT INTO api_keys (key_name, api_key, user_id) VALUES 
    ('Admin Key', 'sample-admin-key', 1),
    ('User1 Key', 'sample-user1-key', 2),
    ('User2 Key', 'sample-user2-key', 3);