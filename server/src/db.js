const { Pool } = require('pg');

let pool = null;

function getPool() {
  if (!pool) {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      throw new Error('DATABASE_URL is not set');
    }
    pool = new Pool({
      connectionString,
      ssl: process.env.PGSSL === 'false' ? false : { rejectUnauthorized: false },
    });
  }
  return pool;
}

async function initDb() {
  const client = await getPool().connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        phone VARCHAR(15) UNIQUE NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        last_login_at TIMESTAMPTZ,
        is_pro BOOLEAN NOT NULL DEFAULT FALSE,
        expire_pro TIMESTAMPTZ
      );

      CREATE TABLE IF NOT EXISTS otp_codes (
        id SERIAL PRIMARY KEY,
        phone VARCHAR(15) NOT NULL,
        code VARCHAR(6) NOT NULL,
        expires_at TIMESTAMPTZ NOT NULL,
        attempts INT NOT NULL DEFAULT 0,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );

      CREATE INDEX IF NOT EXISTS idx_otp_phone ON otp_codes (phone, created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_users_created ON users (created_at DESC);
    `);
  } finally {
    client.release();
  }
}

async function query(text, params) {
  return getPool().query(text, params);
}

module.exports = { initDb, query, getPool };
