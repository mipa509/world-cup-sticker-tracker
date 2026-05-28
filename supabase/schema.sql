begin;

create or replace function public.valid_sticker_ids(ids text[])
returns boolean
language sql
immutable
as $$
  select coalesce(
    bool_and(id ~ '^[A-Z]{3}-[0-9]{2,3}$' and char_length(id) <= 7),
    true
  )
  from unnest(coalesce(ids, '{}'::text[])) as sticker(id);
$$;

create table if not exists public.trader_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 60),
  status text not null default 'open' check (status in ('open', 'busy', 'paused')),
  area_label text not null check (char_length(area_label) between 1 and 80),
  approx_lat double precision not null check (approx_lat between -90 and 90),
  approx_lng double precision not null check (approx_lng between -180 and 180),
  needs text[] not null default '{}',
  swaps text[] not null default '{}',
  active boolean not null default true,
  updated_at timestamptz not null default now(),
  constraint trader_profiles_needs_count check (cardinality(needs) <= 1300),
  constraint trader_profiles_swaps_count check (cardinality(swaps) <= 1300),
  constraint trader_profiles_active_status_consistent check (
    (active = true and status in ('open', 'busy'))
    or (active = false and status = 'paused')
  ),
  constraint trader_profiles_needs_valid_ids check (public.valid_sticker_ids(needs)),
  constraint trader_profiles_swaps_valid_ids check (public.valid_sticker_ids(swaps))
);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'trader_profiles_active_status_consistent'
      and conrelid = 'public.trader_profiles'::regclass
  ) then
    update public.trader_profiles
    set status = 'paused'
    where active = false and status <> 'paused';

    update public.trader_profiles
    set active = false
    where active = true and status = 'paused';

    alter table public.trader_profiles
      add constraint trader_profiles_active_status_consistent check (
        (active = true and status in ('open', 'busy'))
        or (active = false and status = 'paused')
      );
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'trader_profiles_needs_valid_ids'
      and conrelid = 'public.trader_profiles'::regclass
  ) then
    alter table public.trader_profiles
      add constraint trader_profiles_needs_valid_ids check (public.valid_sticker_ids(needs));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'trader_profiles_swaps_valid_ids'
      and conrelid = 'public.trader_profiles'::regclass
  ) then
    alter table public.trader_profiles
      add constraint trader_profiles_swaps_valid_ids check (public.valid_sticker_ids(swaps));
  end if;
end;
$$;

create table if not exists public.trader_contacts (
  user_id uuid primary key references auth.users(id) on delete cascade,
  contact_type text not null check (contact_type in ('whatsapp', 'facebook', 'email', 'other')),
  contact_value text not null check (char_length(contact_value) between 1 and 180),
  updated_at timestamptz not null default now()
);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.round_trader_profile_location()
returns trigger
language plpgsql
as $$
begin
  new.approx_lat = round(new.approx_lat::numeric, 2)::double precision;
  new.approx_lng = round(new.approx_lng::numeric, 2)::double precision;
  return new;
end;
$$;

drop trigger if exists touch_trader_profiles_updated_at on public.trader_profiles;
create trigger touch_trader_profiles_updated_at
before update on public.trader_profiles
for each row execute function public.touch_updated_at();

drop trigger if exists round_trader_profiles_location on public.trader_profiles;
create trigger round_trader_profiles_location
before insert or update on public.trader_profiles
for each row execute function public.round_trader_profile_location();

drop trigger if exists touch_trader_contacts_updated_at on public.trader_contacts;
create trigger touch_trader_contacts_updated_at
before update on public.trader_contacts
for each row execute function public.touch_updated_at();

update public.trader_profiles
set
  approx_lat = round(approx_lat::numeric, 2)::double precision,
  approx_lng = round(approx_lng::numeric, 2)::double precision
where approx_lat <> round(approx_lat::numeric, 2)::double precision
   or approx_lng <> round(approx_lng::numeric, 2)::double precision;

alter table public.trader_profiles enable row level security;
alter table public.trader_contacts enable row level security;

drop policy if exists trader_profiles_select_active_or_own on public.trader_profiles;
drop policy if exists trader_profiles_select_own on public.trader_profiles;
create policy trader_profiles_select_own
on public.trader_profiles
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists trader_profiles_insert_own on public.trader_profiles;
create policy trader_profiles_insert_own
on public.trader_profiles
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists trader_profiles_update_own on public.trader_profiles;
create policy trader_profiles_update_own
on public.trader_profiles
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists trader_profiles_delete_own on public.trader_profiles;
create policy trader_profiles_delete_own
on public.trader_profiles
for delete
to authenticated
using (user_id = auth.uid());

