require File.expand_path("../test_helper", __dir__)

class IssueViewColumnsProjectSettingsTest < Redmine::ControllerTest
  tests ProjectsController

  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles,
           :trackers, :projects_trackers, :enabled_modules, :issue_statuses,
           :enumerations, :workflows

  def setup
    User.current = nil
    @project = Project.find(1)
    @project.enable_module!(:issue_view_columns)
    # jsmith (2) is Manager (role 1) on project 1
    Role.find(1).add_permission!(:manage_issue_view_columns)
  end

  def test_settings_tab_with_permission_shows_the_columns_form
    @request.session[:user_id] = 2

    get :settings, params: { id: @project.identifier, tab: "issue_view_columns" }

    assert_response :success
    assert_select "#tab-issue_view_columns", text: I18n.t(:issue_view_columns_settings)
    assert_select "form[action=?]", "/issue_view_columns" do
      assert_select "input[name=project_id][value=?]", @project.id.to_s
      assert_select "select#selected_c"
      assert_select "input[name=relations_limit]"
      assert_select "input[type=checkbox][name=relations_group_by_type]"
    end
  end

  def test_settings_tab_is_hidden_without_permission
    Role.find(1).remove_permission!(:manage_issue_view_columns)
    @request.session[:user_id] = 2

    get :settings, params: { id: @project.identifier }

    assert_response :success
    assert_select "#tab-issue_view_columns", 0
  end

  def test_settings_tab_is_hidden_when_the_module_is_disabled
    @project.disable_module!(:issue_view_columns)
    @request.session[:user_id] = 2

    get :settings, params: { id: @project.identifier }

    assert_response :success
    assert_select "#tab-issue_view_columns", 0
  end
end
