require_dependency File.dirname(__FILE__) + "/lib/redmine_issue_view_columns/relation_types.rb"
require_dependency File.dirname(__FILE__) + "/lib/redmine_issue_view_columns/project_helper_patch.rb"
require_dependency File.dirname(__FILE__) + "/lib/redmine_issue_view_columns/view_issues_show_hook.rb"

Redmine::Plugin.register :redmine_issue_view_columns do
  name "Redmine Issue View Columns"
  author "Kenan Dervišević and Jan Catrysse"
  description "Customize shown columns in subtasks and related issues on issue page"
  version "2.0.0"
  url "https://github.com/jcatrysse/redmine_issue_view_columns"

  project_module :issue_view_columns do
    permission :manage_issue_view_columns, { issue_view_columns: :index }, { require: :member }
  end
  settings default: {
    "empty": true,
    "relations_group_by_type": false,
    "project_relations_group_by_type": {}
  }, partial: "settings/issue_view_columns_settings"
end


# helper methods needed for the Settings page of the project also
ProjectsController.send :helper, IssueViewColumnsHelper
IssuesController.send :helper, IssueViewColumnsIssuesHelper
IssueRelationsController.send :helper, IssueViewColumnsIssuesHelper

local_config = File.join(__dir__, "config", "redmine_issue_view_columns.local.rb")
load local_config if File.exist?(local_config)
