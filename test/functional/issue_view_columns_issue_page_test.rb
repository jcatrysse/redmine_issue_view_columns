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
  end

  def test_related_issues_table_has_translated_remove_relation_link
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
end
