# project_columns

Run 2026-10-06T19:47:46.228Z against http://127.0.0.1:3000.

| screenshot | user | URL | shows |
|---|---|---|---|
| ![](project_columns-tab.png) | manager | `/projects/e2e-project/settings/issue_view_columns` | Project tab "Issue columns" as manager: selector side by side, limit, grouping, Save and a Cancel link |
| ![](project_columns-saved.png) | manager | `/projects/e2e-project/settings/issue_view_columns` | After Save: notice, and Due date is a selected column |
| ![](project_columns-issue-new-column.png) | manager | `/issues/7` | The issue shows the new Due date column in subtasks and related issues |
| ![](project_columns-cancel.png) | manager | `/projects/e2e-project/settings/issue_view_columns` | Cancel leaves the tab without saving: the limit is still empty |
| ![](project_columns-reporter-refused.png) | reporter | `/projects/e2e-project/settings` | Reporter (no plugin permission, no settings permission): project settings refused |
| ![](project_columns-module-off.png) | admin | `/projects/e2e-nomodule/settings` | Module disabled (e2e-nomodule, admin): no "Issue columns" tab |
| ![](project_columns-unchanged.png) | manager | `/projects/e2e-project/settings/issue_view_columns` | After the refused posts the project keeps its 3 columns and no limit |
