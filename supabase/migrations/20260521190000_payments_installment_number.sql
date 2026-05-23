alter table public.payments
  add column if not exists installment_number integer;

comment on column public.payments.installment_number is
  'Número da parcela quitada (1-based)';
