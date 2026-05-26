-- RLS performance: auth_rls_initplan + multiple_permissive_policies
-- Pattern: auth.uid() → (select auth.uid()); merge duplicate SELECT/INSERT policies with OR

-- ─── profiles ────────────────────────────────────────────────────────────────

drop policy if exists profiles_select_own on public.profiles;
drop policy if exists profiles_select_admin on public.profiles;

create policy profiles_select on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id or private.is_admin());

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles
  for insert to authenticated
  with check ((select auth.uid()) = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- ─── clients ─────────────────────────────────────────────────────────────────

drop policy if exists clients_select_own on public.clients;
drop policy if exists clients_select_administrador on public.clients;

create policy clients_select on public.clients
  for select to authenticated
  using ((select auth.uid()) = user_id or private.is_admin());

drop policy if exists clients_insert_own on public.clients;
create policy clients_insert_own on public.clients
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists clients_update_own on public.clients;
create policy clients_update_own on public.clients
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists clients_delete_own on public.clients;
create policy clients_delete_own on public.clients
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- ─── loans ───────────────────────────────────────────────────────────────────

drop policy if exists loans_select_own on public.loans;
drop policy if exists loans_select_admin on public.loans;

create policy loans_select on public.loans
  for select to authenticated
  using (
    private.is_admin()
    or exists (
      select 1 from public.clients c
      where c.id = loans.client_id and c.user_id = (select auth.uid())
    )
  );

drop policy if exists loans_insert_own on public.loans;
create policy loans_insert_own on public.loans
  for insert to authenticated
  with check (exists (
    select 1 from public.clients c
    where c.id = loans.client_id and c.user_id = (select auth.uid())
  ));

drop policy if exists loans_update_own on public.loans;
create policy loans_update_own on public.loans
  for update to authenticated
  using (exists (
    select 1 from public.clients c
    where c.id = loans.client_id and c.user_id = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.clients c
    where c.id = loans.client_id and c.user_id = (select auth.uid())
  ));

drop policy if exists loans_delete_own on public.loans;
create policy loans_delete_own on public.loans
  for delete to authenticated
  using (exists (
    select 1 from public.clients c
    where c.id = loans.client_id and c.user_id = (select auth.uid())
  ));

-- ─── payments ────────────────────────────────────────────────────────────────

drop policy if exists payments_select_own on public.payments;
drop policy if exists payments_select_admin on public.payments;

create policy payments_select on public.payments
  for select to authenticated
  using (
    private.is_admin()
    or exists (
      select 1 from public.loans l
      join public.clients c on c.id = l.client_id
      where l.id = payments.loan_id and c.user_id = (select auth.uid())
    )
  );

drop policy if exists payments_insert_own on public.payments;
create policy payments_insert_own on public.payments
  for insert to authenticated
  with check (exists (
    select 1 from public.loans l
    join public.clients c on c.id = l.client_id
    where l.id = payments.loan_id and c.user_id = (select auth.uid())
  ));

drop policy if exists payments_update_own on public.payments;
create policy payments_update_own on public.payments
  for update to authenticated
  using (exists (
    select 1 from public.loans l
    join public.clients c on c.id = l.client_id
    where l.id = payments.loan_id and c.user_id = (select auth.uid())
  ))
  with check (exists (
    select 1 from public.loans l
    join public.clients c on c.id = l.client_id
    where l.id = payments.loan_id and c.user_id = (select auth.uid())
  ));

drop policy if exists payments_delete_own on public.payments;
create policy payments_delete_own on public.payments
  for delete to authenticated
  using (exists (
    select 1 from public.loans l
    join public.clients c on c.id = l.client_id
    where l.id = payments.loan_id and c.user_id = (select auth.uid())
  ));

-- ─── support_tickets ─────────────────────────────────────────────────────────

drop policy if exists support_tickets_select_own on public.support_tickets;
drop policy if exists support_tickets_select_admin on public.support_tickets;

create policy support_tickets_select on public.support_tickets
  for select to authenticated
  using ((select auth.uid()) = user_id or private.is_admin());

drop policy if exists support_tickets_insert_own on public.support_tickets;
create policy support_tickets_insert_own on public.support_tickets
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

-- ─── ticket_messages ───────────────────────────────────────────────────────────

drop policy if exists ticket_messages_select_own on public.ticket_messages;
drop policy if exists ticket_messages_select_admin on public.ticket_messages;

create policy ticket_messages_select on public.ticket_messages
  for select to authenticated
  using (
    private.is_admin()
    or exists (
      select 1 from public.support_tickets t
      where t.id = ticket_messages.ticket_id and t.user_id = (select auth.uid())
    )
  );

drop policy if exists ticket_messages_insert_user on public.ticket_messages;
drop policy if exists ticket_messages_insert_admin on public.ticket_messages;

create policy ticket_messages_insert on public.ticket_messages
  for insert to authenticated
  with check (
    (private.is_admin() and author_role = 'admin')
    or (
      author_id = (select auth.uid())
      and author_role = 'user'
      and exists (
        select 1 from public.support_tickets t
        where t.id = ticket_messages.ticket_id and t.user_id = (select auth.uid())
      )
    )
  );
