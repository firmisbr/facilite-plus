-- Campos extras no perfil do gestor

alter table public.profiles
  add column if not exists business_name text,
  add column if not exists whatsapp      text,
  add column if not exists pix_key       text;

comment on column public.profiles.business_name is 'Nome do negócio exibido no app (ex.: Crediário do Victor)';
comment on column public.profiles.whatsapp      is 'WhatsApp do gestor (formato livre)';
comment on column public.profiles.pix_key       is 'Chave PIX do gestor para recebimento';
