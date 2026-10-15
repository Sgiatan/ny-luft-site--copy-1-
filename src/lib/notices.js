// Everything the website says to the database lives in this one small file.
// It talks to Supabase's REST API directly, so there's nothing extra to install.
// What visitors are allowed to do is decided by the rules in supabase/setup.sql,
// not by this code – so it's safe that the key below is visible in the browser.

const URL = (import.meta.env.PUBLIC_SUPABASE_URL || '').replace(/\/$/, '');
const KEY = import.meta.env.PUBLIC_SUPABASE_KEY;

function assertConfigured() {
  if (!URL || !KEY) {
    throw new Error('Missing PUBLIC_SUPABASE_URL / PUBLIC_SUPABASE_KEY – copy .env.example to .env and fill it in.');
  }
}

/** Approved notices, newest first. (The database only ever returns approved ones.) */
export async function fetchNotices() {
  assertConfigured();
  const res = await fetch(
    `${URL}/rest/v1/notices?select=id,title,description,contact,created_at&order=created_at.desc&limit=50`,
    { headers: { apikey: KEY } },
  );
  if (!res.ok) throw new Error(`Could not load notices (HTTP ${res.status})`);
  return res.json();
}

/** Sends a new notice. It is saved as "pending" and stays hidden until you approve it. */
export async function submitNotice({ title, description, contact }) {
  assertConfigured();
  const res = await fetch(`${URL}/rest/v1/notices`, {
    method: 'POST',
    headers: { apikey: KEY, 'Content-Type': 'application/json', Prefer: 'return=minimal' },
    body: JSON.stringify({ title, description, contact }),
  });
  if (!res.ok) throw new Error(`Could not send notice (HTTP ${res.status})`);
}

/** "2026-09-28T11:12:00+00:00" -> "2026-09-28, 13:12" (always Swedish time) */
export function formatDate(iso) {
  const text = new Intl.DateTimeFormat('sv-SE', {
    timeZone: 'Europe/Stockholm',
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit',
  }).format(new Date(iso));
  return text.replace(' ', ', ');
}
