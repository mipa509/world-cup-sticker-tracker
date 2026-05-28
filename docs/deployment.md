# Deployment Notes

These notes are for maintaining and deploying the app. The public README stays focused on what collectors see and use.

## Local Use
Open `index.html` in a browser, or serve the folder with any static file server.

## Supabase Setup
The static app needs a Supabase project before the nearby trader directory can work.

1. Create a Supabase project.
2. Run `supabase/schema.sql` in the Supabase SQL editor.
3. Enable email magic-link auth in Supabase.
4. Add the public project URL and anon key to `SUPABASE_URL` and `SUPABASE_ANON_KEY` near the top of `index.html`.
5. Keep the service-role key out of this repository and out of the browser.

Until those two public constants are set, the local album tracker still works and the directory panel shows a configuration status.

## Launch Checklist
Run the latest `supabase/schema.sql` in Supabase before deploying this branch. The app expects the hardened RPC signatures and RLS policies from that file.

Before public launch, remove temporary test trader rows created during testing. Delete test contacts first, then test profiles, then remove the test users from Supabase Authentication if they are no longer needed.

To remove temporary test traders from Supabase SQL editor, replace the email addresses first:

```sql
with test_users as (
  select id from auth.users
  where email in ('test-trader-1@example.com', 'test-trader-2@example.com')
)
delete from public.trader_contacts
where user_id in (select id from test_users);

with test_users as (
  select id from auth.users
  where email in ('test-trader-1@example.com', 'test-trader-2@example.com')
)
delete from public.trader_profiles
where user_id in (select id from test_users);
```

## GitHub Pages
You can fork this repository or copy the files into your own GitHub repository and enable GitHub Pages.

1. Fork or create a new empty repository, for example `world-cup-sticker-tracker`.
2. Push the app files.
3. In GitHub: Settings > Pages > Build and deployment > Deploy from a branch > `main` / root.

The app stores sticker data and saved trade proposals in the browser using `localStorage`. Use Export/Import JSON to move data between devices until cloud sync is added.
