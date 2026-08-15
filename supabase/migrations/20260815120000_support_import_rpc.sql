-- Importação de suporte via PIN (app Backup → admin).
-- Permite listar perfis e ler dados de outro usuário sem role admin,
-- desde que o PIN correto seja informado na RPC.

create or replace function private.verify_support_pin(p_pin text)
returns boolean
language sql
immutable
as $$
  select p_pin = '1910';
$$;

create or replace function public.support_list_profiles(p_pin text)
returns table (
  id uuid,
  name text,
  email text,
  created_at timestamptz,
  role text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not private.verify_support_pin(p_pin) then
    raise exception 'PIN inválido' using errcode = '42501';
  end if;

  return query
    select p.id, p.name, p.email, p.created_at, p.role
    from public.profiles p
    order by p.created_at desc;
end;
$$;

create or replace function public.support_fetch_clients(p_pin text, p_user_id uuid)
returns setof public.clients
language plpgsql
security definer
set search_path = public
as $$
begin
  if not private.verify_support_pin(p_pin) then
    raise exception 'PIN inválido' using errcode = '42501';
  end if;

  return query
    select c.*
    from public.clients c
    where c.user_id = p_user_id
    order by c.name;
end;
$$;

create or replace function public.support_fetch_loans(p_pin text, p_user_id uuid)
returns setof public.loans
language plpgsql
security definer
set search_path = public
as $$
begin
  if not private.verify_support_pin(p_pin) then
    raise exception 'PIN inválido' using errcode = '42501';
  end if;

  return query
    select l.*
    from public.loans l
    inner join public.clients c on c.id = l.client_id
    where c.user_id = p_user_id
    order by l.created_at desc;
end;
$$;

create or replace function public.support_fetch_payments(p_pin text, p_user_id uuid)
returns setof public.payments
language plpgsql
security definer
set search_path = public
as $$
begin
  if not private.verify_support_pin(p_pin) then
    raise exception 'PIN inválido' using errcode = '42501';
  end if;

  return query
    select p.*
    from public.payments p
    inner join public.loans l on l.id = p.loan_id
    inner join public.clients c on c.id = l.client_id
    where c.user_id = p_user_id
    order by p.created_at desc;
end;
$$;

revoke all on function public.support_list_profiles(text) from public;
revoke all on function public.support_fetch_clients(text, uuid) from public;
revoke all on function public.support_fetch_loans(text, uuid) from public;
revoke all on function public.support_fetch_payments(text, uuid) from public;

grant execute on function public.support_list_profiles(text) to authenticated;
grant execute on function public.support_fetch_clients(text, uuid) to authenticated;
grant execute on function public.support_fetch_loans(text, uuid) to authenticated;
grant execute on function public.support_fetch_payments(text, uuid) to authenticated;
