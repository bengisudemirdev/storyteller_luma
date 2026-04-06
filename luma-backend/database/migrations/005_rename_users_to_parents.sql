-- Eski projelerde public.users → public.parents (backend + RLS ile uyum).
-- Yeni kurulumlarda 001 zaten parents oluşturur; bu dosya o durumda no-op olur.
-- PostgreSQL tablo rename ile FK'lar (children.user_id vb.) otomatik güncellenir.

do $$
begin
  if to_regclass('public.users') is not null and to_regclass('public.parents') is null then
    alter table public.users rename to parents;

    if exists (
      select 1 from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relkind = 'i' and c.relname = 'users_email_idx'
    ) then
      alter index public.users_email_idx rename to parents_email_idx;
    end if;

    if exists (
      select 1 from pg_trigger t
      join pg_class c on c.oid = t.tgrelid
      join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relname = 'parents' and t.tgname = 'users_set_updated_at'
    ) then
      execute 'alter trigger users_set_updated_at on public.parents rename to parents_set_updated_at';
    end if;
  end if;
end $$;
