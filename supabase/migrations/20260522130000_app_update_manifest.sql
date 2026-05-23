-- Manifesto de versão do app para OTA interno

create table public.app_update_manifest (
  id           integer primary key default 1 check (id = 1),
  version      text not null,
  build        integer not null,
  apk_url      text not null,
  min_version  text,
  changelog    text,
  updated_at   timestamptz not null default now()
);

comment on table public.app_update_manifest is 'Singleton: versão mais recente do APK disponível para download OTA';

alter table public.app_update_manifest enable row level security;

-- Leitura pública (user autenticado)
create policy manifest_select_authenticated on public.app_update_manifest
  for select to authenticated using (true);

-- Escrita somente admin
create policy manifest_insert_admin on public.app_update_manifest
  for insert to authenticated with check (public.is_admin());

create policy manifest_update_admin on public.app_update_manifest
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Linha inicial — apk_url real: use scripts/release.ps1 ou UPDATE manual
insert into public.app_update_manifest (id, version, build, apk_url, changelog)
values (
  1,
  '1.0.0',
  1,
  'https://example.com/placeholder.apk',
  'Versão inicial'
)
on conflict (id) do nothing;
