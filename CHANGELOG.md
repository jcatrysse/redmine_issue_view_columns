# Changelog

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
