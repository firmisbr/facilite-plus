-- Histórico de versões publicadas (somente leitura no app; sem APK antigo)

create table public.app_version_history (
  id          uuid primary key default gen_random_uuid(),
  version     text not null,
  build       integer not null,
  changelog   text,
  released_at timestamptz not null default now(),
  unique (version, build)
);

create index app_version_history_released_at_idx
  on public.app_version_history (released_at desc);

comment on table public.app_version_history is
  'Changelog de cada release; o app lista para consulta (sem download de versões antigas)';

alter table public.app_version_history enable row level security;

create policy version_history_select_authenticated on public.app_version_history
  for select to authenticated using (true);

create policy version_history_insert_admin on public.app_version_history
  for insert to authenticated with check (public.is_admin());

create policy version_history_update_admin on public.app_version_history
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- Copia a versão atual do manifesto para o histórico (se existir)
insert into public.app_version_history (version, build, changelog, released_at)
select version, build, changelog, updated_at
from public.app_update_manifest
where id = 1
on conflict (version, build) do nothing;
