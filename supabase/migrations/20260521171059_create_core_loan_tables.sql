-- Facilite Plus: schema inicial (PRD)

create extension if not exists "pgcrypto";

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text,
  email text,
  created_at timestamptz not null default now()
);

create table public.clients (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  phone text,
  document text,
  address text,
  notes text,
  created_at timestamptz not null default now()
);

create table public.loans (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients (id) on delete cascade,
  amount text not null,
  interest text,
  installments integer,
  status text,
  created_at timestamptz not null default now()
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null references public.loans (id) on delete cascade,
  amount text not null,
  payment_date text,
  method text,
  created_at timestamptz not null default now()
);

create index clients_user_id_idx on public.clients (user_id);
create index loans_client_id_idx on public.loans (client_id);
create index payments_loan_id_idx on public.payments (loan_id);

comment on table public.clients is 'Clientes do gerente (empréstimos)';
comment on table public.loans is 'Empréstimos vinculados a clientes';
comment on table public.payments is 'Pagamentos de empréstimos';
