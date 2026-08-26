# Bot API 10.3 support

## Scope

- Regenerate the API contract from the current official Telegram Bot API documentation.
- Restore the repository's seven hand-written type methods after generation.
- Bump the gem version from `2.8.1` to `2.9.0`.
- Add a `CHANGELOG.md` entry for Bot API 10.3.

## Design

Use the existing pipeline without changing its parser:

```text
Telegram Bot API HTML
  -> rake parse:types / parse:methods
  -> data/types.json / data/methods.json
  -> rake rebuild:types / rebuild:methods
  -> lib/telegram/bot/types and api/endpoints.rb
```

The generated diff will be reviewed for the Bot API 10.3 additions, and the
custom methods documented in `.claude/skills/update-api/SKILL.md` will be
preserved. No manual API type or endpoint implementation is planned unless
the current documentation parser fails on a 10.3 construct.

## Validation

- Confirm generated data and Ruby sources contain the Bot API 10.3 contract.
- Confirm all documented custom methods remain present.
- Run `bundle exec rubocop`.
- Run `bundle exec rake spec`.
- Review the final diff and version/changelog changes.
