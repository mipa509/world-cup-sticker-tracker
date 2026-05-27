-- Temporary seed data for testing nearby trader matching.
--
-- Before running:
-- 1. In Supabase, open Authentication > Users.
-- 2. Create two test users, for example:
--    test-trader-1@example.com
--    test-trader-2@example.com
-- 3. Copy each user's UUID from the Users table.
-- 4. Replace the two UUID values below.
--
-- This script does not create auth users. It only publishes trader
-- profiles and contacts for existing auth.users rows.

do $$
declare
  test_trader_one uuid := '00000000-0000-0000-0000-000000000001'::uuid;
  test_trader_two uuid := '00000000-0000-0000-0000-000000000002'::uuid;
begin
  if test_trader_one = '00000000-0000-0000-0000-000000000001'::uuid
     or test_trader_two = '00000000-0000-0000-0000-000000000002'::uuid then
    raise exception 'Replace test_trader_one and test_trader_two with real auth.users UUIDs first.';
  end if;

  if not exists (select 1 from auth.users where id = test_trader_one) then
    raise exception 'test_trader_one does not exist in auth.users: %', test_trader_one;
  end if;

  if not exists (select 1 from auth.users where id = test_trader_two) then
    raise exception 'test_trader_two does not exist in auth.users: %', test_trader_two;
  end if;

  delete from public.trader_contacts where user_id in (test_trader_one, test_trader_two);
  delete from public.trader_profiles where user_id in (test_trader_one, test_trader_two);

  insert into public.trader_profiles (
    user_id,
    display_name,
    status,
    area_label,
    approx_lat,
    approx_lng,
    needs,
    swaps,
    active
  )
  values
    (
      test_trader_one,
      'Alex Test - North London',
      'open',
      'North London, UK',
      51.55,
      -0.14,
      array['ARG-01', 'BRA-02', 'ENG-05', 'MEX-03', 'SCO-13', 'USA-08', 'EXT-01'],
      array['MEX-01', 'MEX-02', 'BRA-03', 'ENG-06', 'USA-04', 'FRA-09', 'EXT-02', 'ARG-10'],
      true
    ),
    (
      test_trader_two,
      'Sam Test - West London',
      'open',
      'West London, UK',
      51.50,
      -0.30,
      array['MEX-01', 'BRA-03', 'USA-04', 'FRA-09', 'EXT-02', 'ARG-10'],
      array['ARG-01', 'BRA-02', 'ENG-05', 'MEX-03', 'SCO-13', 'USA-08', 'EXT-01'],
      true
    );

  insert into public.trader_contacts (
    user_id,
    contact_type,
    contact_value
  )
  values
    (test_trader_one, 'other', 'Test contact only - Alex'),
    (test_trader_two, 'other', 'Test contact only - Sam');
end $$;

-- Cleanup after testing:
--
-- delete from public.trader_contacts
-- where user_id in (
--   'REPLACE_WITH_TEST_TRADER_ONE_UUID'::uuid,
--   'REPLACE_WITH_TEST_TRADER_TWO_UUID'::uuid
-- );
--
-- delete from public.trader_profiles
-- where user_id in (
--   'REPLACE_WITH_TEST_TRADER_ONE_UUID'::uuid,
--   'REPLACE_WITH_TEST_TRADER_TWO_UUID'::uuid
-- );
