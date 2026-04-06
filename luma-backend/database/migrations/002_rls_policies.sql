-- Row Level Security policies for frontend access.
-- Backend uses Supabase service_role, but RLS must still be correct for anon/authenticated keys.
--
-- Eski veritabanında hâlâ public.users varsa: önce 005_rename_users_to_parents.sql çalıştırın,
-- sonra bu dosyayı uygulayın (002 public.parents bekler).

-- PARENTS (eski adı public.users olan tablolar 005 migration ile parents olur)
alter table public.parents enable row level security;

drop policy if exists users_select_own on public.parents;
drop policy if exists users_update_own on public.parents;
drop policy if exists users_insert_own on public.parents;
drop policy if exists parents_select_own on public.parents;
drop policy if exists parents_update_own on public.parents;
drop policy if exists parents_insert_own on public.parents;

create policy parents_select_own
on public.parents
for select
using (id = auth.uid());

create policy parents_update_own
on public.parents
for update
using (id = auth.uid())
with check (id = auth.uid());

create policy parents_insert_own
on public.parents
for insert
with check (id = auth.uid());

-- CHILDREN
alter table public.children enable row level security;

drop policy if exists children_select_own on public.children;
create policy children_select_own
on public.children
for select
using (user_id = auth.uid());

drop policy if exists children_insert_own on public.children;
create policy children_insert_own
on public.children
for insert
with check (user_id = auth.uid());

drop policy if exists children_update_own on public.children;
create policy children_update_own
on public.children
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- STORIES
alter table public.stories enable row level security;

drop policy if exists stories_select_own on public.stories;
create policy stories_select_own
on public.stories
for select
using (user_id = auth.uid());

drop policy if exists stories_insert_own on public.stories;
create policy stories_insert_own
on public.stories
for insert
with check (
  user_id = auth.uid()
  and exists (
    select 1 from public.children c
    where c.id = stories.child_id
      and c.user_id = auth.uid()
  )
);

drop policy if exists stories_update_own on public.stories;
create policy stories_update_own
on public.stories
for update
using (user_id = auth.uid())
with check (
  user_id = auth.uid()
  and exists (
    select 1 from public.children c
    where c.id = stories.child_id
      and c.user_id = auth.uid()
  )
);

-- SUBSCRIPTIONS
alter table public.subscriptions enable row level security;

drop policy if exists subscriptions_select_own on public.subscriptions;
create policy subscriptions_select_own
on public.subscriptions
for select
using (user_id = auth.uid());

drop policy if exists subscriptions_insert_own on public.subscriptions;
create policy subscriptions_insert_own
on public.subscriptions
for insert
with check (user_id = auth.uid());

drop policy if exists subscriptions_update_own on public.subscriptions;
create policy subscriptions_update_own
on public.subscriptions
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- USAGE_LOGS (optional but safe for future usage screens)
alter table public.usage_logs enable row level security;

drop policy if exists usage_logs_select_own on public.usage_logs;
create policy usage_logs_select_own
on public.usage_logs
for select
using (user_id = auth.uid());

