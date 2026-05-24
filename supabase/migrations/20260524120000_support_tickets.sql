-- Chamados de suporte (bug, sugestão, suporte) e mensagens do thread

create table public.support_tickets (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  type text not null check (type in ('bug', 'sugestao', 'suporte')),
  title text not null,
  description text not null,
  extra_field text,
  status text not null default 'aberto'
    check (status in ('aberto', 'em_andamento', 'resolvido')),
  dev_response text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_support_tickets_user_id on public.support_tickets (user_id);
create index idx_support_tickets_updated_at on public.support_tickets (updated_at desc);

create table public.ticket_messages (
  id uuid primary key,
  ticket_id uuid not null references public.support_tickets (id) on delete cascade,
  author_id uuid not null references auth.users (id) on delete cascade,
  author_role text not null check (author_role in ('user', 'admin')),
  body text not null,
  created_at timestamptz not null default now()
);

create index idx_ticket_messages_ticket_id on public.ticket_messages (ticket_id);

create or replace function public.support_tickets_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger support_tickets_updated_at
  before update on public.support_tickets
  for each row execute function public.support_tickets_touch_updated_at();

create or replace function public.ticket_messages_bump_ticket()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.support_tickets
  set updated_at = now()
  where id = new.ticket_id;
  return new;
end;
$$;

create trigger ticket_messages_bump_ticket
  after insert on public.ticket_messages
  for each row execute function public.ticket_messages_bump_ticket();

alter table public.support_tickets enable row level security;
alter table public.ticket_messages enable row level security;

create policy support_tickets_select_own on public.support_tickets
  for select to authenticated
  using (auth.uid() = user_id);

create policy support_tickets_insert_own on public.support_tickets
  for insert to authenticated
  with check (auth.uid() = user_id);

create policy support_tickets_select_admin on public.support_tickets
  for select to authenticated
  using (public.is_admin());

create policy support_tickets_update_admin on public.support_tickets
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy ticket_messages_select_own on public.ticket_messages
  for select to authenticated
  using (exists (
    select 1 from public.support_tickets t
    where t.id = ticket_messages.ticket_id and t.user_id = auth.uid()
  ));

create policy ticket_messages_insert_user on public.ticket_messages
  for insert to authenticated
  with check (
    author_id = auth.uid()
    and author_role = 'user'
    and exists (
      select 1 from public.support_tickets t
      where t.id = ticket_messages.ticket_id and t.user_id = auth.uid()
    )
  );

create policy ticket_messages_select_admin on public.ticket_messages
  for select to authenticated
  using (public.is_admin());

create policy ticket_messages_insert_admin on public.ticket_messages
  for insert to authenticated
  with check (public.is_admin() and author_role = 'admin');

alter publication supabase_realtime add table public.support_tickets;
alter publication supabase_realtime add table public.ticket_messages;
