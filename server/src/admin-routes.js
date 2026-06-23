const express = require('express');
const jwt = require('jsonwebtoken');
const { query } = require('./db');

const router = express.Router();

const ADMIN_USER = process.env.ADMIN_USERNAME || 'admin';
const ADMIN_PASS = process.env.ADMIN_PASSWORD || '';
const ADMIN_JWT_SECRET = process.env.ADMIN_JWT_SECRET || process.env.JWT_SECRET || 'admin-secret';

function adminAuth(req, res, next) {
  const token = req.cookies?.boma_admin;
  if (!token) return res.status(401).json({ ok: false, error: 'unauthorized' });
  try {
    req.admin = jwt.verify(token, ADMIN_JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ ok: false, error: 'unauthorized' });
  }
}

router.post('/login', async (req, res) => {
  const { username, password } = req.body || {};
  if (!ADMIN_PASS) {
    return res.status(503).json({ ok: false, error: 'admin_not_configured' });
  }
  if (username !== ADMIN_USER || password !== ADMIN_PASS) {
    return res.status(401).json({ ok: false, error: 'invalid_credentials' });
  }
  const token = jwt.sign({ role: 'admin', username }, ADMIN_JWT_SECRET, {
    expiresIn: '7d',
  });
  res.cookie('boma_admin', token, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    maxAge: 7 * 24 * 60 * 60 * 1000,
  });
  res.json({ ok: true });
});

router.post('/logout', (_req, res) => {
  res.clearCookie('boma_admin');
  res.json({ ok: true });
});

router.get('/stats', adminAuth, async (_req, res) => {
  const total = await query(`SELECT COUNT(*)::int AS count FROM users`);
  const today = await query(
    `SELECT COUNT(*)::int AS count FROM users WHERE created_at >= CURRENT_DATE`,
  );
  const logins = await query(
    `SELECT COUNT(*)::int AS count FROM users WHERE last_login_at >= CURRENT_DATE`,
  );
  res.json({
    ok: true,
    stats: {
      totalUsers: total.rows[0].count,
      signupsToday: today.rows[0].count,
      loginsToday: logins.rows[0].count,
    },
  });
});

router.get('/users', adminAuth, async (req, res) => {
  const page = Math.max(1, Number(req.query.page || 1));
  const limit = Math.min(100, Math.max(10, Number(req.query.limit || 25)));
  const offset = (page - 1) * limit;
  const search = String(req.query.search || '').trim();

  let rows;
  let count;
  if (search) {
    const pattern = `%${search.replace(/[%_]/g, '')}%`;
    rows = await query(
      `SELECT id, phone, created_at, last_login_at, is_pro, expire_pro
       FROM users WHERE phone LIKE $1
       ORDER BY created_at DESC LIMIT $2 OFFSET $3`,
      [pattern, limit, offset],
    );
    count = await query(`SELECT COUNT(*)::int AS count FROM users WHERE phone LIKE $1`, [
      pattern,
    ]);
  } else {
    rows = await query(
      `SELECT id, phone, created_at, last_login_at, is_pro, expire_pro
       FROM users ORDER BY created_at DESC LIMIT $1 OFFSET $2`,
      [limit, offset],
    );
    count = await query(`SELECT COUNT(*)::int AS count FROM users`);
  }

  res.json({
    ok: true,
    page,
    limit,
    total: count.rows[0].count,
    users: rows.rows.map((u) => ({
      id: u.id,
      phone: u.phone,
      createdAt: u.created_at.toISOString(),
      lastLoginAt: u.last_login_at ? u.last_login_at.toISOString() : null,
      isPro: u.is_pro,
      expirePro: u.expire_pro ? u.expire_pro.toISOString() : null,
    })),
  });
});

module.exports = { router, adminAuth };
