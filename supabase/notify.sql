-- ============================================================
-- Get a message every time someone submits a new notice.
-- Works with any "incoming webhook" URL: Discord, Slack, Make, Zapier, ntfy ...
--
-- BEFORE running this:
--   1. Dashboard > Database > Extensions > search "pg_net" > enable it.
--   2. Create a webhook URL in the place you want the message to appear.
--   3. Run this one line ONCE, with your URL pasted in (it is kept in the Vault, not in the code):
--
--        select vault.create_secret('PASTE-YOUR-WEBHOOK-URL-HERE', 'notice_webhook_url');
--
-- THEN paste and run everything below.
-- ============================================================

create or replace function public.notify_new_notice()
returns trigger
language plpgsql
security definer          -- runs with your rights, so it may read the Vault
set search_path = ''
as $$
declare
  hook_url text;
  pending  int;
  msg      text;
begin
  begin
    select decrypted_secret into hook_url
      from vault.decrypted_secrets
     where name = 'notice_webhook_url';

    if hook_url is not null then
      select count(*) into pending from public.notices where status = 'pending';

      -- Deliberately contains NOTHING the visitor typed (no title, no contact):
      -- keeps personal details out of chat tools and stops anyone sneaking in @-mentions or links.
      msg := 'Ny notis väntar på godkännande på anslagstavlan (' || pending || ' totalt).';

      perform net.http_post(
        url     := hook_url,
        headers := '{"Content-Type": "application/json"}'::jsonb,
        -- Discord reads "content", Slack/Make/Zapier read "text". Extra keys are ignored.
        body    := jsonb_build_object(
                     'content', msg,
                     'text', msg,
                     'allowed_mentions', jsonb_build_object('parse', jsonb_build_array())
                   )
      );
    end if;
  exception when others then
    -- A broken notification must never stop a visitor's notice from being saved.
    null;
  end;
  return new;
end;
$$;

revoke execute on function public.notify_new_notice() from public, anon, authenticated;

drop trigger if exists notice_notify on public.notices;
create trigger notice_notify
  after insert on public.notices
  for each row execute function public.notify_new_notice();
