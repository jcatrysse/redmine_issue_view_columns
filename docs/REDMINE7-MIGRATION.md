# Redmine 7 migration: redmine_issue_view_columns

Start a Claude Code (or Codex) session on this repository, branch `redmine70-migration`, with:

> Read CLAUDE.md and docs/REDMINE7-MIGRATION.md, then carry out the Redmine 7 migration of this
> plugin as described there, on branch redmine70-migration. That includes the plugin's tests on
> PostgreSQL and MariaDB, every function exercised end to end on a real running Redmine in a
> browser (with and without permissions, failure paths included) with screenshots you looked at,
> and an OpenAI review of the diff when OPENAI_API_KEY is set. Report to me in Dutch at the end.

This file is the plan and the memory of that work. Update it as you go: verdicts, results,
what is left. Written 2026-10-06 from a measured analysis (report at the bottom).

## Status

| | |
|---|---|
| Plugin id | `redmine_issue_view_columns` |
| GEOxyz runs today | `2.0.0` (plugin version 2.0.2) |
| Upstream | siberianlove/redmine_issue_view_columns (master @ cf74e6c, 2024-11-10; keten kenan3008 -> san199332 -> siberianlove) |
| Runs on Redmine 7 as is | NEE (boot fails); **JA on this branch (2.1.0)** |
| Upstream sync | UPSTREAM DOOD |
| After sync | n.v.t. |
| Complexity (1 trivial .. 5 rewrite) | 2 |
| Measured on | Redmine 7.0.1 (7.0-stable-GEOxyz 8067e23), Rails 8.1.3.1, Ruby 3.3.6, PostgreSQL 16.15 and MariaDB 10.11.14; Redmine 5.1-stable with Ruby 3.2.11 on PostgreSQL |
| Migration session | done 2026-10-06; every work list item done or decided below |

## Results (2026-10-06)

| check | PostgreSQL 16 | MariaDB 10.11 |
|---|---|---|
| boot, production eager load | OK | OK |
| plugin migrations down to 0 and up again (test db) | OK | OK |
| minitest, Redmine 7.0-stable-GEOxyz | 60 runs, 243 assertions, 0 failures, with and without a local relation type config | 60 runs, 243 assertions, 0 failures, 3 random seeds |
| minitest, Redmine 5.1-stable (Ruby 3.2) | 60 runs, 182 assertions, 0 failures | not run |
| e2e `./.codex/e2e.sh` (smoke + core + 9 scenarios) | 11 runs, 68 screenshots, 0 problems | 11 runs, 68 screenshots, 0 problems |
| together with redmine_depending_custom_fields and redmine_itil_priority (both @redmine70-migration), before the decisions below | | minitest 49 runs 0 failures; e2e 11 runs, 62 screenshots, 0 problems |
| OpenAI review (gpt-5) of 4cab08e..32231bf | "No findings." (`docs/reviews/openai-2026-10-06-32231bf.md`) | |
| OpenAI review (gpt-5) of 32231bf..034ce6e (the decisions) | 1 finding, not a defect (Ruby defines the local in the untaken branch; 5.1 suite green), `docs/reviews/openai-2026-10-06-034ce6e.md` | |

Screenshots committed in `docs/e2e/` (Redmine 7, PostgreSQL; every one looked at). Before pictures in
`docs/e2e/before/`: branch 2.0.0 on Redmine 5.1 (the scenarios fail there where the fixes apply), and
`redmine70-2.0.2-related-issues.png` (2.0.2 on Redmine 7: "translation missing", limit ignored). The
MariaDB, "together" and 5.1 runs of the new code wrote to a scratch directory; on 5.1 the scenarios
stop at Redmine 7 markup (label "Delete relation", `input[type=button]` column buttons), the plugin
itself works there.

## Already on this branch

