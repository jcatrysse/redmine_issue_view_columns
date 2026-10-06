# global_defaults

Run 2026-10-06T22:28:30.469Z against http://127.0.0.1:3000.

| screenshot | user | URL | shows |
|---|---|---|---|
| ![](global_defaults-settings.png) | admin | `/settings/plugin/redmine_issue_view_columns` | Plugin settings: columns now link to core's issue tracking settings; limit, grouping and relation types stay here |
| ![](global_defaults-defaults.png) | admin | `/issues/17` | Project without the module: the plugin table with core's columns Status, Priority |
| ![](global_defaults-core-columns.png) | admin | `/settings?tab=issues` | Core setting "Related and sub issues list defaults" with Assignee added (Administration > Settings > Issue tracking) |
| ![](global_defaults-core-columns-applied.png) | admin | `/issues/17` | The project without the module follows core's setting: Assignee column added |
| ![](global_defaults-headers-off.png) | admin | `/issues/17` | Core "Display table headers" off: the plugin table has no header row, like core's |
| ![](global_defaults-global-limit-grouped.png) | admin | `/issues/17` | Global limit 1 and grouping: one row, the "Show all" button, headers per type |
| ![](global_defaults-project-overrides.png) | admin | `/issues/7` | A project with the module keeps its own settings: 4 rows, not grouped |
| ![](global_defaults-manager-refused.png) | manager | `/settings/plugin/redmine_issue_view_columns` | A non-administrator cannot open the plugin settings (403) |
