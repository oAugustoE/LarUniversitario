CREATE DATABASE IF NOT EXISTS laruniversitariodev;

CREATE TYPE user_type AS ENUM ('student', 'owner', 'rental', 'republic');
CREATE TYPE user_role AS ENUM ('admin', 'user');

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    user_type user_type NOT NULL DEFAULT 'student',
    profile_picture VARCHAR(255),
    institution VARCHAR(100),
    description varchar(2000),
    user_role user_role NOT NULL DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);