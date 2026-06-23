const express = require('express');
const jwt = require('jsonwebtoken');
const { query } = require('./db');
const { sendOtpSms, normalizePhone } = require('./sms');

const router = express.Router();

const OTP_TTL_SECONDS = Number(process.env.OTP_TTL_SECONDS || 120);
const OTP_RESEND_SECONDS = Number(process.env.OTP_RESEND_SECONDS || 60);
const MAX_OTP_ATTEMPTS = Number(process.env.MAX_OTP_ATTEMPTS || 5);
const JWT_SECRET = process.env.JWT_SECRET || 'change-me-in-production';
const JWT_EXPIRES = process.env.JWT_EXPIRES || '30d';

function isValidIranianPhone(phone) {
  return /^09\d{9}$/.test(phone);
}

function generateOtpCode() {
  return String(Math.floor(1000 + Math.random() * 9000));
}

function signToken(user) {
  return jwt.sign(
    { sub: user.id, phone: user.phone },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES },
  );
}

function userPayload(row) {
  return {
    id: row.id,
    phone: row.phone,
    isPro: row.is_pro,
    expirePro: row.expire_pro ? row.expire_pro.toISOString() : null,
    createdAt: row.created_at.toISOString(),
    lastLoginAt: row.last_login_at ? row.last_login_at.toISOString() : null,
  };
}

router.post('/send-otp', async (req, res) => {
  try {
    const phone = normalizePhone(req.body?.phone || '');
    if (!isValidIranianPhone(phone)) {
      return res.status(400).json({ ok: false, error: 'invalid_phone' });
    }

    const recent = await query(
      `SELECT created_at FROM otp_codes
       WHERE phone = $1 AND created_at > NOW() - ($2 || ' seconds')::interval
       ORDER BY created_at DESC LIMIT 1`,
      [phone, String(OTP_RESEND_SECONDS)],
    );
    if (recent.rows.length > 0) {
      return res.status(429).json({ ok: false, error: 'rate_limited' });
    }

    const code = generateOtpCode();
    await query(
      `INSERT INTO otp_codes (phone, code, expires_at) VALUES ($1, $2, NOW() + ($3 || ' seconds')::interval)`,
      [phone, code, String(OTP_TTL_SECONDS)],
    );

    const smsMeta = await sendOtpSms(phone, code);
    const payload = { ok: true, expiresIn: OTP_TTL_SECONDS };
    if (process.env.DEV_OTP_RESPONSE === 'true' && smsMeta.dev) {
      payload.devCode = code;
    }
    res.json(payload);
  } catch (err) {
    console.error('send-otp error:', err);
    res.status(500).json({ ok: false, error: 'sms_failed' });
  }
});

router.post('/verify-otp', async (req, res) => {
  try {
    const phone = normalizePhone(req.body?.phone || '');
    const code = String(req.body?.code || '').trim();

    if (!isValidIranianPhone(phone) || !/^\d{4}$/.test(code)) {
      return res.status(400).json({ ok: false, error: 'invalid_request' });
    }

    const otpResult = await query(
      `SELECT id, code, expires_at, attempts FROM otp_codes
       WHERE phone = $1 ORDER BY created_at DESC LIMIT 1`,
      [phone],
    );

    if (otpResult.rows.length === 0) {
      return res.status(400).json({ ok: false, error: 'otp_not_found' });
    }

    const otp = otpResult.rows[0];
    if (otp.attempts >= MAX_OTP_ATTEMPTS) {
      return res.status(400).json({ ok: false, error: 'too_many_attempts' });
    }
    if (new Date(otp.expires_at) < new Date()) {
      return res.status(400).json({ ok: false, error: 'otp_expired' });
    }

    await query(`UPDATE otp_codes SET attempts = attempts + 1 WHERE id = $1`, [
      otp.id,
    ]);

    if (otp.code !== code) {
      return res.status(400).json({ ok: false, error: 'invalid_code' });
    }

    await query(`DELETE FROM otp_codes WHERE phone = $1`, [phone]);

    let userResult = await query(`SELECT * FROM users WHERE phone = $1`, [phone]);
    let user;
    if (userResult.rows.length === 0) {
      userResult = await query(
        `INSERT INTO users (phone, last_login_at) VALUES ($1, NOW()) RETURNING *`,
        [phone],
      );
      user = userResult.rows[0];
    } else {
      userResult = await query(
        `UPDATE users SET last_login_at = NOW() WHERE phone = $1 RETURNING *`,
        [phone],
      );
      user = userResult.rows[0];
    }

    const token = signToken(user);
    res.json({
      ok: true,
      token,
      user: userPayload(user),
    });
  } catch (err) {
    console.error('verify-otp error:', err);
    res.status(500).json({ ok: false, error: 'server_error' });
  }
});

router.get('/me', async (req, res) => {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) return res.status(401).json({ ok: false, error: 'unauthorized' });

    const payload = jwt.verify(token, JWT_SECRET);
    const result = await query(`SELECT * FROM users WHERE id = $1`, [payload.sub]);
    if (result.rows.length === 0) {
      return res.status(401).json({ ok: false, error: 'unauthorized' });
    }
    res.json({ ok: true, user: userPayload(result.rows[0]) });
  } catch {
    res.status(401).json({ ok: false, error: 'unauthorized' });
  }
});

module.exports = router;
