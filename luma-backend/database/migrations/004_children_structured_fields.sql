-- Structured child fields (avatar, interests, fears). `profile` retained for backward compatibility.

alter table public.children
  add column if not exists avatar_emoji text not null default '🦊';

alter table public.children
  add column if not exists interests text[] not null default '{}';

alter table public.children
  add column if not exists fears text[] not null default '{}';
