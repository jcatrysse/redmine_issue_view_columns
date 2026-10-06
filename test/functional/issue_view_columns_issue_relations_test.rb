require File.expand_path("../test_helper", __dir__)

# Adding or removing a relation on the issue page re-renders the related issues
# through IssueRelationsController (ca689ee): the plugin's table must come back,
# not core's.
class IssueViewColumnsIssueRelationsTest < Redmine::ControllerTest
  tests IssueRelationsController

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
    @request.session[:user_id] = 1
  end

  def test_create_by_xhr_renders_the_plugin_table
    # the "check all" box sits in the header row, which Redmine 6.1+ only shows with this setting
    if Setting.available_settings.key?("display_related_issues_table_headers")
      original_headers = Setting.display_related_issues_table_headers
      Setting.display_related_issues_table_headers = "1"
    end
    assert_difference "IssueRelation.count", 1 do
      post :create, params: { issue_id: @issue.id,
                              relation: { issue_to_id: @other.id.to_s, relation_type: IssueRelation::TYPE_RELATES } },
                    xhr: true
    end

    assert_response :success
    assert_include "ivc-relation-row", response.body
    assert_include "toggle-selection", response.body
  ensure
    Setting.display_related_issues_table_headers = original_headers unless original_headers.nil?
  end

  def test_destroy_by_xhr_renders_the_plugin_table
    relation = IssueRelation.create!(issue_from: @issue, issue_to: @other, relation_type: IssueRelation::TYPE_RELATES)
    IssueRelation.create!(issue_from: @issue, issue_to: Issue.generate!(project: @project),
                          relation_type: IssueRelation::TYPE_RELATES)

    assert_difference "IssueRelation.count", -1 do
      delete :destroy, params: { id: relation.id, issue_id: @issue.id }, xhr: true
    end

    assert_response :success
    assert_include "relation-#{relation.id}", response.body
  end
end
