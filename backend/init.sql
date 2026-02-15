-- Initial database setup
-- This runs automatically when the PostgreSQL container starts

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create indexes for full-text search performance
-- (These will also be created by Alembic migrations, but
--  having them here ensures they exist on fresh deploys)
