namespace :redmine_issue_view_columns do
  desc "Copy the plugin's global subtask/related issue columns into Redmine's own setting (Redmine 6.1+)"
  task copy_global_columns_to_core: :environment do
    if RedmineIssueViewColumns::GlobalColumns.copy_plugin_columns_to_core!
      puts "Copied: #{Setting.related_issues_default_columns.join(', ')}"
    else
      puts "Nothing copied (Redmine before 6.1, or no global plugin columns)."
    end
  end
end
