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

CREATE TYPE place_type AS ENUM (
    'apartment',
    'room',
    'shared_room',
    'republic'
);

CREATE TYPE report_target_type AS ENUM ('place', 'user');

CREATE TYPE report_status AS ENUM ('pending', 'reviewed', 'dismissed');

CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    pass_hash VARCHAR(255) NOT NULL,
    user_type user_type NOT NULL DEFAULT 'student',
    profile_picture VARCHAR(300),
    institution VARCHAR(150),
    description TEXT,
    user_role user_role NOT NULL DEFAULT 'user',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT users_name_not_blank CHECK (btrim(name) <> ''),
    CONSTRAINT users_username_not_blank CHECK (btrim(username) <> ''),
    CONSTRAINT users_email_not_blank CHECK (btrim(email) <> '')
);

CREATE TABLE institutions (
    id_institution BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(200) NOT NULL UNIQUE,
    city VARCHAR(100) NOT NULL,
    address VARCHAR(250) NOT NULL,
    district VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT institutions_name_not_blank CHECK (btrim(name) <> '')
);

CREATE TABLE places (
    place_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    institution_id BIGINT NOT NULL REFERENCES institutions (id_institution) ON DELETE RESTRICT,
    owner_id BIGINT NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    title VARCHAR(200) NOT NULL,
    place_brief TEXT NOT NULL,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    distance_to_uni NUMERIC(6, 3),
    furnished BOOLEAN NOT NULL DEFAULT FALSE,
    place_type place_type NOT NULL,
    place_size NUMERIC(7, 2) NOT NULL,
    monthly_price NUMERIC(10, 2) NOT NULL,
    place_address VARCHAR(500) NOT NULL,
    rooms SMALLINT NOT NULL,
    city VARCHAR(100) NOT NULL,
    district VARCHAR(100) NOT NULL,
    longitude NUMERIC(9, 6) NOT NULL,
    latitude NUMERIC(9, 6) NOT NULL,
    status place_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT places_title_not_blank CHECK (btrim(title) <> ''),
    CONSTRAINT places_size_positive CHECK (place_size > 0),
    CONSTRAINT places_rooms_non_negative CHECK (rooms >= 0),
    CONSTRAINT places_price_non_negative CHECK (monthly_price >= 0),
    CONSTRAINT places_distance_non_negative CHECK (
        distance_to_uni IS NULL
        OR distance_to_uni >= 0
    ),
    CONSTRAINT places_valid_latitude CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT places_valid_longitude CHECK (longitude BETWEEN -180 AND 180)
);

CREATE TABLE ad_images (
    image_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    place_id BIGINT NOT NULL REFERENCES places (place_id) ON DELETE CASCADE,
    image_url VARCHAR(1000) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ad_images_url_not_blank CHECK (btrim(image_url) <> '')
);

CREATE TABLE user_ratings (
    rating_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rater_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    rated_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    rate NUMERIC(3, 2) NOT NULL,
    commentary TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_ratings_rate_range CHECK (rate BETWEEN 0 AND 5),
    CONSTRAINT user_ratings_not_self CHECK (rater_id <> rated_id),
    CONSTRAINT unique_user_rating_per_pair UNIQUE (rater_id, rated_id)
);

CREATE TABLE place_ratings (
    rating_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    place_id BIGINT NOT NULL REFERENCES places (place_id) ON DELETE CASCADE,
    rater_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    rate NUMERIC(2, 1) NOT NULL,
    commentary TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT place_ratings_rate_range CHECK (rate BETWEEN 0 AND 5),
    CONSTRAINT unique_place_rating_per_pair UNIQUE (place_id, rater_id)
);

CREATE TABLE favorites (
    fav_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    place_id BIGINT NOT NULL REFERENCES places (place_id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_favorite_per_user_place UNIQUE (user_id, place_id)
);

CREATE TABLE reports (
    report_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reporter_user_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    reported_place_id BIGINT REFERENCES places (place_id) ON DELETE CASCADE,
    reported_user_id BIGINT REFERENCES users (id) ON DELETE CASCADE,
    report_content TEXT NOT NULL,
    report_type report_target_type NOT NULL,
    report_status report_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reports_target_required CHECK (
        (report_type = 'place' AND reported_place_id IS NOT NULL AND reported_user_id IS NULL)
        OR
        (report_type = 'user' AND reported_user_id IS NOT NULL AND reported_place_id IS NULL)
    ),
    CONSTRAINT reports_not_self CHECK (reporter_user_id <> COALESCE(reported_user_id, -1))
);

CREATE TABLE chats (
    chat_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    place_id BIGINT NOT NULL REFERENCES places (place_id) ON DELETE CASCADE,
    interested_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_chat_pair UNIQUE (place_id, interested_id)
);

CREATE TABLE messages (
    message_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    chat_id BIGINT NOT NULL REFERENCES chats (chat_id) ON DELETE CASCADE,
    sender_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    image_url VARCHAR(1000),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT messages_content_required CHECK (
        btrim(message) <> ''
        OR image_url IS NOT NULL
    )
);

CREATE INDEX idx_places_status ON places (status);
CREATE INDEX idx_places_city ON places (city);
CREATE INDEX idx_places_district ON places (district);
CREATE INDEX idx_places_institution_id ON places (institution_id);
CREATE INDEX idx_places_owner_id ON places (owner_id);
CREATE INDEX idx_user_ratings_rated_id ON user_ratings (rated_id);
CREATE INDEX idx_place_ratings_place_id ON place_ratings (place_id);
CREATE INDEX idx_reports_report_status ON reports (report_status);
CREATE INDEX idx_messages_chat_id ON messages (chat_id);

CREATE OR REPLACE FUNCTION prevent_self_chat()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM places p
        WHERE p.id = NEW.place_id
          AND p.owner_id = NEW.interested_id
    ) THEN
        RAISE EXCEPTION 'A user cannot start a chat with themselves';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_self_chat
BEFORE INSERT OR UPDATE ON chats
FOR EACH ROW
EXECUTE FUNCTION prevent_self_chat();