alter table public.stage_elements
  add column if not exists pitch real not null default 0;