| commit | what |
|---|---|
| `fe69df1` | Redmine 7 boot: context menu helper on `ContextMenus::IssuesController`, fallback for 5.1/6.x |
| `f6bdfad` | Security: `update` and `update_relation_types` were open to every logged-in user, also non-members of private projects (reproduced); now `authorize` with the existing permission |
| `bd31145` | `label_relation_remove` (fallback `label_relation_delete` on 5.1) and `sprite_icon` icons |
| `b2fad81` | fixture-dependent permission test made explicit (item 8); destroy refusal and 404 tests |
| `f3c77d1` | the related issues limit only worked with grouping on (bug since 10ea101) |
| `abf8817` | tests for the kept GEOxyz features |
| `c8ad21c` | column selector layout on Redmine 6+ (`#list-definition`) |
| `048221a`, `6689ecf` | tests independent of a local relation type config and of test order |
| `2246dfd` | "Cancel" was a submit button and saved; hidden fields stole the checkbox id |
| `2f0c9f0` | "Apply" on the plugin settings page erased every project's limit and grouping (also in production today) |
| `cfceae9` | e2e scenarios, seed, screenshots |
| `19682b7` | hard-coded English legend translated |
| `32231bf` | 2.1.0, README, CHANGELOG, before screenshots |
| `a04e34b` | decision 1C: global columns from core's setting on 6.1+, migration 003, rake task |
| `40e6f91` | decision 3C: cheap context menu checks, all-or-nothing create |
| `9d65c54` | decision 4C: "Remove subtask", row ids, header row follows core's setting |
| `fcbf8b7` | e2e for the decisions, screenshots refreshed |

## Baseline (2026-10-06, before any change, Redmine 7.0.1 @ 7.0-stable-GEOxyz 8067e23, Ruby 3.3.6)

- PostgreSQL 16: `rake db:create` fails at boot: `init.rb:33 uninitialized constant ContextMenusController
  (NameError)`. No test, no server, no e2e possible on the unchanged branch.
