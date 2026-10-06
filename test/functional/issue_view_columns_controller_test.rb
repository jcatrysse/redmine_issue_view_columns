require File.expand_path("../test_helper", __dir__)

class IssueViewColumnsControllerTest < Redmine::ControllerTest
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles,
           :trackers, :projects_trackers, :enabled_modules, :issue_statuses,
           :enumerations, :workflows

  def setup
    User.current = nil
    @project = Project.find(1)
    @project.enable_module!(:issue_view_columns)
    # jsmith (2) is Manager (role 1) on project 1, dlopper (3) is Developer (role 2)
    Role.find(1).add_permission!(:manage_issue_view_columns)
    Role.find(2).remove_permission!(:manage_issue_view_columns)
    @original_settings = Setting.plugin_redmine_issue_view_columns
  end

  def teardown
    Setting.plugin_redmine_issue_view_columns = @original_settings
  end

  def test_update_with_permission_saves_columns_and_limit
    @request.session[:user_id] = 2

    post :update, params: { project_id: @project.id, c: %w[tracker status assigned_to], relations_limit: "4" }

    assert_response :redirect
    assert_equal %w[status assigned_to], project_columns(@project)
    assert_equal 4, Setting.plugin_redmine_issue_view_columns["project_relations_limits"][@project.id.to_s]
  end

  def test_update_with_project_identifier_saves_columns_for_that_project
    @request.session[:user_id] = 2

    post :update, params: { project_id: @project.identifier, c: %w[status] }

    assert_response :redirect
    assert_equal %w[status], project_columns(@project)
  end

  def test_update_without_permission_is_refused
    @request.session[:user_id] = 3

    post :update, params: { project_id: @project.id, c: %w[status], relations_limit: "4" }

    assert_response 403
    assert_equal [], project_columns(@project)
    assert_nil (Setting.plugin_redmine_issue_view_columns["project_relations_limits"] || {})[@project.id.to_s]
  end

  def test_update_by_non_member_of_private_project_is_refused
    project = Project.find(2) # private, jsmith is not a member
    project.enable_module!(:issue_view_columns)
    @request.session[:user_id] = 2

    post :update, params: { project_id: project.id, c: %w[status] }

    assert_response 403
    assert_equal [], project_columns(project)
  end

  def test_update_when_module_disabled_is_refused
    @project.disable_module!(:issue_view_columns)
    @request.session[:user_id] = 2

    post :update, params: { project_id: @project.id, c: %w[status] }

    assert_response 403
    assert_equal [], project_columns(@project)
  end

  def test_update_as_anonymous_requires_login
    post :update, params: { project_id: @project.id, c: %w[status] }

    assert_response :redirect
    assert_match %r{/login}, response.location
    assert_equal [], project_columns(@project)
  end

  def test_update_relation_types_without_permission_is_refused
    @request.session[:user_id] = 3

    post :update_relation_types, params: { project_id: @project.id, project_relation_types_all: { @project.id.to_s => "1" } }

    assert_response 403
    assert_nil (Setting.plugin_redmine_issue_view_columns["project_relation_types_all"] || {})[@project.id.to_s]
  end

  def test_update_relation_types_with_permission_is_saved
    @request.session[:user_id] = 2

    post :update_relation_types, params: { project_id: @project.id, project_relation_types_all: { @project.id.to_s => "1" } }

    assert_response :redirect
    assert_equal true, Setting.plugin_redmine_issue_view_columns["project_relation_types_all"][@project.id.to_s]
  end

  def test_update_relation_types_by_admin_with_module_disabled_is_saved
    @project.disable_module!(:issue_view_columns)
    @request.session[:user_id] = 1

    post :update_relation_types, params: { project_id: @project.id, project_relation_types_all: { @project.id.to_s => "1" } }

    assert_response :redirect
    assert_equal true, Setting.plugin_redmine_issue_view_columns["project_relation_types_all"][@project.id.to_s]
  end

  private

  def project_columns(project)
    IssueViewColumns.where(project_id: project.id).order(:order).pluck(:ident)
  end
end
