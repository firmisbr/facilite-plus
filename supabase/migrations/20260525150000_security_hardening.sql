-- Security hardening: fix all 7 warnings from Security Advisors
--
-- 1. Create private schema (not exposed by PostgREST) and move is_admin() there
--    → eliminates anon + authenticated RPC exposure for is_admin()
-- 2. Revoke EXECUTE on trigger-only functions from PUBLIC
--    → eliminates anon + authenticated RPC exposure for trigger fns
-- 3. Add SET search_path on support_tickets_touch_updated_at
--    → eliminates mutable search_path warning
-- (auth_leaked_password_protection must be enabled in Auth Dashboard)

-- ─── 1. Private schema ────────────────────────────────────────────────────────

create schema if not exists private;

-- Roles that need to traverse private (authenticated for RLS; service_role for admin ops)
grant usage on schema private to authenticated, service_role;

-- ─── 2. Move is_admin() to private ───────────────────────────────────────────
-- set search_path = '' forces fully-qualified names → safe against search_path injection

create or replace function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- authenticated needs EXECUTE so RLS policies that call private.is_admin() work
grant execute on function private.is_admin() to authenticated;

-- ─── 3. Drop all policies that reference public.is_admin() ───────────────────
-- (must drop before dropping the function)

drop policy if exists profiles_select_admin          on public.profiles;
drop policy if exists clients_select_administrador   on public.clients;
drop policy if exists loans_select_admin             on public.loans;
drop policy if exists payments_select_admin          on public.payments;
drop policy if exists support_tickets_select_admin   on public.support_tickets;
drop policy if exists support_tickets_update_admin   on public.support_tickets;
drop policy if exists ticket_messages_select_admin   on public.ticket_messages;
drop policy if exists ticket_messages_insert_admin   on public.ticket_messages;
drop policy if exists version_history_insert_admin   on public.app_version_history;
drop policy if exists version_history_update_admin   on public.app_version_history;
drop policy if exists manifest_insert_admin          on public.app_update_manifest;
drop policy if exists manifest_update_admin          on public.app_update_manifest;

-- ─── 4. Drop public.is_admin() ───────────────────────────────────────────────

drop function if exists public.is_admin();

-- ─── 5. Recreate policies using private.is_admin() ───────────────────────────

create policy profiles_select_admin on public.profiles
  for select to authenticated
  using (private.is_admin());

create policy clients_select_administrador on public.clients
  for select to authenticated
  using (private.is_admin());

create policy loans_select_admin on public.loans
  for select to authenticated
  using (private.is_admin());

create policy payments_select_admin on public.payments
  for select to authenticated
  using (private.is_admin());

create policy support_tickets_select_admin on public.support_tickets
  for select to authenticated
  using (private.is_admin());

create policy support_tickets_update_admin on public.support_tickets
  for update to authenticated
  using (private.is_admin())
  with check (private.is_admin());

create policy ticket_messages_select_admin on public.ticket_messages
  for select to authenticated
  using (private.is_admin());

create policy ticket_messages_insert_admin on public.ticket_messages
  for insert to authenticated
  with check (private.is_admin() and author_role = 'admin');

create policy version_history_insert_admin on public.app_version_history
  for insert to authenticated
  with check (private.is_admin());

create policy version_history_update_admin on public.app_version_history
  for update to authenticated
  using (private.is_admin())
  with check (private.is_admin());

create policy manifest_insert_admin on public.app_update_manifest
  for insert to authenticated
  with check (private.is_admin());

create policy manifest_update_admin on public.app_update_manifest
  for update to authenticated
  using (private.is_admin())
  with check (private.is_admin());

-- ─── 6. Move profiles_default_role() to private (eliminates RPC exposure) ────

create or replace function private.profiles_default_role()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if new.role is null then
      new.role := 'user';
    elsif new.role <> 'user' and not private.is_admin() then
      new.role := 'user';
    end if;
  elsif tg_op = 'UPDATE' then
    if new.role is distinct from old.role and not private.is_admin() then
      new.role := old.role;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_protect_role on public.profiles;
create trigger profiles_protect_role
  before insert or update on public.profiles
  for each row execute function private.profiles_default_role();

drop function if exists public.profiles_default_role();

-- ─── 7. Fix support_tickets_touch_updated_at() search_path ───────────────────

create or replace function public.support_tickets_touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ─── 8. Move ticket_messages_bump_ticket() to private ────────────────────────

create or replace function private.ticket_messages_bump_ticket()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.support_tickets
  set updated_at = now()
  where id = new.ticket_id;
  return new;
end;
$$;

drop trigger if exists ticket_messages_bump_ticket on public.ticket_messages;
create trigger ticket_messages_bump_ticket
  after insert on public.ticket_messages
  for each row execute function private.ticket_messages_bump_ticket();

drop function if exists public.ticket_messages_bump_ticket();
