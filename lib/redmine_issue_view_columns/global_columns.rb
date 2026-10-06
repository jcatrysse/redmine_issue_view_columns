module RedmineIssueViewColumns
  # Columns of the subtask and related issue tables for a project without its own columns.
  # Redmine 6.1+ has its own setting for them (#42477, Administration > Settings > Issue tracking);
  # on older Redmine the plugin's global setting is used.
  module GlobalColumns
    class << self
      def core_setting?
        Setting.available_settings.key?("related_issues_default_columns")
      end

      def column_names
        Array(core_setting? ? Setting.related_issues_default_columns : plugin_columns).map(&:to_s)
      end

      def plugin_columns
        Array((Setting.plugin_redmine_issue_view_columns || {})["issue_view_default_columns"]).reject(&:blank?).map(&:to_s)
      end

      # Copies the plugin's global columns into core's setting, once, when moving to Redmine 6.1+.
      # The plugin's value is kept, so going back to an older plugin version shows the same columns.
      def copy_plugin_columns_to_core!
        return false unless core_setting?

        columns = plugin_columns - %w[tracker subject]
        return false if columns.empty?

        Setting.related_issues_default_columns = columns
        true
      end
    end
  end
end