drop policy if exists trader_contacts_select_own on public.trader_contacts;
create policy trader_contacts_select_own
on public.trader_contacts
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists trader_contacts_insert_own on public.trader_contacts;
create policy trader_contacts_insert_own
on public.trader_contacts
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists trader_contacts_update_own on public.trader_contacts;
create policy trader_contacts_update_own
on public.trader_contacts
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists trader_contacts_delete_own on public.trader_contacts;
create policy trader_contacts_delete_own
on public.trader_contacts
for delete
to authenticated
using (user_id = auth.uid());

create or replace function public.distance_km(
  lat_a double precision,
  lng_a double precision,
  lat_b double precision,
  lng_b double precision
)
returns double precision
language sql
immutable
as $$
  select 6371 * 2 * asin(
    sqrt(
      power(sin(radians((lat_b - lat_a) / 2)), 2)
      + cos(radians(lat_a)) * cos(radians(lat_b)) * power(sin(radians((lng_b - lng_a) / 2)), 2)
    )
  );
$$;

drop function if exists public.match_nearby_traders(text[], text[], double precision, double precision, double precision);
drop function if exists public.reveal_trader_contact(uuid, text[], text[]);

create or replace function public.match_nearby_traders(
  max_distance_km double precision default 100
)
returns table (
  user_id uuid,
  display_name text,
  status text,
  area_label text,
  approx_lat double precision,
  approx_lng double precision,
  needs text[],
  swaps text[],
  can_give text[],
  can_receive text[],
  balanced_count integer,
  one_way_count integer,
  distance_km double precision,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  with viewer as (
    select
      p.needs,
      p.swaps,
      p.approx_lat as lat,
      p.approx_lng as lng,
      least(100, greatest(1, coalesce(max_distance_km, 100))) as radius_km
    from public.trader_profiles p
    where auth.uid() is not null
      and p.user_id = auth.uid()
      and p.active = true
  ),
  candidates as (
    select
      p.user_id,
      p.display_name,
      p.status,
      p.area_label,
      p.approx_lat,
      p.approx_lng,
      p.needs,
      p.swaps,
      coalesce((select array_agg(wanted.id order by wanted.id) from unnest(p.needs) as wanted(id) where wanted.id = any(v.swaps)), '{}'::text[]) as can_give,
      coalesce((select array_agg(offered.id order by offered.id) from unnest(p.swaps) as offered(id) where offered.id = any(v.needs)), '{}'::text[]) as can_receive,
      public.distance_km(v.lat, v.lng, p.approx_lat, p.approx_lng) as distance_km,
      p.updated_at
    from public.trader_profiles p
    cross join viewer v
    where p.active = true
      and p.user_id <> auth.uid()
  )
  select
    c.user_id,
    c.display_name,
    c.status,
    c.area_label,
    c.approx_lat,
    c.approx_lng,
    c.needs,
    c.swaps,
    c.can_give,
    c.can_receive,
    least(cardinality(c.can_give), cardinality(c.can_receive))::integer as balanced_count,
    (cardinality(c.can_give) + cardinality(c.can_receive))::integer as one_way_count,
    c.distance_km,
    c.updated_at
  from candidates c
  cross join viewer v
  where c.distance_km <= v.radius_km
    and (cardinality(c.can_give) > 0 or cardinality(c.can_receive) > 0)
  order by
    least(cardinality(c.can_give), cardinality(c.can_receive)) desc,
    (cardinality(c.can_give) + cardinality(c.can_receive)) desc,
    c.distance_km asc
  limit 50;
$$;

create or replace function public.reveal_trader_contact(
  trader_id uuid
)
returns table (
  contact_type text,
  contact_value text
)
language sql
stable
security definer
set search_path = public
as $$
  select c.contact_type, c.contact_value
  from public.trader_profiles viewer
  join public.trader_profiles p on p.user_id = trader_id
  join public.trader_contacts c on c.user_id = p.user_id
  where auth.uid() is not null
    and viewer.user_id = auth.uid()
    and viewer.active = true
    and p.user_id <> auth.uid()
    and p.active = true
    and (
      exists (select 1 from unnest(p.needs) as wanted(id) where wanted.id = any(viewer.swaps))
      or exists (select 1 from unnest(p.swaps) as offered(id) where offered.id = any(viewer.needs))
    )
  limit 1;
$$;

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.trader_profiles to authenticated;
grant select, insert, update, delete on public.trader_contacts to authenticated;
revoke all on function public.match_nearby_traders(double precision) from public;
revoke all on function public.reveal_trader_contact(uuid) from public;
grant execute on function public.match_nearby_traders(double precision) to authenticated;
grant execute on function public.reveal_trader_contact(uuid) to authenticated;

commit;
