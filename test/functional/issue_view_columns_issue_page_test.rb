require File.expand_path("../test_helper", __dir__)

class IssueViewColumnsIssuePageTest < Redmine::ControllerTest
  tests IssuesController

  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles,
           :trackers, :projects_trackers, :enabled_modules, :issue_statuses,
           :enumerations, :workflows

  def setup
    User.current = nil
    @project = Project.find(1)
    @project.enable_module!(:issue_view_columns)
    IssueViewColumns.create!(project_id: @project.id, ident: "status", order: 1)
    @issue = Issue.generate!(project: @project)
    @other = Issue.generate!(project: @project)
    @relation = IssueRelation.create!(issue_from: @issue, issue_to: @other, relation_type: IssueRelation::TYPE_RELATES)
    @original_settings = Setting.plugin_redmine_issue_view_columns
    @original_core_columns = Setting.related_issues_default_columns if RedmineIssueViewColumns::GlobalColumns.core_setting?
    @original_headers = Setting.display_related_issues_table_headers if Setting.available_settings.key?("display_related_issues_table_headers")
  end

  def teardown
    Setting.plugin_redmine_issue_view_columns = @original_settings
    Setting.related_issues_default_columns = @original_core_columns if @original_core_columns
    Setting.display_related_issues_table_headers = @original_headers unless @original_headers.nil?
  end

  def test_related_issues_table_has_translated_remove_relation_link
    table_headers(true)
    @request.session[:user_id] = 1

    get :show, params: { id: @issue.id }

    assert_response :success
    label = I18n.t(:label_relation_remove, default: :label_relation_delete)
    assert_select "#relations tr#relation-#{@relation.id} td.buttons a.icon-link-break[title=?]", label do |links|
      assert_no_match(/translation missing/i, links.first.to_s)
      assert_select "svg use[href*=?]", "link-break" if Redmine::VERSION::MAJOR >= 6
    end
    assert_select "#relations th", text: I18n.t(:field_status)
  end

  def test_related_issues_table_has_no_remove_link_without_manage_relations
    Role.anonymous.add_permission!(:view_issues)
    Role.anonymous.remove_permission!(:manage_issue_relations)

    get :show, params: { id: @issue.id }

    assert_response :success
    assert_select "#relations tr#relation-#{@relation.id}"
    assert_select "#relations a.icon-link-break", 0
  end

  def test_relations_limit_wraps_the_table_and_marks_every_row_when_not_grouped
    add_relations(2)
    plugin_settings("project_relations_limits" => { @project.id.to_s => 2 },
                    "project_relations_group_by_type" => { @project.id.to_s => false })
    @request.session[:user_id] = 1

    get :show, params: { id: @issue.id }

    assert_response :success
    assert_select "#relations div.ivc-relations-wrapper[data-limit='2']" do
      # better_subtasks_table.js hides the rows after the limit; it only counts tr.ivc-relation-row
      assert_select "tr.ivc-relation-row", 3
      assert_select "tr.ivc-relation-group-header", 0
      assert_select "button.ivc-relations-toggle", text: I18n.t(:label_issue_view_columns_show_more_relations)
    end
  end

  def test_relations_limit_is_not_rendered_when_relations_fit
    plugin_settings("project_relations_limits" => { @project.id.to_s => 5 })
    @request.session[:user_id] = 1

    get :show, params: { id: @issue.id }

    assert_response :success
    assert_select "#relations div.ivc-relations-wrapper", 0
    assert_select "#relations button.ivc-relations-toggle", 0
  end

  def test_relations_grouped_by_type_have_a_header_per_type
    blocked = Issue.generate!(project: @project)
    IssueRelation.create!(issue_from: @issue, issue_to: blocked, relation_type: IssueRelation::TYPE_BLOCKS)
    plugin_settings("project_relations_group_by_type" => { @project.id.to_s => true })
    @request.session[:user_id] = 1

    get :show, params: { id: @issue.id }

    assert_response :success
    assert_select "#relations tr.ivc-relation-group-header[data-relation-group=relates] th", text: I18n.t(:label_relates_to)
    assert_select "#relations tr.ivc-relation-group-header[data-relation-group=blocks] th", text: I18n.t(:label_blocks)
    assert_select "#relations tr.ivc-relation-row[data-relation-group=relates]", 1
    assert_select "#relations tr.ivc-relation-row[data-relation-group=blocks]", 1
  end

  def test_subtasks_table_shows_the_project_columns
    table_headers(true)
    Issue.generate!(project: @project, parent_issue_id: @issue.id)
    @request.session[:user_id] = 1

    get :show, params: { id: @issue.id }

    assert_response :success
    assert_select "#issue_tree th", text: I18n.t(:field_status)
    assert_select "#issue_tree tr.issue td.status", 1
  end

  # Redmine 6.1+: the global columns are core's related issues columns (#42477); before, the plugin's
  def test_subtasks_table_has_core_remove_subtask_link_and_row_id
    child = Issue.generate!(project: @project, parent_issue_id: @issue.id)
    @request.session[:user_id] = 1

    get :show, params: { id: @issue.id }

    assert_response :success
    label = I18n.t(:label_subtask_remove, default: :label_delete_link_to_subtask)
    assert_select "#issue_tree tr#issue-#{child.id}.issue td.buttons" do
      assert_select "a.icon-link-break[data-method=put][title=?][href*=?]", label, "parent_issue_id%5D=" do
        assert_select "svg use[href*=?]", "link-break" if Redmine::VERSION::MAJOR >= 6
      end
      assert_select "a.icon-actions"
    end
  end

  def test_subtasks_table_has_no_remove_subtask_link_without_manage_subtasks
    Issue.generate!(project: @project, parent_issue_id: @issue.id)
    Role.anonymous.add_permission!(:view_issues)
    Role.anonymous.remove_permission!(:manage_subtasks)

    get :show, params: { id: @issue.id }

    assert_response :success
    assert_select "#issue_tree tr.issue"
    assert_select "#issue_tree a.icon-link-break", 0
  end

  def test_table_headers_follow_the_core_setting
    Issue.generate!(project: @project, parent_issue_id: @issue.id)
    @request.session[:user_id] = 1

    table_headers(false)
    get :show, params: { id: @issue.id }
    # Redmine 6.1+ hides the headers unless "Display table headers" is on; 5.1 has no such setting
    expected = RedmineIssueViewColumns::GlobalColumns.core_setting? ? 0 : 1
    assert_select "#relations table thead", expected
    assert_select "#issue_tree table thead", expected

    table_headers(true)
    get :show, params: { id: @issue.id }
    assert_select "#relations table thead", 1
    assert_select "#issue_tree table thead", 1
  end

  def test_global_columns_apply_when_the_module_is_disabled
    @project.disable_module!(:issue_view_columns)
    global_columns(%w[priority])
    @request.session[:user_id] = 1

    get :show, params: { id: @issue.id }

    assert_response :success
    assert_select "#relations tr.ivc-relation-row td.priority"
    assert_select "#relations tr.ivc-relation-row td.status", 0
  end

  def test_global_columns_apply_when_the_project_has_no_columns_of_its_own
    IssueViewColumns.where(project_id: @project.id).delete_all
    global_columns(%w[priority])
    @request.session[:user_id] = 1

    get :show, params: { id: @issue.id }

    assert_response :success
    assert_select "#relations tr.ivc-relation-row td.priority"
  end

  def test_core_table_is_used_without_any_columns
    IssueViewColumns.where(project_id: @project.id).delete_all
    global_columns([])
    @request.session[:user_id] = 1

    get :show, params: { id: @issue.id }

    assert_response :success
    assert_select "#relations tr#relation-#{@relation.id}"
    assert_select "#relations tr.ivc-relation-row", 0
  end

  private

  def add_relations(count)
    count.times do
      IssueRelation.create!(issue_from: @issue, issue_to: Issue.generate!(project: @project),
                            relation_type: IssueRelation::TYPE_RELATES)
    end
  end

  def table_headers(on)
    return unless Setting.available_settings.key?("display_related_issues_table_headers")

    Setting.display_related_issues_table_headers = on ? "1" : "0"
  end

  def global_columns(names)
    if RedmineIssueViewColumns::GlobalColumns.core_setting?
      Setting.related_issues_default_columns = names
    else
      plugin_settings("issue_view_default_columns" => names)
    end
  end

  def plugin_settings(values)
    Setting.plugin_redmine_issue_view_columns = (Setting.plugin_redmine_issue_view_columns || {}).merge(values)
  end
end
