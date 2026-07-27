CREATE TYPE user_type AS ENUM (
    'student',
    'property_owner',
    'realtor',
    'republic_representative'
);

CREATE TYPE user_role AS ENUM ('admin', 'user');

CREATE TYPE place_status AS ENUM (
    'draft',
    'pending',
    'active',
    'inactive',
    'rented',
    'rejected',
    'deleted'
);

CREATE TABLE
    users (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        username VARCHAR(50) NOT NULL UNIQUE,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(255) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        user_type user_type NOT NULL DEFAULT 'student',
        user_role user_role NOT NULL DEFAULT 'user',
        profile_picture VARCHAR(500),
        institution VARCHAR(150),
        description TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
        deleted_at TIMESTAMPTZ
    );

CREATE TABLE 
    places (
        id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        owner_id BIGINT NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
        title VARCHAR(200) NOT NULL,
        description TEXT NOT NULL,
        distance_from_university NUMERIC(6, 3),
        furnished BOOLEAN NOT NULL DEFAULT FALSE,
        place_size_m2 NUMERIC(7, 2) NOT NULL,
        bedrooms SMALLINT NOT NULL,
        monthly_price NUMERIC(10, 2) NOT NULL,
        address VARCHAR(250) NOT NULL,
        district VARCHAR(100) NOT NULL,
        city VARCHAR(100) NOT NULL,
        state CHAR(2) NOT NULL,
        longitude NUMERIC(9, 6) NOT NULL,
        latitude NUMERIC(9, 6) NOT NULL,
        status place_status NOT NULL DEFAULT 'pending',
        created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
        deleted_at TIMESTAMPTZ,
        CONSTRAINT places_size_positive CHECK (place_size_m2 > 0),
        CONSTRAINT places_bedrooms_non_negative CHECK (bedrooms >= 0),
        CONSTRAINT places_price_non_negative CHECK (monthly_price >= 0),
        CONSTRAINT places_distance_non_negative CHECK (
            distance_from_university IS NULL
            OR distance_from_university >= 0
        ),
        CONSTRAINT places_valid_latitude CHECK (latitude BETWEEN -90 AND 90),
        CONSTRAINT places_valid_longitude CHECK (longitude BETWEEN -180 AND 180)
    );

CREATE TABLE institutions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(200) NOT NULL UNIQUE,
    address VARCHAR(250) NOT NULL,
    district VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state CHAR(2) NOT NULL,
    longitude NUMERIC(9, 6) NOT NULL,
    latitude NUMERIC(9, 6) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT institutions_valid_latitude CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT institutions_valid_longitude CHECK (longitude BETWEEN -180 AND 180)
);

CREATE TABLE chats() (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    interested_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    place_id BIGINT NOT NULL REFERENCES places (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_chat_pair UNIQUE (interested_id, place_id)
);