require File.expand_path("../test_helper", __dir__)

class IssueViewColumnsPluginSettingsTest < Redmine::ControllerTest
  tests SettingsController

  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles

  def setup
    User.current = nil
    @original_settings = Setting.plugin_redmine_issue_view_columns
  end

  def teardown
    Setting.plugin_redmine_issue_view_columns = @original_settings
  end

  def test_plugin_settings_page_shows_the_default_columns_selector
    Setting.plugin_redmine_issue_view_columns = { "issue_view_default_columns" => %w[status priority] }
    @request.session[:user_id] = 1

    get :plugin, params: { id: "redmine_issue_view_columns" }

    assert_response :success
    # Redmine 6+ CSS lays the selector out side by side only inside #list-definition > div
    assert_select "#list-definition > div select#available_settings_issue_view_default_columns"
    assert_select "#list-definition > div select#selected_settings_issue_view_default_columns option", 2
    assert_select "input[name='settings[relations_display_limit]']"
    assert_select "input[type=checkbox][name='settings[relations_group_by_type]']"
  end

  def test_plugin_settings_are_saved
    @request.session[:user_id] = 1

    post :plugin, params: { id: "redmine_issue_view_columns",
                            settings: { issue_view_default_columns: %w[status assigned_to],
                                        relations_display_limit: "3", relations_group_by_type: "1" } }

    assert_response :redirect
    settings = Setting.plugin_redmine_issue_view_columns
    assert_equal %w[status assigned_to], settings["issue_view_default_columns"]
    assert_equal "3", settings["relations_display_limit"]
    assert_equal "1", settings["relations_group_by_type"]
  end

  def test_plugin_settings_page_keeps_the_per_project_limit_and_grouping
    Setting.plugin_redmine_issue_view_columns = {
      "project_relations_limits" => { "1" => 2 },
      "project_relations_group_by_type" => { "1" => false, "2" => true }
    }
    @request.session[:user_id] = 1

    get :plugin, params: { id: "redmine_issue_view_columns" }

    assert_response :success
    # Apply replaces every plugin setting with what the form posts, so these must be in the form
    assert_select "input[type=hidden][name=?][value='2']", "settings[project_relations_limits][1]"
    assert_select "input[type=hidden][name=?][value='false']", "settings[project_relations_group_by_type][1]"
    assert_select "input[type=hidden][name=?][value='true']", "settings[project_relations_group_by_type][2]"
  end

  def test_plugin_settings_post_with_the_kept_values_preserves_project_overrides
    Setting.plugin_redmine_issue_view_columns = { "project_relations_limits" => { "1" => 2 } }
    @request.session[:user_id] = 1

    post :plugin, params: { id: "redmine_issue_view_columns",
                            settings: { relations_display_limit: "1",
                                        project_relations_limits: { "1" => "2" },
                                        project_relations_group_by_type: { "1" => "false" } } }

    project = Project.find(1)
    project.enable_module!(:issue_view_columns)
    helper = Class.new { include IssueViewColumnsHelper }.new
    assert_equal 2, helper.relations_display_limit_for(project)
    assert_equal false, helper.relations_grouped_by_type_for(project)
  end

  def test_plugin_settings_are_refused_to_non_admins
    @request.session[:user_id] = 2

    get :plugin, params: { id: "redmine_issue_view_columns" }

    assert_response 403
  end
end
