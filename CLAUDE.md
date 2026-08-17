# CLAUDE.md — Office Assistant

## What this is

An internal service for coordinating a hybrid office: desk booking, meeting-room
booking, and visibility into who is in the office on a given day.

This is a hiring take-home. It will be reviewed by a head of development, and the
author must be able to defend **every line** of it in a live conversation. That
constraint outranks elegance, completeness, and cleverness.

## The prime directive

**Do not write code the author cannot explain.**

Concretely, this forbids:
- Metaprogramming, dynamic method definition, `send`, monkey-patching.
- Abstractions introduced before there are two concrete uses.
- Service objects, form objects, query objects, or a `lib/` layer unless a
  controller genuinely cannot stay readable without one.
- Gems beyond what is listed below.
- Clever one-liners where three plain lines are clearer.

When in doubt, choose the more boring implementation.

## Stack — fixed, do not substitute

- Ruby on Rails 8, `inertia_rails`, Vite
- Svelte 5 (runes) + TypeScript
- `carbon-components-svelte` 0.111 (theme g10) + `carbon-icons-svelte`, IBM Plex
  Sans served locally. No Tailwind and no second component library: the project
  ran on shadcn-svelte + Tailwind until `spike/carbon` measured the swap, and
  the state before it is tagged `shadcn-baseline`. Layout is Carbon's grid plus
  plain scoped CSS on `--cds-*` tokens — never a literal colour.
- PostgreSQL in development (Docker Compose) and production (Kamal accessory)
- Solid Queue for background jobs, Solid Cache for cache — **no Redis, no Sidekiq**
- Rails 8 built-in authentication generator — **not Devise**
- Kamal for deployment
- Minitest (Rails default) — not RSpec

Do not add Redis, Zod, Superforms, Formsnap, or any state-management
library. Superforms and Formsnap are SvelteKit-only and will not work here:
validation lives in Rails models and errors arrive in components automatically
through Inertia.

## Scope

Read `SCOPE.md` before every task. It lists what is in and what is deliberately
out. **Never implement anything from the "out" list**, even if it seems trivial
or you notice it while working on something else. If something feels missing,
raise it as a question — do not build it.

## Domain rules that matter

- **Rooms are booked in fixed 30-minute slots.** This is a deliberate product
  decision: it makes the UI a grid and it makes double-booking preventable with
  a plain unique index on `(resource_id, slot_start)`. Do not switch to
  arbitrary start/end times.
- **Desks are booked per day**, not by time.
- **A booking without check-in is auto-released.** A recurring background job
  releases room bookings whose slot started more than 10 minutes ago and that
  were never checked in. This is the core mechanic of the product; keep it
  simple and keep it tested.
- Uniqueness must be enforced **at the database level**, not only in model
  validations. Fixed slots make a plain unique index on `(resource_id, slot_start)`
  a complete guarantee; an exclusion constraint over a time range would only be
  needed if bookings ever became arbitrary intervals. Do not add one.

## Code conventions

- Standard Rails structure. Skinny controllers, logic in models.
- Controllers render Inertia pages with explicit props. No serializer layer.
- Svelte components stay presentational; no client-side data fetching, all data
  arrives as props from the controller.
- TypeScript types for props, defined next to the component that uses them.
- **UI copy is in Russian.** Code, identifiers, comments, and commit messages are
  in English.
- Error messages shown to users must say what to do next, not just what failed.

## Tests

Minimal but real. Do not chase coverage. Write model tests for exactly these:

1. Overlapping room bookings for the same slot are rejected.
2. Auto-release marks an un-checked-in booking as released after the threshold.
3. Auto-release does **not** touch a booking that was checked in.
4. Recurring schedule expands into bookings for the correct weekdays.

Nothing else needs a test unless the author asks.

## Commits

- One commit per vertical slice — migration plus model plus controller plus page.
- **Never a single "initial commit" containing the whole project.** The commit
  history is part of what gets reviewed; it must read as work in progress.
- Message format: `feat: add room slot grid`, `fix: release only unchecked bookings`.
- Do not commit until the author has reviewed the stage.

## DECISIONS.md

Append one short entry for every non-obvious choice, in Russian, in this shape:

```
## Фиксированные 30-минутные слоты для переговорных
Решение: бронирование слотами, не произвольным интервалом.
Почему: сетка в интерфейсе и защита от двойной брони обычным уникальным индексом.
Цена: нельзя забронировать 20 минут или 1 ч 10 мин.
Пересмотр: если пользователи начнут жаловаться на жёсткость сетки.
```

Do not write entries for obvious things. Ten to fifteen entries total is right.

## README.md

Write only the structure and the technical sections (setup, run, deploy, schema
overview). **Leave the "Проблема", "Почему не купили готовое", "Границы MVP" and
"Что дальше" sections as empty headings** — the author writes those himself in
his own words, because he has to defend them out loud.

## Working style

- Before starting a stage, state your plan in three to five lines and wait for
  approval.
- After finishing a stage, stop. Summarise what changed, what you decided and
  why, and what you would question. Do not start the next stage unprompted.
- If a requirement is ambiguous, ask. Do not resolve it by guessing.
- If you think a decision in this file is wrong, say so once, with the argument.
  Then follow it unless the author changes it.