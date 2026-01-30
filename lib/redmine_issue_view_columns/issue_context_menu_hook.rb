module RedmineIssueViewColumns
  class IssueContextMenuHook < Redmine::Hook::ViewListener
    render_on :view_issues_context_menu_end, partial: 'issue_view_columns/context_menu'
  end
end
