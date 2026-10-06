class CopyGlobalColumnsToCoreSetting < Rails.version < "5.1" ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  # Redmine 6.1+ takes the global columns from its own setting; copy the plugin's once.
  # Before 6.1 nothing happens: run rake redmine_issue_view_columns:copy_global_columns_to_core
  # after upgrading Redmine itself.
  def up
    RedmineIssueViewColumns::GlobalColumns.copy_plugin_columns_to_core!
  end

  def down
    # the plugin's own value was kept, so nothing to restore
  end
end
