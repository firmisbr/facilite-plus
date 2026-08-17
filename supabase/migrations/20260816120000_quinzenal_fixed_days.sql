-- Quinzenal com dois dias fixos no mês (opcional).
-- Null em ambos = comportamento antigo (a cada 14 dias).

alter table public.loans
  add column if not exists quinzenal_day_1 integer,
  add column if not exists quinzenal_day_2 integer;

comment on column public.loans.quinzenal_day_1 is
  'Dia fixo 1 do mês (1-31) para quinzenal; null com day_2 = intervalo de 14 dias';
comment on column public.loans.quinzenal_day_2 is
  'Dia fixo 2 do mês (1-31) para quinzenal';
