-- ONLY for projects that already ran an older setup.sql (where status was plain text).
-- Turns "status" into a drop-down (pending / approved / rejected) in the Table Editor.
-- Paste into Supabase > SQL Editor > Run. Your existing notices are kept.
begin;

create type public.notice_status as enum ('pending', 'approved', 'rejected');

-- Postgres won't change a column's type while rules/constraints depend on it,
-- so: remove them, change the type, put them back.
drop policy "anyone can read approved notices" on public.notices;
drop policy "anyone can submit a notice, but only as pending" on public.notices;
alter table public.notices drop constraint notices_status_check;

alter table public.notices alter column status drop default;
alter table public.notices
  alter column status type public.notice_status using status::public.notice_status;
alter table public.notices alter column status set default 'pending';

create policy "anyone can read approved notices"
  on public.notices for select
  to anon, authenticated
  using (status = 'approved');

create policy "anyone can submit a notice, but only as pending"
  on public.notices for insert
  to anon, authenticated
  with check (status = 'pending');

commit;
