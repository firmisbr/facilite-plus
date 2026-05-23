-- Perfis com papel (user | admin) e leitura cross-user para administradores

alter table public.profiles
  add column if not exists role text not null default 'user'
    check (role in ('user', 'admin'));

comment on column public.profiles.role is 'Papel do usuário: user (padrão) ou admin';

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- Perfis ausentes (usuários criados antes desta migration)
insert into public.profiles (id, email, name, role)
select
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data->>'name', split_part(u.email, '@', 1)),
  case
    when lower(u.email) = lower('firmis.br@gmail.com') then 'admin'
    else 'user'
  end
from auth.users u
where not exists (
  select 1 from public.profiles p where p.id = u.id
);

update public.profiles p
set role = 'admin'
from auth.users u
where p.id = u.id
  and lower(u.email) = lower('firmis.br@gmail.com');

create or replace function public.profiles_default_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    if new.role is null then
      new.role := 'user';
    elsif new.role <> 'user' and not public.is_admin() then
      new.role := 'user';
    end if;
  elsif tg_op = 'UPDATE' then
    if new.role is distinct from old.role and not public.is_admin() then
      new.role := old.role;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_protect_role on public.profiles;
create trigger profiles_protect_role
  before insert or update on public.profiles
  for each row execute function public.profiles_default_role();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    case
      when lower(new.email) = lower('firmis.br@gmail.com') then 'admin'
      else 'user'
    end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create policy profiles_select_admin on public.profiles
  for select to authenticated
  using (public.is_admin());

create policy clients_select_administrador on public.clients
  for select to authenticated
  using (public.is_admin());

create policy loans_select_admin on public.loans
  for select to authenticated
  using (public.is_admin());

create policy payments_select_admin on public.payments
  for select to authenticated
  using (public.is_admin());
