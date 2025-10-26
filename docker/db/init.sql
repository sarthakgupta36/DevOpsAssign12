-- PostgreSQL initialization script for Django login app
-- This script creates the necessary database and user if they don't exist

-- Create database if it doesn't exist
SELECT 'CREATE DATABASE postgres'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'postgres');

-- Connect to the database
\c postgres;

-- Create the login table if it doesn't exist
CREATE TABLE IF NOT EXISTS login (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_login_username ON login(username);

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE postgres TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;

-- Insert a sample user for testing (optional)
-- INSERT INTO login (username, password) VALUES ('ITA700', '2022PE0000') 
-- ON CONFLICT (username) DO NOTHING;