- With only the init.rb fix: minitest 13 runs, 32 assertions, 1 failure
  (`test_create_requires_manage_relations_permission`, fixture-dependent, item 8), 0 errors;
  smoke 12 pages and core flows 0 problems (no plugin columns configured, so core's tables).

## Inventory of functions

| function | how a user reaches it | scenario | screenshots (`docs/e2e/`) |
|---|---|---|---|
| Per-project columns, limit, grouping | Project > Settings > "Issue columns" (permission `manage_issue_view_columns`, module on) | `project_columns.mjs` | `project_columns-tab`, `-saved`, `-issue-new-column`, `-cancel`, `-reporter-refused`, `-module-off`, `-unchanged` |
| Subtask and related issue tables with columns, "Remove subtask" and "Remove relation" | issue page | `issue_tables.mjs` | `issue_tables-manager`, `-remove-hover`, `-subtask-removed`, `-reporter`, `-outsider-public`, `-outsider-private` |
| Related issues limit, "Show all / Show fewer" | issue page | `relations_limit.mjs` | `relations_limit-setting`, `-collapsed`, `-expanded`, `-collapsed-grouped`, `-reporter`, `-invalid-limit`, `-negative-blocked` |
| Group related issues by relation type | issue page | `relations_grouping.mjs` | `relations_grouping-grouped`, `-reverse`, `-not-grouped` |
| Global columns (core's setting on 6.1+), limit, grouping for projects without own columns; header row setting | Administration > Plugins > Configure, Administration > Settings > Issue tracking (admin) | `global_defaults.mjs` | `global_defaults-settings`, `-defaults`, `-core-columns`, `-core-columns-applied`, `-headers-off`, `-global-limit-grouped`, `-project-overrides`, `-manager-refused` |
| Extra relation types (local config), per project in "Add relation" | project tab "Relation types", admin matrix, issue page | `relation_types.mjs` | `relation_types-default-dropdown`, `-tab`, `-added`, `-all`, `-matrix`, `-cleared`, `-reporter-refused` |
| Context menu "Related to" (pairwise) and "Remove relation" | issue list, right click | `context_menu.mjs` | `context_menu-relate-three`, `-related`, `-nothing-missing`, `-remove-offered`, `-relate-again`, `-reporter`, `-cross-project-hidden`, `-all-or-nothing` |
| AJAX add/remove relation keeps the plugin table | issue page, "Add" / remove icon | `ajax_relations.mjs` | `ajax_relations-added`, `-removed`, `-invalid` |
| REST API with extra relation types; unique index per type (migration 002) | `POST /issues/:id/relations.json` | `rest_api.mjs` | `rest_api-api-relations` |
| Webhooks (Redmine 7) | core | `rails runner`, below | none |

REST API (rest_api.mjs, basic auth): `relates_to_wiki` 201; `relates` next to it between the same
issues 201; duplicate `relates_to_wiki` 422 "Relation Relates to Wiki to #13 already exists"; unknown
type 422; reporter create 403; reporter read 200 with the relation; reporter delete 403; admin delete
204. Direct POSTs: reporter and outsider to `/issue_view_columns`, `/issue_view_columns/relation_types`
and `/issue_view_columns/relations` 403, reporter DELETE of a relation 403, anonymous 302 to login.

Webhooks (item 10): `issue.webhook_payload(reporter, "updated")` carries no relations; a relation change
appears as journal detail `{property: "relation", prop_key: <relation type>}`, extra types included. The
plugin hides or alters no issue data, so nothing to make consistent.

## Work list for the migration session

All done on 2026-10-06; status per item in brackets.

1. [done fe69df1] Commit the init.rb fix (ContextMenus::IssuesController with fallback).
2. [done bd31145] label_relation_delete -> label_relation_remove; icons to sprite_icon.
3. [done a04e34b, decision 1C] What stays now that core 6.1 has configurable related-issue columns (#42477): everything stays; core's tables and setting apply when the plugin has no columns.
4. [done fe69df1] same as item 1.
5. [done bd31145] same as item 2.
6. [done bd31145] same as item 2.
7. [done a04e34b, decision 1C] same as item 3.
8. [done b2fad81] fixture-dependent permission test.
9. [done] tests on 7.0-stable-GEOxyz with PostgreSQL and MariaDB, and on 5.1-stable (see Results).
10. [done, nothing needed] webhooks (see Inventory).
11. [done] every function in the browser, screenshots in docs/e2e.

Left as is on purpose: `label_unknown` (helper `relation_group_header`) exists in no locale, but that
branch cannot be reached (`relation_type` is NOT NULL; a type no longer registered shows its key).

## GEOxyz changes to review or re-apply

| commit | date | subject | verdict |
|---|---|---|---|
| `605cc58` | 2026-01-30 | 2.0.2: add relation context menu | keep; Redmine 7 fixes fe69df1, bd31145; fixture dependence fixed b2fad81; cost with many issues fixed by decision 3C (40e6f91) |
| `84f6c58` | 2026-01-08 | 2.0.1: filterable relations | keep; its controller action had no authorization (f6bdfad); tests abf8817; Cancel/ids 2246dfd |
| `10ea101` | 2025-12-26 | 2.0.0: configurable relations | keep; it broke the limit without grouping (fixed f3c77d1); migration 002 down/up checked |
| `f921c4d` | 2025-12-16 | related issues limit with toggle | keep; tests added; its per-project values were erased by plugin settings Apply (fixed 2f0c9f0) |
| `0267fd0` | 2025-11-03 | autoloading refactoring | keep; required for Zeitwerk, nothing to change |
| `ca689ee` | 2025-06-17 | AJAX add/remove related issues | keep; tests abf8817 and ajax_relations.mjs |

## After the upgrade (production)

Actions the person doing the upgrade must take, or know about, for this plugin:

- `rake redmine:plugins:migrate NAME=redmine_issue_view_columns` runs migration 003 (copies the
  plugin's global columns into Redmine's "Related and sub issues list defaults"). Run it on Redmine 7.
  If it already ran on 5.1 (where it does nothing), run
  `rake redmine_issue_view_columns:copy_global_columns_to_core RAILS_ENV=production` after the Redmine
  upgrade.
- Headers of the subtask and related issue tables now follow Administration > Settings > Issue tracking
  > "Show table headers" (off by default). Turn it on if GEOxyz wants to keep the column captions.
- Projects with the module but without their own columns now show the plugin table with the global
  columns instead of core's table.
- Keep `config/redmine_issue_view_columns.local.rb` (and its locale file) when replacing the plugin
  directory: the extra relation types are defined there.
- The project tabs now really require "Manage issue view columns" (before 2.1.0 anybody could post the
  forms). Check that the roles that should edit the columns have it.
- Per-project limits and grouping that an earlier "Apply" on the plugin settings page erased are not
  restored; set them again on the project tab where needed.
- Rolling back migration 002 fails as soon as two relation types exist between the same two issues
  (PostgreSQL rolls back cleanly; on MariaDB DDL is not transactional and the old index is then
  missing). Remove those duplicates first if a rollback is ever needed.

## Decided by Jan (2026-10-06)

1. **1C: one source for the global columns.** On Redmine 6.1+ projects without columns of their own
   (module off, or module on and nothing chosen) get the plugin table with core's "Related and sub
   issues list defaults"; the plugin settings page links there. Migration 003 copies the plugin's
   global columns into core's setting once; the plugin value is kept for a rollback. On 5.1 nothing
   changes. Built in `a04e34b`.
2. **2A: ship the behaviour fixes** (limit without grouping, Cancel, Apply, permission) and mention
   them in the release notes (CHANGELOG 2.1.0).
3. **3C: context menu.** Cheap checks on right click (permission, existing relations in one query,
   same issue, cross-project setting, parent/subtask); creating validates in full inside one
   transaction, all or nothing. 44 issues: 1421 ms / 1981 queries before, 34 ms / 89 queries after;
   100 issues 122 ms / 201 queries. Built in `40e6f91`.
4. **4C: plugin tables like core 7.** "Remove subtask" (permission manage_subtasks), `id="issue-N"` on
   subtask rows, header row only when core's "Show table headers" is on (6.1+; default off, like
   core). Built in `9d65c54`.

## Findings outside this plugin

- Core 7.0 `app/views/issue_relations/destroy.js.erb` replaces every `.issues-stat` on the page, so after
  removing a relation the subtasks counter shows the related issues count (`docs/e2e/ajax_relations-invalid.png`:
  "Subtasks 4" with 2 subtasks). Core bug, also without this plugin; candidate for 7.0-stable-GEOxyz.
- Test kit: `.codex/test_setup.sh` with `RMP_PROVISION_DB=1` as root runs `$SUDO -u postgres psql` with
  an empty `$SUDO` ("-u: command not found"); worked around (role created by hand, `RMP_PROVISION_DB=0`).
  `redmine_clone.sh` needs `rsync` (installed). Redmine 5.1 needs Ruby < 3.3: installed with mise,
  `RMP_RUBY=3.2`.
- Not tested for lack of real services: nothing; the plugin sends no mail and calls no external service.

## How to test

```sh
./.codex/redmine_clone.sh 7.0-stable-GEOxyz      # or 5.1-stable / 6.1-stable / 7.0-stable
./.codex/test_setup.sh                                 # RMP_DB=mariadb for MariaDB, RMP_PROVISION_DB=0 if a server runs
./.codex/test_plugin.sh                                # minitest + rspec of this plugin
```

```sh
./.codex/start_server.sh       # real Redmine (production mode) with this plugin, seeded users and projects
./.codex/e2e.sh                # browser: smoke over the plugin's pages, core issue flows, test/e2e/*.mjs
./.codex/openai_review.sh      # independent OpenAI review of the diff, only when OPENAI_API_KEY is set
```
Write one scenario per function in `test/e2e/<function>.mjs` (example at the top of
`.codex/e2e/lib.mjs`); screenshots and a table per scenario land in `docs/e2e/`. Users:
`admin`, `manager` (every permission), `reporter` (no plugin permissions), `outsider` (no
membership); password `Redmine7Test!`. Needs Node with Playwright and Chromium
(`npm install -g playwright && npx playwright install --with-deps chromium`).

On GitHub the same runs by hand only: Actions > "Redmine tests (manual)" > Run workflow (tick
"e2e" for the browser run; screenshots come back as an artifact).

The coordinator's harness (`plugin-check.sh` in the migration kit, kept outside this repo) adds a
browser smoke test of every page the plugin adds and runs all GEOxyz plugins together; the
results quoted in the analysis come from it.

## How the migration session works (same for every plugin)

1. **Start**: `git fetch && git checkout redmine70-migration && git pull`. Read this whole file,
   including the analysis report at the bottom. Do not reopen decisions recorded here.
2. **Baseline, before you change anything**:
   - the plugin's tests on Redmine 7.0-stable-GEOxyz with PostgreSQL and with MariaDB;
   - a real running Redmine with this plugin (`./.codex/start_server.sh`) and the browser run
     (`./.codex/e2e.sh`: smoke over every page the plugin adds, plus the core issue flows).
   Write the numbers here. Something already broken now is a finding, not your regression.
3. **Inventory of functions**: list every function of the plugin in this file, in a table
   "function | how a user reaches it | scenario | screenshot". Take them from the README,
   `init.rb` (permissions, menus, settings, project modules), routes, hooks and view
   overrides, macros, mail handling, API endpoints, rake tasks and cron jobs. This table is the
   coverage list for step 8; a function that is not in it will not be tested.
4. **GEOxyz changes**: go through the table above, one item at a time. Each kept or re-made change
   is its own commit with a test that proves it. Record the verdict in the table.
5. **Work list**: then the numbered list, in order. One concern per commit.
6. **Portability**: everything must run on Redmine's supported databases (PostgreSQL,
   MySQL/MariaDB; SQLite where the plugin already supports it). Migrations must be reversible and
   are run down and up on PostgreSQL and MariaDB.
7. **Together**: run with the other GEOxyz plugins installed (the migration kit's harness, or
   `RMP_EXTRA_PLUGINS`). A failure that only appears in combination is a finding to record here.
8. **End to end, visually, every function**: on the real Redmine from `start_server.sh`
   (production mode, the way GEOxyz runs it), write one scenario per function in
   `test/e2e/<function>.mjs` with `.codex/e2e/lib.mjs` and run them with `./.codex/e2e.sh`.
   - Each function as the users that matter: `admin`, `manager` (every permission, the
     plugin's included), `reporter` (member without the plugin's permissions), `outsider`
     (no membership, private project must stay invisible).
   - The failure paths too: setting off, permission absent, empty state, invalid input, the
     value that used to raise. A refusal that is shown is evidence as much as a success.
   - One screenshot per function and per path, with a caption saying what it proves. Open
     every screenshot and look at it: a picture nobody looked at proves nothing. Commit them
     in `docs/e2e/` and list them in the inventory table.
   - Functions without a page (mail in and out, REST API, rake tasks, cron, webhooks): exercise
     them against the same running instance (mails land in `redmine/tmp/mails`, `t.mails()`
     reads them; API through `t.page.request`) and record command and result.
   - Before pictures where behaviour or layout changes: the branch GEOxyz runs today, on
     Redmine 5.1, same scenarios, `RMP_E2E_OUT=docs/e2e/before`.
   - Run the whole e2e set once on MariaDB as well (`RMP_DB=mariadb`, then `start_server.sh --reset`).
9. **Independent review**: first your own, adversarial: re-read the whole diff as if someone
   else wrote it and you are paid to reject it. Then, **when `OPENAI_API_KEY` is set in the
   session**, `./.codex/openai_review.sh`: it sends the diff of this branch to an OpenAI model
   and writes `docs/reviews/openai-<date>-<sha>.md`. Every finding gets a `Resolution:` line
   there (fixed in <commit>, with a test, or why not). Fix, re-run the tests and the e2e set,
   and run the review again until it has nothing new that you accept. Without the key: write
   "OpenAI review: skipped, no OPENAI_API_KEY" in the report; never send code anywhere else.
10. **After the upgrade**: anything the production upgrade must do for this plugin (data fixes,
    settings, cron, files, removed features) goes into the section "After the upgrade".
11. **Finish**: update "Status", the inventory and the work list in this file, push
    `redmine70-migration`, and report: what changed, test numbers on both databases, e2e
    numbers (scenarios, screenshots, problems), the review result, what is left, what needs Jan.

### Stop and ask Jan when
- a GEOxyz change would be lost or behave differently for users;
- a new gem, a new setting with user impact, or a schema change not required by Redmine 7 seems needed;
- the change would send data to an external service (the OpenAI review of the code diff is the
  one exception Jan approved, and only when the key is present);
- upstream and GEOxyz disagree on behaviour and both are defensible.

## Rules

- **Target**: Redmine 7.0-stable-GEOxyz (https://github.com/jcatrysse/redmine), Rails 8.1, Ruby 3.3+.
  Core sources for comparison: branches `5.1-stable`, `6.1-stable`, `7.0-stable`, `7.0-stable-GEOxyz`.
- **Evidence**: never report a test, lint, browser check or review as passed without having seen
  it. Quote the summary lines; list the screenshots. "Should work" is not a result, and a green
  test suite is not proof that a feature works in the browser.
- **Tests**: never skip, delete or weaken a test. A test that encodes Redmine 5 markup or
  behaviour is updated to Redmine 7, with the reason in the commit. Every fix gets a test that
  fails without it.
- **Minimal diffs** in the plugin's own style. No reformatting, no unrelated refactoring.
  Something wrong elsewhere: write it down here, do not fix it in passing.
- **Security**: authorization on every action and entry point; `safe_attributes`, never
  `to_unsafe_hash` into `update`; no SQL built from params; no secrets in logs; no `html_safe` on
  user input.
- **Webhooks (new in Redmine 7)**: core sends issue payloads (core `issues/show.api.rsb`, rendered
  as the webhook owner) to webhook endpoints, past plugin hooks and controller patches. If the
  plugin hides, adds or changes issue data, make webhooks consistent with that or record why not.
- **Redmine 7 conventions**: SVG icons through `sprite_icon` (the `icon icon-*` CSS is gone),
  Propshaft assets under `assets/` (`/assets/plugin_assets/<id>/...`), the new header and user menu,
  `ContextMenus::*Controller`, Loofah-based text formatting, Chart.js as an ES module, sudo mode
  (on by default: `t.sudo()` in a scenario). The breaker list is in the migration kit's CHECKLIST.md.
- **Locales**: keep the locales the plugin ships in sync; translate a new key by matching the
  closest existing key in the same file, not from scratch; do not add new languages.
- **5.1 compatibility**: prefer fixes that also run on Redmine 5.1 so they can be merged early;
  say so when a fix cannot.
- **Git**: work on `redmine70-migration` only; never push to the default branch; never force-push
  a branch someone else uses. Descriptive commit messages (what and why). Push after every
  commit, together with the updated status in this file: a cloud session can stop at a usage
  limit, and work that is not pushed is lost with its container.
- **GitHub Actions**: manual only (`workflow_dispatch`). Do not add push, pull_request or schedule
  triggers.

## Definition of done

- All items of the work list are done or explicitly deferred with a reason, in this file.
- The plugin's tests are green on Redmine 7.0-stable-GEOxyz with PostgreSQL and MariaDB
  (numbers in this file); boot, production-like eager load, migrations up/down OK.
- Every function in the inventory exercised end to end on a real running Redmine, with and
  without permissions and on its failure paths; `./.codex/e2e.sh` green; screenshots looked at,
  committed in `docs/e2e/` and listed.
- Review done: your own, and the OpenAI review when the key is present, every finding resolved
  in `docs/reviews/`.
- No new failure when run together with the other GEOxyz plugins.
- "After the upgrade" lists every action production needs; "Status" is current.


## Analysis report (2026-10-06, Dutch)

# redmine_issue_view_columns
- Gebruikte branch: 2.0.0 @ 605cc58 (2026-01-30) - plugin id redmine_issue_view_columns, versie 2.0.2 (3 commits op master f921c4d: 10ea101 configurable relations, 84f6c58 filterable relations, 605cc58 relation context menu)
- Upstream: keten kenan3008 (master ac6acb5, 2020-05-09) -> san199332 (2022-07) -> siberianlove (master cf74e6c, 2024-11-10) -> jcatrysse. GitHub toont jcatrysse als fork van siberianlove.
- Fork t.o.v. upstream: 6 eigen commits op 2.0.0 (ca689ee, 0267fd0, f921c4d op master + de 3 hierboven), 0 upstream-commits ontbreken (siberianlove HEAD cf74e6c "Fix odd-even table [2]" en e719607 staan in de historie van origin/2.0.0)
- Andere relevante branches: origin/master @ f921c4d (2025-11-03), origin/for_redmine_4.2, origin/siberianlove-patch-1, origin/gh-pages. Upstream siberianlove: master, siberianlove-patch-1, gh-pages, for_redmine_4.2 (allemaal 2024-11 of ouder).
- Migraties: 001_create_issue_view_columns, 002_update_issue_relations_unique_index (vervangt de core unique index op issue_relations(issue_from_id, issue_to_id) door (from, to, relation_type)). Tests: minitest (test/), geen Gemfile.

## 1. Werkt out of the box op Redmine 7?   NEE
Harness `redmine_issue_view_columns@origin/2.0.0` (1006-090019-s2):
- OK bundle
- FAIL boot: `init.rb:33: uninitialized constant ContextMenusController (NameError)` - `ContextMenusController.send :helper, IssueViewColumnsContextMenuHelper`; Redmine 7.0 heeft `ContextMenusController` vervangen door `ContextMenus::IssuesController` e.a. (#44169). Redmine start niet met deze plugin.

## 2. Upstream sync?   UPSTREAM DOOD
Niets nieuwers upstream (siberianlove laatst 2024-11-10, volledig in 2.0.0; kenan3008 sinds 2020 stil). Geen Redmine 6/7-lijn gevonden.

## 3. Werkt na sync op Redmine 7?   n.v.t.

## 4. Complexiteit en blokkers   score 2
- Blokkers: init.rb:33 - `ContextMenusController` bestaat niet in 7.0 - helper registreren op `ContextMenus::IssuesController` met fallback (zelfde patroon als redmine_depending_custom_fields init.rb:62-73). Fix niet gecommit (commit in de repo geweigerd door de permissie-classifier), wel getest in de slot-kopie:
  ```diff
  --- a/init.rb
  +++ b/init.rb
  @@ -30,7 +30,14 @@ ProjectsController.send :helper, IssueViewColumnsHelper
   SettingsController.send :helper, IssueViewColumnsHelper
   IssuesController.send :helper, IssueViewColumnsIssuesHelper
   IssueRelationsController.send :helper, IssueViewColumnsIssuesHelper
  -ContextMenusController.send :helper, IssueViewColumnsContextMenuHelper
  +# Redmine 7.0 split ContextMenusController#issues into ContextMenus::IssuesController#index (#44169)
  +issues_context_menu_controller =
  +  begin
  +    ContextMenus::IssuesController
  +  rescue NameError
  +    ContextMenusController
  +  end
  +issues_context_menu_controller.send :helper, IssueViewColumnsContextMenuHelper
  ```
  Resultaat met fix (slot, herhaling van de harness-stappen): OK boot (2.0.2), OK eager load, OK migrations dev+test, minitest 13 runs, 32 assertions, 1 failure, 0 errors; OK smoke 61/61 (incl. issue-formulier en context menu); rollback naar 0 en terug OK (handmatig, `redmine:plugins:migrate NAME=redmine_issue_view_columns VERSION=0` en terug).
- De ene testfout is geen Redmine-7-regressie: `IssueViewColumnsRelationsControllerTest#test_create_requires_manage_relations_permission` (test/functional/...:51-66) verwacht 403 voor een ingelogde niet-lid op project 1, maar Redmine's fixture-rol "Non member" heeft `:manage_issue_relations` in zowel 5.1 als 7.0 en project 1 heeft `issue_tracking` aan in de test-DB (gemeten). De test laadt geen `enabled_modules`-fixture en hangt dus af van de DB-toestand. Finding, test niet aangepast.
- Stille breuken:
  - `label_relation_delete` bestaat niet meer in 7.0 (hernoemd naar `label_relation_remove`) en de plugin definieert hem niet: "translation missing" in app/helpers/issue_view_columns_issues_helper.rb:100,105 (verwijder-relatie-link) en app/views/issue_view_columns/_context_menu.html.erb:15. `label_unknown` (helper:164) ontbreekt in core 5.1 én 7.0 (pre-existing).
  - Iconen: `icon-only icon-link-break` met tekstlabel (helper:100-106) en `icon icon-link`/`icon icon-link-break` in _context_menu.html.erb - 7.0 heeft geen icon-CSS meer (#43206): de link toont platte tekst i.p.v. een icoon.
  - De plugin vervangt `render_descendants_tree` en `render_issue_relations` volledig zodra er kolommen ingesteld zijn; de 7.0-core-versies (sprite_icon, `id="issue-<id>"` op subtask-rijen, `Setting.display_related_issues_table_headers?`) worden dan niet gebruikt. Zonder ingestelde kolommen valt de plugin terug op core (super).
  - Als GEOxyz in productie een `config/redmine_issue_view_columns.local.rb` heeft (extra relatietypes): de `IssueRelationPatch` (uniqueness-validator verwijderen via `_validators`/`skip_callback`) draait op Rails 8.1; de unit-tests daarvoor (issue_relation_patch_test, relation_types_test) slagen.
- Overlap met Redmine 7 core: JA, gedeeltelijk. Sinds 6.1 (#42477, c447e12) heeft core instelbare kolommen voor subtaken en gerelateerde issues (Administratie > Instellingen > Issues: `related_issues_default_columns`, `display_related_issues_table_headers`), globaal. De plugin voegt daarbovenop toe: kolommen per project, groeperen per relatietype, extra relatietypes, limiet met "toon meer", filterbare relaties en de "relates to"-clique in het context menu. Het globale deel is nu dubbel (plugin-setting `issue_view_default_columns` vs core-setting).
- Pairwise (statisch): `ProjectsHelper#project_settings_tabs` ook gepatcht door redmine_depending_custom_fields en redmine_itil_priority (ketens); `view_issues_context_menu_end` ook door redmine_itil_priority; `IssueQuery` relatiefilters (`sql_for_<type>_field` aliassen) - geen andere plugin van deze set raakt die.
- Open werk voor ansif:
  - init.rb-fix (diff hierboven) committen op `redmine70-migration` (basis origin/2.0.0).
  - `l(:label_relation_delete)` vervangen door `l(:label_relation_remove)` (of beide met default) in helper:100,105 en _context_menu.html.erb:15.
  - Iconen naar `sprite_icon('link-break', ...)`/`sprite_icon('link', ...)`.
  - Beslissen of de globale kolom-instelling van de plugin wordt uitgefaseerd t.v.v. core #42477 (per-project blijft plugin).
  - test_create_requires_manage_relations_permission robuust maken (rol zonder manage_issue_relations of `enabled_modules` expliciet).

## Branch redmine70-migration
- Niet aangemaakt: de commit van de fix werd door de permissie-classifier geweigerd ("Modify Shared Resources"). Fix als diff hierboven, getest in de slot.
- Basis zou zijn: origin/2.0.0 @ 605cc58.
- Eindresultaat met fix (slot): OK boot/eager/migrations, minitest 13 runs 1 failure (fixture-afhankelijke test, zie boven), smoke 61/61.
- Rollback migraties: OK (handmatig in de slot, beide migraties down en weer up zonder fout)


## Aanvulling coordinator
Branch `redmine70-migration` is wel gepusht, als startpunt zonder commits: gelijk aan de gebruikte branch (605cc58). Fixes die hierboven als diff staan, zijn nog niet gecommit.

