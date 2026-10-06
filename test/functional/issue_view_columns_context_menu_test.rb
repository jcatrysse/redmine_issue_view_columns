require File.expand_path("../test_helper", __dir__)

# Redmine 7.0 moved the issue context menu to ContextMenus::IssuesController#index (#44169);
# Redmine 5.1 and 6.x serve it from ContextMenusController#issues.
CONTEXT_MENU_ISSUES_CONTROLLER =
  begin
    ContextMenus::IssuesController
  rescue NameError
    ContextMenusController
  end

class IssueViewColumnsContextMenuTest < Redmine::ControllerTest
  tests CONTEXT_MENU_ISSUES_CONTROLLER

  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles,
           :trackers, :projects_trackers, :enabled_modules, :issue_statuses,
           :enumerations, :workflows

  def setup
    User.current = nil
    @request.session[:user_id] = 1
    project = Project.find(1)
    @issue_one = Issue.generate!(project: project)
    @issue_two = Issue.generate!(project: project)
  end

  def test_context_menu_offers_relates_to_for_unrelated_issues
    get_context_menu [@issue_one.id, @issue_two.id]

    assert_response :success
    assert_select "a[href^=?][data-method=post]", "/issue_view_columns/relations", text: /#{I18n.t(:label_relates_to)}/
  end

  private

  def get_context_menu(ids)
    action = CONTEXT_MENU_ISSUES_CONTROLLER.action_methods.include?("index") ? :index : :issues
    get action, params: { ids: ids, back_url: "/issues" }
  end
end
