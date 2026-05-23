-- Campos para criação unificada de empréstimo + cliente

alter table public.clients
  add column if not exists email text;

alter table public.loans
  add column if not exists periodicity text,
  add column if not exists first_due_date text;

comment on column public.clients.email is 'E-mail opcional do cliente';
comment on column public.loans.periodicity is 'diaria, semanal, quinzenal, mensal';
comment on column public.loans.first_due_date is 'Data do primeiro vencimento (ISO)';
