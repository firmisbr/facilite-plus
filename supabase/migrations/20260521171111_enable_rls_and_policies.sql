-- RLS: dados isolados por usuário autenticado

alter table public.profiles enable row level security;
alter table public.clients enable row level security;
alter table public.loans enable row level security;
alter table public.payments enable row level security;

create policy profiles_select_own on public.profiles
  for select to authenticated using (auth.uid() = id);

create policy profiles_insert_own on public.profiles
  for insert to authenticated with check (auth.uid() = id);

create policy profiles_update_own on public.profiles
  for update to authenticated
  using (auth.uid() = id) with check (auth.uid() = id);

create policy clients_select_own on public.clients
  for select to authenticated using (auth.uid() = user_id);

create policy clients_insert_own on public.clients
  for insert to authenticated with check (auth.uid() = user_id);

create policy clients_update_own on public.clients
  for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy clients_delete_own on public.clients
  for delete to authenticated using (auth.uid() = user_id);

create policy loans_select_own on public.loans
  for select to authenticated
  using (exists (
    select 1 from public.clients c
    where c.id = loans.client_id and c.user_id = auth.uid()
  ));

create policy loans_insert_own on public.loans
  for insert to authenticated
  with check (exists (
    select 1 from public.clients c
    where c.id = loans.client_id and c.user_id = auth.uid()
  ));

create policy loans_update_own on public.loans
  for update to authenticated
  using (exists (
    select 1 from public.clients c
    where c.id = loans.client_id and c.user_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.clients c
    where c.id = loans.client_id and c.user_id = auth.uid()
  ));

create policy loans_delete_own on public.loans
  for delete to authenticated
  using (exists (
    select 1 from public.clients c
    where c.id = loans.client_id and c.user_id = auth.uid()
  ));

create policy payments_select_own on public.payments
  for select to authenticated
  using (exists (
    select 1 from public.loans l
    join public.clients c on c.id = l.client_id
    where l.id = payments.loan_id and c.user_id = auth.uid()
  ));

create policy payments_insert_own on public.payments
  for insert to authenticated
  with check (exists (
    select 1 from public.loans l
    join public.clients c on c.id = l.client_id
    where l.id = payments.loan_id and c.user_id = auth.uid()
  ));

create policy payments_update_own on public.payments
  for update to authenticated
  using (exists (
    select 1 from public.loans l
    join public.clients c on c.id = l.client_id
    where l.id = payments.loan_id and c.user_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.loans l
    join public.clients c on c.id = l.client_id
    where l.id = payments.loan_id and c.user_id = auth.uid()
  ));

create policy payments_delete_own on public.payments
  for delete to authenticated
  using (exists (
    select 1 from public.loans l
    join public.clients c on c.id = l.client_id
    where l.id = payments.loan_id and c.user_id = auth.uid()
  ));
