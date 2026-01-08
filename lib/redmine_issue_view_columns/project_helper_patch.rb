module RedmineIssueViewColumns
  module ProjectHelperPatch
    include IssueViewColumnsHelper

    def project_settings_tabs
      super.tap do |tabs|
        tabs << {
          name: "issue_view_columns",
          action: :issue_view_columns,
          partial: "issue_view_columns/index",
          label: :issue_view_columns_settings,
        } if User.current.allowed_to?(:manage_issue_view_columns, @project) &&
             @project.module_enabled?(:issue_view_columns)

        tabs << {
          name: "issue_view_columns_relations",
          action: :issue_view_columns,
          partial: "issue_view_columns/relation_types",
          label: :label_issue_view_columns_relation_types_tab,
        } if (User.current.allowed_to?(:manage_issue_view_columns, @project) || User.current.admin?) &&
             additional_relation_type_keys.any?
      end
    end
  end
end

ProjectsController.helper RedmineIssueViewColumns::ProjectHelperPatch
