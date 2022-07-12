require_dependency File.dirname(__FILE__) + "/lib/issue_view_columns/project_helper_patch.rb"

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

if Rails.configuration.respond_to?(:autoloader) && Rails.configuration.autoloader == :zeitwerk
  Rails.autoloaders.each { |loader| loader.ignore(File.dirname(__FILE__) + '/lib') }
end

# helper methods needed for the Settings page of the project also
ProjectsController.send :helper, IssueViewColumnsHelper
IssuesController.send :helper, IssueViewColumnsIssuesHelper
