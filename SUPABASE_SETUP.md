# Supabase Setup For `saidia_app`

Run this SQL in Supabase SQL Editor (safe/idempotent where possible) to align with the app changes.

```sql
-- 1) Core profile + wallet tables used by signup/login
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  email text not null unique,
  phone text unique,
  role text not null default 'customer' check (role in ('customer', 'provider', 'admin')),
  "providerStatus" text,
  "createdAt" timestamptz not null default timezone('utc', now()),
  "updatedAt" timestamptz not null default timezone('utc', now())
);

create table if not exists public.wallets (
  "userId" uuid primary key references public.users(id) on delete cascade,
  balance numeric not null default 0,
  currency text not null default 'UGX',
  "createdAt" timestamptz not null default timezone('utc', now()),
  "updatedAt" timestamptz not null default timezone('utc', now())
);

-- 2) Keep updatedAt fresh
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new."updatedAt" = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists trg_users_updated_at on public.users;
create trigger trg_users_updated_at
before update on public.users
for each row execute function public.set_updated_at();

drop trigger if exists trg_wallets_updated_at on public.wallets;
create trigger trg_wallets_updated_at
before update on public.wallets
for each row execute function public.set_updated_at();

-- 3) Auto-create profile + wallet at auth signup
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (id, name, email, phone, role)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data->>'name', ''),
      split_part(coalesce(new.email, new.phone, new.id::text), '@', 1)
    ),
    coalesce(
      nullif(lower(new.email), ''),
      nullif(lower(new.raw_user_meta_data->>'email'), ''),
      new.id::text || '@phone.local'
    ),
    coalesce(nullif(new.phone, ''), nullif(new.raw_user_meta_data->>'phone', '')),
    'customer'
  )
  on conflict (id) do update
  set
    name = excluded.name,
    email = excluded.email,
    phone = coalesce(excluded.phone, public.users.phone);

  insert into public.wallets ("userId", balance, currency)
  values (new.id, 0, 'UGX')
  on conflict ("userId") do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_auth_user();

-- 4) RLS baseline for users + wallets
alter table public.users enable row level security;
alter table public.wallets enable row level security;

drop policy if exists "users_select_own" on public.users;
create policy "users_select_own"
on public.users for select
using (auth.uid() = id);

drop policy if exists "users_insert_own" on public.users;
create policy "users_insert_own"
on public.users for insert
with check (auth.uid() = id);

drop policy if exists "users_update_own" on public.users;
create policy "users_update_own"
on public.users for update
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "wallets_select_own" on public.wallets;
create policy "wallets_select_own"
on public.wallets for select
using (auth.uid() = "userId");

drop policy if exists "wallets_insert_own" on public.wallets;
create policy "wallets_insert_own"
on public.wallets for insert
with check (auth.uid() = "userId");

drop policy if exists "wallets_update_own" on public.wallets;
create policy "wallets_update_own"
on public.wallets for update
using (auth.uid() = "userId")
with check (auth.uid() = "userId");
```

## Supabase Dashboard Settings

1. `Authentication -> Providers -> Email`
   - This app now uses **email OTP code verification** during signup.
   - Keep email provider enabled.
   - In Auth email templates, ensure OTP token is available in the template (not only confirmation URL link) if you want 6-digit code UX.

2. `Authentication -> Providers -> Phone`
   - Optional for this flow. You can keep it disabled if not needed.

3. `Authentication -> URL Configuration`
   - Add your app URL(s) to **Site URL** and **Redirect URLs** for email links.

4. `Authentication -> Rate Limits`
   - If you hit `429` (`over_email_send_rate_limit`), pause retries for a few minutes.
   - Aggressive test loops can temporarily block sends.

5. `Database -> Extensions`
   - Ensure `pgcrypto` is enabled (usually already enabled in Supabase projects).

## OTP 500 Troubleshooting

If `POST /auth/v1/otp` returns `500`, the issue is usually in email provider/SMTP setup, not Flutter code:

1. Open `Supabase Dashboard -> Authentication -> Logs` and inspect the exact OTP error row.
2. Verify `Authentication -> Providers -> Email` is enabled and SMTP/provider settings are valid.
3. If using custom SMTP, confirm sender email/domain is valid and allowed by the provider.
4. Check Auth email templates for valid placeholders and no broken HTML/template variables.
5. Retry after 1-2 minutes to avoid mixing `500` provider errors with temporary `429` limits.

If `POST /auth/v1/signup` or `POST /auth/v1/otp` fails with message like `Database error saving new user`:

1. Inspect `Authentication -> Logs` details for the failing request.
2. Check your `on_auth_user_created` trigger/function on `auth.users`.
3. Remove orphan app rows that no longer have matching `auth.users` records:

```sql
delete from public.wallets w
where not exists (
  select 1 from auth.users a where a.id = w."userId"
);

delete from public.users u
where not exists (
  select 1 from auth.users a where a.id = u.id
);
```
