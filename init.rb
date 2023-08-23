Redmine::Plugin.register :redmine_issue_view_columns do
  name "Redmine Issue View Columns"
  author "Kenan Dervišević"
  description "Customize shown columns in subtasks and related issues on issue page"
  version "1.0.1"
  url "https://github.com/kenan3008/redmine_issue_view_columns"

  project_module :issue_view_columns do
    permission :manage_issue_view_columns, { issue_view_columns: :index }, { require: :member }
  end
  settings default: { "empty": true }, partial: "settings/issue_view_columns_settings"
end

require File.dirname(__FILE__) + '/lib/issue_view_columns_project_settings_tab'
require File.dirname(__FILE__) + '/lib/issue_details_hooks'

ProjectsController.send :helper, IssueViewColumnsHelper
IssuesController.send :helper, IssueViewColumnsIssuesHelper
