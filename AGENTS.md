# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Project Overview

PhoenixKit User Connections module — provides social relationship management with one-way follows, two-way mutual connections, and user blocking. Implements the `PhoenixKit.Module` behaviour for auto-discovery by a parent Phoenix application.

## Common Commands

```bash
mix deps.get          # Install dependencies
mix test              # Run all tests
mix test test/phoenix_kit_user_connections_test.exs  # Run specific test file
mix format            # Format code
mix credo --strict    # Static analysis (strict mode)
mix dialyzer          # Type checking
mix precommit         # compile + format + credo --strict + dialyzer
mix quality           # format + credo --strict + dialyzer
mix quality.ci        # format --check-formatted + credo --strict + dialyzer
```

## Architecture

This is a **library** (not a standalone Phoenix app) that provides user connections as a PhoenixKit plugin module.

### File Layout

```
lib/
  phoenix_kit_user_connections.ex          # Main module — public API, business logic
  phoenix_kit_user_connections/
    schemas/
      follow.ex                            # One-way follow schema
      follow_history.ex                    # Follow audit log schema
      connection.ex                        # Two-way connection schema
      connection_history.ex                # Connection audit log schema
      block.ex                             # Block schema
      block_history.ex                     # Block audit log schema
    web/
      connections.ex                       # Admin LiveView
      connections.html.heex                # Admin template
      user_connections.ex                  # User-facing LiveView
      user_connections.html.heex           # User-facing template
config/
  config.exs                               # Main config (imports test.exs)
  test.exs                                 # Test environment config
test/
  phoenix_kit_user_connections_test.exs    # Module behaviour tests
  test_helper.exs                          # ExUnit setup
```

### Key Concepts

- **Follows** — One-way relationships. User A follows User B without consent.
- **Connections** — Two-way mutual relationships requiring acceptance from both parties.
- **Blocks** — Prevents all interaction; blocking removes existing follows and connections.
- **History tables** — Every action (follow, unfollow, request, accept, reject, block, unblock) is logged for audit.

### Database Tables

- `phoenix_kit_user_follows` — Active follow relationships
- `phoenix_kit_user_connections` — Connection requests and accepted connections
- `phoenix_kit_user_blocks` — Active blocks
- `phoenix_kit_user_follows_history` — Follow action audit log
- `phoenix_kit_user_connections_history` — Connection action audit log
- `phoenix_kit_user_blocks_history` — Block action audit log

All schemas use UUIDv7 primary keys and reference `PhoenixKit.Users.Auth.User`.

**Migrations live in `phoenix_kit` core** (v72, v74, v75), not in this module. This follows the same pattern as all other PhoenixKit external modules.

### Dependencies

- `phoenix_kit` (path dependency for local dev)
- `phoenix_live_view` — LiveView components
- `ex_doc` — Documentation generation (dev only)
- `credo` — Static analysis (dev/test only)
- `dialyxir` — Type checking (dev/test only)

## Testing

Tests currently cover PhoenixKit.Module behaviour callbacks (module_key, module_name, enabled?, permissions, admin_tabs, version, css_sources). Integration tests requiring a database are not yet implemented.

## Versioning

Tags use **bare version numbers** (no `v` prefix). See the top-level `/www/pk/AGENTS.md` for the full release checklist.
