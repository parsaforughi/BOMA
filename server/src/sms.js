const https = require('https');

function env(name, fallback = '') {
  return process.env[name] || fallback;
}

function normalizePhone(phone) {
  let p = String(phone).replace(/\D/g, '');
  if (p.startsWith('98') && p.length === 12) p = '0' + p.slice(2);
  if (p.startsWith('9') && p.length === 10) p = '0' + p;
  return p;
}

function httpGet(url) {
  return new Promise((resolve, reject) => {
    https
      .get(url, (res) => {
        let body = '';
        res.on('data', (chunk) => {
          body += chunk;
        });
        res.on('end', () => {
          try {
            resolve({ status: res.statusCode, body: JSON.parse(body) });
          } catch {
            resolve({ status: res.statusCode, body });
          }
        });
      })
      .on('error', reject);
  });
}

function httpPost(url, headers, payload) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(payload);
    const req = https.request(
      url,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(data),
          ...headers,
        },
      },
      (res) => {
        let body = '';
        res.on('data', (chunk) => {
          body += chunk;
        });
        res.on('end', () => {
          try {
            resolve({ status: res.statusCode, body: JSON.parse(body) });
          } catch {
            resolve({ status: res.statusCode, body });
          }
        });
      },
    );
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

async function sendViaKavenegar(phone, code) {
  const apiKey = env('KAVENEGAR_API_KEY');
  const template = env('KAVENEGAR_TEMPLATE', 'boma');
  if (!apiKey) throw new Error('KAVENEGAR_API_KEY is not set');

  const url =
    `https://api.kavenegar.com/v1/${encodeURIComponent(apiKey)}/verify/lookup.json` +
    `?receptor=${encodeURIComponent(phone)}` +
    `&token=${encodeURIComponent(code)}` +
    `&template=${encodeURIComponent(template)}`;

  const result = await httpGet(url);
  const ok = result.body?.return?.status === 200;
  if (!ok) {
    throw new Error(
      `Kavenegar error: ${JSON.stringify(result.body?.return || result.body)}`,
    );
  }
}

async function sendViaSmsIr(phone, code) {
  const apiKey = env('SMSIR_API_KEY');
  const templateId = env('SMSIR_TEMPLATE_ID');
  if (!apiKey || !templateId) {
    throw new Error('SMSIR_API_KEY and SMSIR_TEMPLATE_ID are required');
  }

  const result = await httpPost(
    'https://api.sms.ir/v1/send/verify',
    { 'X-API-KEY': apiKey },
    {
      mobile: phone,
      templateId: Number(templateId),
      parameters: [{ name: 'CODE', value: code }],
    },
  );

  if (result.status !== 200 || result.body?.status !== 1) {
    throw new Error(`SMS.ir error: ${JSON.stringify(result.body)}`);
  }
}

async function sendOtpSms(phone, code) {
  const normalized = normalizePhone(phone);
  const provider = env('SMS_PROVIDER', 'console').toLowerCase();

  if (provider === 'console') {
    console.log(`[BOMA OTP] ${normalized} => ${code}`);
    return { dev: true };
  }
  if (provider === 'kavenegar') {
    await sendViaKavenegar(normalized, code);
    return {};
  }
  if (provider === 'smsir') {
    await sendViaSmsIr(normalized, code);
    return {};
  }
  throw new Error(`Unknown SMS_PROVIDER: ${provider}`);
}

module.exports = { sendOtpSms, normalizePhone };
