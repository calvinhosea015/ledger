# Ledger — domain glossary

- **Purchase** — one bought item record (Supabase `items` row), with lifecycle dates and a currency snapshot.
- **Category** — user-owned label grouping Purchases.
- **Profile** — per-user settings; owns preferred `currencyCode` (ISO 4217).
- **Envelope** — monthly budget bucket (`income` / `fixed` / `variable` / `savings`) with budgeted amount.
- **EnvelopeLedger** — resolves a month view: computed expense actuals from Purchases, income/savings actuals from the envelope, differences and summary totals.
- **PurchaseLifecycle** — rules for active / finishing soon / expiring / finished / overdue.
- **InventoryCatalog** — list, filter, and mutate Purchases and Categories.
- **SpendSummary** — totals of Purchase `price` by Category over a time window.
- **ItemStatus** — derived status of a Purchase for a given “today” and soon-window.
- **CatalogStore** — persistence seam for Categories, Purchases, Profiles, and Envelopes.
- **AuthSession** — authentication seam (sign up / sign in / sign out / current user).
