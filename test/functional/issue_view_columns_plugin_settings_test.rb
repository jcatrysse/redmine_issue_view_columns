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

  def test_plugin_settings_are_refused_to_non_admins
    @request.session[:user_id] = 2

    get :plugin, params: { id: "redmine_issue_view_columns" }

    assert_response 403
  end
end
