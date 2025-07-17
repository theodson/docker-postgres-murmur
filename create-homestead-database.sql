CREATE EXTENSION hashlib;
CREATE EXTENSION pg_trgm;
CREATE ROLE homestead LOGIN PASSWORD 'secret' SUPERUSER INHERIT;
ALTER USER postgres PASSWORD 'secret';
-- SELECT 'CREATE DATABASE homestead' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'homestead' )
CREATE DATABASE homestead_test;
