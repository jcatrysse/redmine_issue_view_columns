class ViewIssuesShowHook < Redmine::Hook::ViewListener
  render_on :view_issues_show_description_bottom, partial: 'issue_view_columns/custom_subtasks'
end
