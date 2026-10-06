# Changelog

# 2.1.0 - 2026-10-06 - Jan Catrysse
- Redmine 7.0 support: context menu helper on ContextMenus::IssuesController, "Remove relation" label and SVG icons, column selector layout of Redmine 6+.
- Security: the project settings actions (columns, limit, grouping, relation types) now require the "Manage issue view columns" permission.
- Fixed: the related issues limit did nothing when relations were not grouped.
- Fixed: "Apply" on the plugin settings page erased the per-project limit and grouping.
- Fixed: "Cancel" on the project tabs saved the form; labels of the grouping checkboxes did not toggle them.
- Redmine 6.1+: global columns come from Redmine's own "Related and sub issues list defaults"; migration 003 copies the plugin's former global columns there; the header row follows Redmine's "Show table headers".
- Subtask table: "Remove subtask" link and row ids like core's.
- Context menu "Related to": fast for any selection; the relations are created all or nothing.
- Tests for every function, end-to-end browser scenarios in test/e2e.

# 2.0.1 - 2025-03-13 - Jan Catrysse
- Added UI-only filtering for extra relation types with per-project configuration in the admin matrix and project tab.
- Kept standard Redmine relation types always visible in the "Add relation" dropdown.

# 2.0.0 - 2025-03-12 - Jan Catrysse
- Added plugin-configured "relates-like" relation types with example labels.
- Added global and per-project settings to group related issues by relation type.

# 1.0.3 - 2025-10-24 - Jan Catrysse
- Added a configurable limit for related issues with an inline toggle to reveal or hide extra rows.
- Introduced global and per-project settings for the related issues limit.

# 1.0.2 - 2025-06-25 - Jan Catrysse
- Issue page does handle adding or destroying related issues correctly
- Introduced a dedicated namespace for helper patches in project_helper_patch.rb, ensuring proper Zeitwerk autoloading
- Namespaced the hook listener in view_issues_show_hook.rb to align with the new directory structure
- Updated init.rb to load files from redmine_issue_view_columns and removed the custom Zeitwerk ignore block

## 1.0.1
- Maintenance release.
