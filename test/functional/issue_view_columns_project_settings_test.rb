require File.expand_path("../test_helper", __dir__)

class IssueViewColumnsProjectSettingsTest < Redmine::ControllerTest
  include IssueViewColumnsRelationTypesState
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
      # Redmine 6+ CSS lays the selector out side by side only inside #list-definition > div
      assert_select "#list-definition > div select#available_c"
      assert_select "#list-definition > div select#selected_c"
      assert_select "input[name=relations_limit]"
      assert_select "input[type=checkbox][name=relations_group_by_type]"
      # the label must reach the checkbox, not the hidden "0" field before it
      assert_select "#relations_group_by_type", 1
      assert_select "input[type=checkbox]#relations_group_by_type"
      # Cancel leaves without saving: a link, not a second submit button of this form
      assert_select "input[type=submit][value=?]", I18n.t(:button_cancel), 0
    end
    assert_select "#tab-content-issue_view_columns a[href=?]", "/projects/#{@project.identifier}/settings/issue_view_columns",
                  text: I18n.t(:button_cancel)
  end

  def test_relation_types_tab_saves_and_cancels_without_a_second_submit
    with_extra_relation_type do
      @request.session[:user_id] = 2

      get :settings, params: { id: @project.identifier, tab: "issue_view_columns_relations" }

      assert_response :success
      assert_select "#tab-content-issue_view_columns_relations form[action=?]", "/issue_view_columns/relation_types" do
        assert_select "input[type=checkbox][name=?][value=relates_custom]", "project_relation_types[#{@project.id}][]"
        assert_select "#project_relation_types_all_#{@project.id}", 1
        assert_select "input[type=submit][value=?]", I18n.t(:button_cancel), 0
      end
      assert_select "#tab-content-issue_view_columns_relations a[href=?]",
                    "/projects/#{@project.identifier}/settings/issue_view_columns_relations", text: I18n.t(:button_cancel)
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

  private

  def with_extra_relation_type
    save_relation_types_state
    RedmineIssueViewColumns::RelationTypes.register!(
      { "relates_custom" => { name: :label_relates_to, sym_name: :label_relates_to, order: 9.9, sym: "relates_custom" } },
      relates_like: %w[relates_custom]
    )
    yield
  ensure
    restore_relation_types_state
  end
end
