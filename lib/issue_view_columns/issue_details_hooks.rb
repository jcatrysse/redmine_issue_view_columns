module IssueDetailsHooks
  class ViewsIssuesHook < Redmine::Hook::ViewListener
    def view_issues_show_details_bottom(context = {})
      stylesheet_link_tag('issue_view_columns_issue_details', plugin: :redmine_issue_view_columns)
    end
  end
end
