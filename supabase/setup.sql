-- ============================================================
-- Anslagstavla (noticeboard) – database setup
-- Paste this whole file into Supabase > SQL Editor > New query > Run.
-- ============================================================

-- 1. The table. Every notice starts as 'pending'.
create table public.notices (
  id          bigint generated always as identity primary key,
  title       text not null check (char_length(btrim(title))       between 1 and 80),
  description text not null check (char_length(btrim(description)) between 1 and 500),
  contact     text not null check (char_length(btrim(contact))     between 1 and 100),
  status      text not null default 'pending'
              check (status in ('pending', 'approved', 'rejected')),
  created_at  timestamptz not null default now()
);

-- 2. Turn on Row Level Security: with no policy, nobody can touch any row.
alter table public.notices enable row level security;

-- 3. Policies = the ONLY things the public website is allowed to do.
--    (You, in the Supabase dashboard, are not affected by these.)
create policy "anyone can read approved notices"
  on public.notices for select
  to anon, authenticated
  using (status = 'approved');

create policy "anyone can submit a notice, but only as pending"
  on public.notices for insert
  to anon, authenticated
  with check (status = 'pending');

-- 4. Second lock: limit which COLUMNS the public may read / write.
--    Visitors can never set status, id or created_at themselves.
revoke all on public.notices from anon, authenticated;
grant select (id, title, description, contact, created_at) on public.notices to anon, authenticated;
grant insert (title, description, contact)                 on public.notices to anon, authenticated;
