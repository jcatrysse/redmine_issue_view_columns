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
    assert_select "a[href^=?][data-method=post]", "/issue_view_columns/relations", text: /#{I18n.t(:label_relates_to)}/ do
      assert_select "svg use[href*=?]", "icon--link" if Redmine::VERSION::MAJOR >= 6
    end
    assert_select "a[data-method=delete][href^=?]", "/issue_view_columns/relations/", 0
  end

  def test_context_menu_offers_translated_remove_relation_for_related_issues
    relation = IssueRelation.create!(issue_from: @issue_one, issue_to: @issue_two,
                                     relation_type: IssueRelation::TYPE_RELATES)

    get_context_menu [@issue_one.id, @issue_two.id]

    assert_response :success
    label = I18n.t(:label_relation_remove, default: :label_relation_delete)
    assert_select "a[data-method=delete][href^=?]", "/issue_view_columns/relations/#{relation.id}", text: /#{label}/ do |links|
      assert_no_match(/translation missing/i, links.first.to_s)
      assert_select "svg use[href*=?]", "link-break" if Redmine::VERSION::MAJOR >= 6
    end
    # every pair is already related, so "Related to" is not offered again
    assert_select "a[href^=?][data-method=post]", "/issue_view_columns/relations", 0
  end

  private

  def get_context_menu(ids)
    action = CONTEXT_MENU_ISSUES_CONTROLLER.action_methods.include?("index") ? :index : :issues
    get action, params: { ids: ids, back_url: "/issues" }
  end
end
