# Ledger

Personal purchase-lifecycle tracker and monthly budget envelopes for web, iOS, Android, macOS, and Windows.

Track **when you bought something**, **when it should finish**, optional **expiry**, **category spend**, and **income / fixed / variable / savings** envelopes with budgeted vs actual.

## Stack

- Flutter (Riverpod, go_router)
- Supabase Auth + Postgres (or in-memory fake backend for local demo)

## Run without Supabase (local demo)

If `SUPABASE_URL` / `SUPABASE_ANON_KEY` are empty, Ledger shows a setup screen. Choose **Continue with local demo**, or force fake mode:

```bash
flutter pub get
flutter run -d macos --dart-define=USE_FAKE_BACKEND=true
```

Sign up with any email/password (8+ chars). Data resets when the app process ends.

## Run with Supabase

### 1. Project prep

1. Create a project at [supabase.com](https://supabase.com)
2. **Authentication → Providers → Email**: enable Email. For local testing, turn **off** Confirm email
3. Copy **Project URL** and **anon public** key from **Project Settings → API**
4. **Do not** put the `service_role` key in the Flutter client

### 2. Database

In **SQL Editor**, run [`supabase/schema.sql`](supabase/schema.sql). That creates:

| Table | Purpose |
|-------|---------|
| `categories` | User category labels |
| `items` | Purchases / lifecycle records |
| `profiles` | Preferred currency |
| `envelopes` | Monthly budget envelopes |

RLS restricts every row to `auth.uid() = user_id`.

### 3. Launch

```bash
flutter run -d macos \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Optional table overrides: `SUPABASE_CATEGORIES_TABLE`, `SUPABASE_ITEMS_TABLE`, `SUPABASE_PROFILES_TABLE`, `SUPABASE_ENVELOPES_TABLE`.

See [.env.example](.env.example) for the dart-define key names (values are passed at run time, not loaded from that file by Flutter).

## Currency

Default preferred currency is **IDR**. Set it under **Profile**. New purchases and envelopes snapshot that code; changing preference does not convert historical amounts.

## Budget envelopes

- Expense actuals (`fixed` / `variable`) = sum of purchases in the linked category for that month
- Income / savings actuals = entered on the envelope
- Opening a month with no envelopes seeds Salary, Rent, Groceries, and Emergency savings

## Domain concepts

See [CONTEXT.md](CONTEXT.md).

## Tests

```bash
flutter test
```

## App identity

Display name: **Ledger**  
Package: `com.personal.budgeting.ledger`
