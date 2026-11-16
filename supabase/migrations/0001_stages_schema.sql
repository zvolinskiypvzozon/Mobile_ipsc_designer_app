create extension if not exists pgcrypto;

create table public.stages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.stage_elements (
  id uuid primary key default gen_random_uuid(),
  stage_id uuid not null references public.stages (id) on delete cascade,
  type text not null check (
    type in (
      'paperTarget',
      'popper',
      'plate',
      'noShoot',
      'wall',
      'barrier',
      'faultLine',
      'shootingPosition'
    )
  ),
  position_x double precision not null,
  position_y double precision not null,
  rotation double precision not null default 0,
  width double precision not null,
  height double precision not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create index stages_user_id_idx on public.stages (user_id);
create index stage_elements_stage_id_idx on public.stage_elements (stage_id);

alter table public.stages enable row level security;
alter table public.stage_elements enable row level security;

create policy "users_select_own_stages" on public.stages
  for select using (auth.uid() = user_id);

create policy "users_insert_own_stages" on public.stages
  for insert with check (auth.uid() = user_id);

create policy "users_update_own_stages" on public.stages
  for update using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "users_delete_own_stages" on public.stages
  for delete using (auth.uid() = user_id);

create policy "users_select_own_stage_elements" on public.stage_elements
  for select using (
    exists (
      select 1
      from public.stages s
      where s.id = stage_elements.stage_id
        and s.user_id = auth.uid()
    )
  );

create policy "users_insert_own_stage_elements" on public.stage_elements
  for insert with check (
    exists (
      select 1
      from public.stages s
      where s.id = stage_elements.stage_id
        and s.user_id = auth.uid()
    )
  );

create policy "users_update_own_stage_elements" on public.stage_elements
  for update using (
    exists (
      select 1
      from public.stages s
      where s.id = stage_elements.stage_id
        and s.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.stages s
      where s.id = stage_elements.stage_id
        and s.user_id = auth.uid()
    )
  );

create policy "users_delete_own_stage_elements" on public.stage_elements
  for delete using (
    exists (
      select 1
      from public.stages s
      where s.id = stage_elements.stage_id
        and s.user_id = auth.uid()
    )
  );

create or replace function public.set_stages_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger stages_set_updated_at
  before update on public.stages
  for each row
  execute function public.set_stages_updated_at();
