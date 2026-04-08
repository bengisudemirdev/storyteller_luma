-- Production Supabase şemasını luma-backend (Express + supabase-js) ile hizalar.
-- Sorun: Tablolarda parent_id varken kod user_id bekliyor; stories'te zorunlu kolonlar eksik.
--
-- Çalıştırmadan önce yedek alın. SQL Editor'da tek seferde çalıştırılabilir.
-- RLS politikaları kolon adına göre ifade içeriyorsa: rename sonrası çoğu durumda PG günceller;
-- hata kalırsa Dashboard'dan ilgili policy'leri silip database/migrations/002_rls_policies.sql ile yeniden oluşturun.

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- children
-- ---------------------------------------------------------------------------
alter table public.children
  add column if not exists profile text;

do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'children' and column_name = 'parent_id'
  )
  and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'children' and column_name = 'user_id'
  ) then
    alter table public.children rename column parent_id to user_id;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- stories
-- ---------------------------------------------------------------------------
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'stories' and column_name = 'parent_id'
  )
  and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'stories' and column_name = 'user_id'
  ) then
    alter table public.stories rename column parent_id to user_id;
  end if;
end $$;

alter table public.stories
  add column if not exists age_group text not null default 'general';

alter table public.stories
  add column if not exists prompt text not null default '';

alter table public.stories
  add column if not exists language text;

alter table public.stories
  add column if not exists cover_image_url text;

alter table public.stories
  add column if not exists audio_url text;

alter table public.stories
  add column if not exists updated_at timestamptz not null default now();

drop trigger if exists stories_set_updated_at on public.stories;
create trigger stories_set_updated_at
before update on public.stories
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- parents (opsiyonel; 001 ile uyum)
-- ---------------------------------------------------------------------------
alter table public.parents
  add column if not exists updated_at timestamptz not null default now();

drop trigger if exists parents_set_updated_at on public.parents;
create trigger parents_set_updated_at
before update on public.parents
for each row execute function public.set_updated_at();
