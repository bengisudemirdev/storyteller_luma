-- Supabase/Postgres initial schema for Luma backend.
-- Creates tables used by Express API:
-- - parents (ebeveyn profil satırı; auth.users ile eşlenir)
-- - children
-- - stories
-- - usage_logs
-- - subscriptions

create extension if not exists pgcrypto;

-- updated_at trigger helper
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- parents (app-level profile; her satır auth.users.id ile birebir)
create table if not exists public.parents (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists parents_email_idx on public.parents(email);

drop trigger if exists parents_set_updated_at on public.parents;
create trigger parents_set_updated_at
before update on public.parents
for each row execute function public.set_updated_at();

-- children
create table if not exists public.children (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.parents(id) on delete cascade,
  name text not null,
  age integer,
  profile text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists children_user_id_idx on public.children(user_id);

drop trigger if exists children_set_updated_at on public.children;
create trigger children_set_updated_at
before update on public.children
for each row execute function public.set_updated_at();

-- stories
create table if not exists public.stories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.parents(id) on delete cascade,
  child_id uuid not null references public.children(id) on delete cascade,

  theme text not null,
  age_group text not null,

  title text not null,
  content text not null,
  prompt text not null,

  language text,

  -- Prepared for future media generation
  cover_image_url text,
  audio_url text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists stories_user_id_created_at_idx on public.stories(user_id, created_at desc);
create index if not exists stories_child_id_idx on public.stories(child_id);
create index if not exists stories_theme_idx on public.stories(theme);

drop trigger if exists stories_set_updated_at on public.stories;
create trigger stories_set_updated_at
before update on public.stories
for each row execute function public.set_updated_at();

-- usage_logs
create table if not exists public.usage_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.parents(id) on delete cascade,
  usage_type text not null,
  date date not null,
  count integer not null default 0,
  plan text not null default 'free',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint usage_logs_usage_type_check
    check (usage_type in ('story_generate')),

  constraint usage_logs_plan_check
    check (plan in ('free','premium'))
);

-- Unique daily usage per user/type.
create unique index if not exists usage_logs_user_date_type_unique
on public.usage_logs(user_id, date, usage_type);

create index if not exists usage_logs_user_id_date_idx on public.usage_logs(user_id, date desc);

drop trigger if exists usage_logs_set_updated_at on public.usage_logs;
create trigger usage_logs_set_updated_at
before update on public.usage_logs
for each row execute function public.set_updated_at();

-- subscriptions
create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.parents(id) on delete cascade,
  status text not null default 'inactive',
  plan text not null default 'free',
  current_period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint subscriptions_status_check
    check (status in ('active','inactive')),

  constraint subscriptions_plan_check
    check (plan in ('free','premium'))
);

create index if not exists subscriptions_user_id_period_idx
on public.subscriptions(user_id, current_period_end desc);

drop trigger if exists subscriptions_set_updated_at on public.subscriptions;
create trigger subscriptions_set_updated_at
before update on public.subscriptions
for each row execute function public.set_updated_at();

