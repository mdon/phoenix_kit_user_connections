# PR #1 Review — Initial Extraction of User Connections

**PR:** BeamLabEU/phoenix_kit_user_connections#1
**Author:** alexdont (Sasha Don)
**Title:** Initial commit to move the connections outside the kit
**Merged:** 2026-03-29
**Reviewer:** Claude

## Summary

Extracts the user connections system from PhoenixKit core into a standalone module package. Adds follows, mutual connections, blocking, history logging, admin dashboard, and user-facing LiveView.

## Verdict: Approve with follow-up items

The extraction is solid and follows PhoenixKit module conventions well. The code is clean, well-structured, and the business logic is sound. All issues identified below have been fixed.

---

## What's Good

1. **Clean module structure** — Schemas, web layer, and business logic are well-separated
2. **Comprehensive business rules** — Self-action prevention, block checks before follow/connect, auto-accept for mutual pending requests
3. **History logging** — Every action gets an audit trail, logged inside transactions
4. **Proper use of PhoenixKit.Module behaviour** — All callbacks implemented correctly
5. **Good test coverage of module behaviour** — Tests verify auto-discovery, permissions, admin tabs, version
6. **Connection history UUID normalization** — `normalize_user_uuids/1` ensures consistent ordering for querying
7. **Admin authorization** — Proper scope/permission checks in the admin LiveView

---

## Issues Found and Fixed

### P1 — Must Fix

#### 1. Missing unique constraint on connections table — FIXED
`Follow` and `Block` schemas define unique constraints, but `Connection` had none on `{requester_uuid, recipient_uuid}`. Race conditions could create duplicate pending requests.

**Fix:** Added `unique_constraint([:requester_uuid, :recipient_uuid])` to Connection changeset.

#### 2. ~~No migration file included~~ NOT AN ISSUE
Migrations for all module tables live in `phoenix_kit` core (v72, v74, v75). This is the standard pattern for all PhoenixKit external modules — no module ships its own migrations.

#### 3. `blocked_count` loaded all records into memory — FIXED
`web/user_connections.ex` used `length(list_blocked(...))` instead of a count query.

**Fix:** Added `blocked_count/1` function using `repo().aggregate(:count)` and updated `load_counts/1` to use it.

### P2 — Should Fix

#### 4. Manual `inserted_at` on Follow/Block/history schemas — ACCEPTED
The `Follow`, `Block`, and history schemas use manual `field(:inserted_at)` instead of `timestamps()`. This is an intentional choice: these records are immutable once created (no updates), so `updated_at` is unnecessary. The `Connection` schema uses `timestamps()` because connections transition through statuses.

#### 5. `get_relationship/2` made 6 separate DB queries — FIXED
Each field in the relationship map was a separate query (following?, followed_by?, connected?, pending?, blocked?, blocked_by?).

**Fix:** Refactored to 3 batch queries: one for follows between the users, one for connections, one for blocks. Results are filtered in memory.

#### 6. User connections template hardcoded admin back-link — FIXED
The user-facing page linked back to `/admin/connections`.

**Fix:** Changed to `/dashboard`.

#### 7. No `cancel_request` function — FIXED
Outgoing requests showed a "Pending" badge but users couldn't cancel their own sent requests.

**Fix:** Added `cancel_request/2` to the main module (validates the requester owns the request), added `cancel_request` event handler to the LiveView, and replaced the static "Pending" badge with a "Cancel" button in the template.

### P3 — Nice to Have

#### 8. Bare rescue in count functions — FIXED
`rescue _ -> 0` swallowed all errors including programming errors.

**Fix:** Changed to rescue only `Ecto.QueryError` and `DBConnection.ConnectionError`.

#### 9. No pagination in list views — FIXED
All list queries loaded unlimited results.

**Fix:** Added `@page_size 25` to the LiveView and pass `limit: @page_size` to all list functions in `load_tab_data/2`.

#### 10. `handle_event("remove_follower", ...)` was a no-op — FIXED
The handler just showed a flash message with no action.

**Fix:** Removed the dead handler entirely. The template doesn't render a button for it.

---

## Missing Project Files (addressed separately)

The following standard files were missing and have been created:
- `LICENSE` (MIT, BEAM Lab 2026)
- `CHANGELOG.md` (with 0.1.0 entry)
- `AGENTS.md` / `CLAUDE.md` (symlink)
- `README.md` (rewritten with features, installation, usage)
- `dev_docs/pull_requests/` directory

---

## Files Reviewed

| File | Lines | Status |
|------|-------|--------|
| `mix.exs` | 73 | OK |
| `lib/phoenix_kit_user_connections.ex` | 788 | Fixed: #1, #3, #5, #7, #8 |
| `lib/.../schemas/connection.ex` | 118 | Fixed: #1 |
| `lib/.../schemas/follow.ex` | 69 | Accepted: #4 |
| `lib/.../schemas/block.ex` | 72 | Accepted: #4 |
| `lib/.../schemas/connection_history.ex` | 61 | OK |
| `lib/.../schemas/follow_history.ex` | 45 | OK |
| `lib/.../schemas/block_history.ex` | 46 | OK |
| `lib/.../web/connections.ex` | 98 | OK |
| `lib/.../web/connections.html.heex` | 109 | OK |
| `lib/.../web/user_connections.ex` | 205 | Fixed: #3, #7, #9, #10 |
| `lib/.../web/user_connections.html.heex` | 330 | Fixed: #6, #7 |
| `test/phoenix_kit_user_connections_test.exs` | 100 | OK |
| `config/config.exs` | 5 | OK |
| `config/test.exs` | 3 | OK |
| `.formatter.exs` | 4 | OK |
| `.gitignore` | 10 | OK |
