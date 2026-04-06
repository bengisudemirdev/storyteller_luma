-- Atomic usage reservation / release for story generation.
-- Prevents double-spend on concurrent requests using:
-- - unique constraint (user_id, date, usage_type)
-- - advisory transaction lock on (user_id, date, usage_type)
-- - single function to check limit and increment

create or replace function public.reserve_story_generate_usage(
  p_user_id uuid,
  p_date date,
  p_plan text,
  p_amount integer,
  p_limit integer
) returns table (
  allowed boolean,
  new_count integer,
  remaining integer
)
language plpgsql
as $$
declare
  current_count integer;
  candidate_count integer;
begin
  if p_amount is null or p_amount <= 0 then
    allowed := false;
    new_count := 0;
    remaining := greatest(p_limit, 0);
    return;
  end if;

  -- Serialize concurrent usage increments for the same user/day/type.
  perform pg_advisory_xact_lock(hashtext(p_user_id::text || '_' || p_date::text || '_story_generate'));

  select ul.count into current_count
  from public.usage_logs ul
  where ul.user_id = p_user_id
    and ul.date = p_date
    and ul.usage_type = 'story_generate'
  for update;

  if current_count is null then
    current_count := 0;
  end if;

  candidate_count := current_count + p_amount;

  if candidate_count > p_limit then
    allowed := false;
    new_count := current_count;
    remaining := greatest(p_limit - current_count, 0);
    return next;
  end if;

  -- Upsert within the same lock.
  insert into public.usage_logs (user_id, usage_type, date, count, plan)
  values (p_user_id, 'story_generate', p_date, candidate_count, p_plan)
  on conflict (user_id, date, usage_type)
  do update
    set count = excluded.count,
        plan = excluded.plan,
        updated_at = now();

  allowed := true;
  new_count := candidate_count;
  remaining := greatest(p_limit - candidate_count, 0);
  return next;
end;
$$ security definer;

create or replace function public.release_story_generate_usage(
  p_user_id uuid,
  p_date date,
  p_amount integer
) returns table (
  new_count integer
)
language plpgsql
as $$
declare
  current_count integer;
  next_count integer;
begin
  if p_amount is null or p_amount <= 0 then
    new_count := 0;
    return next;
  end if;

  perform pg_advisory_xact_lock(hashtext(p_user_id::text || '_' || p_date::text || '_story_generate'));

  select ul.count into current_count
  from public.usage_logs ul
  where ul.user_id = p_user_id
    and ul.date = p_date
    and ul.usage_type = 'story_generate'
  for update;

  if current_count is null then
    new_count := 0;
    return next;
  end if;

  next_count := greatest(current_count - p_amount, 0);

  update public.usage_logs
  set count = next_count,
      updated_at = now()
  where user_id = p_user_id
    and date = p_date
    and usage_type = 'story_generate';

  new_count := next_count;
  return next;
end;
$$ security definer;

