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
| GEOxyz runs today | `2.0.0` |
| Upstream | siberianlove/redmine_issue_view_columns (master @ cf74e6c, 2024-11-10; keten kenan3008 -> san199332 -> siberianlove) |
| Runs on Redmine 7 as is | NEE |
| Upstream sync | UPSTREAM DOOD |
| After sync | n.v.t. |
| Complexity (1 trivial .. 5 rewrite) | 2 |
| Measured on | Redmine 7.0.1 (7.0-stable-GEOxyz + latest 7.0-stable), Rails 8.1.3.1, Ruby 3.3.6, PostgreSQL 16 and MariaDB 10.11 |
| Branch head when this file was written | `eebf15f` |

## Already on this branch

- nothing: the branch equals the branch GEOxyz runs today.

## Work list for the migration session

In this order: things that break, security, the GEOxyz changes, the open items, then the checks.

**Priority items**

1. Commit the init.rb fix from the analysis (ContextMenus::IssuesController with fallback); without it Redmine 7 does not boot.
2. label_relation_delete -> label_relation_remove; icons to sprite_icon.
3. Decide what stays now that core 6.1 has configurable related-issue columns (#42477).

**Open items from the analysis** (Dutch; where they conflict with a decision or a priority item above, those win)

4. init.rb:33 ContextMenusController -> ContextMenus::IssuesController met fallback (getest in slot, niet gecommit: commit geweigerd door classifier)
5. label_relation_delete bestaat niet in 7.0 -> label_relation_remove (helper:100,105, _context_menu.html.erb:15)
6. icon-* CSS -> sprite_icon
7. Globale kolom-setting vs core #42477 rationaliseren
8. test_create_requires_manage_relations_permission is fixture-afhankelijk (Non member heeft manage_issue_relations)

**Checks**

9. Run the plugin's whole test suite on Redmine 7.0-stable-GEOxyz with PostgreSQL AND MariaDB, and once on 5.1-stable if the branch is meant to stay 5.1-compatible.
10. Check Redmine 7 webhooks against this plugin (see "Rules"), and note the result here even if nothing is needed.
11. Verify every feature of the plugin by hand on a running Redmine 7 (screenshots).

## GEOxyz changes to review or re-apply

These GEOxyz commits are on the branch GEOxyz runs today and therefore on this branch. Review each one against the code it now sits on (upstream merges and Redmine 7 core): drop it if upstream or core now does the same, rewrite it if it is not up to the quality rules below (tests, I18n, security, portability), keep it otherwise. Record the verdict per commit in this file.

| commit | date | subject |
|---|---|---|
| `605cc58` | 2026-01-30 | 2.0.2: add relation context menu |
| `84f6c58` | 2026-01-08 | 2.0.1: filterable relations |
| `10ea101` | 2025-12-26 | 2.0.0: configurable relations |
| `f921c4d` | 2025-12-16 | Feature: added a configurable limit for related issues with an inline toggle to reveal or hide extra rows |
| `0267fd0` | 2025-11-03 | Patch: code refactoring (autoloading related) |
| `ca689ee` | 2025-06-17 | Defect: issue page does handle adding or destroying related issues correctly #5248 |

## After the upgrade (production)

Actions the person doing the upgrade must take, or know about, for this plugin:

- None known. Add here what the session finds.

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

