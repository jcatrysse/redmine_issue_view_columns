require File.expand_path("../test_helper", __dir__)

class IssueViewColumnsRelationsControllerTest < Redmine::ControllerTest
  fixtures :projects, :users, :roles, :members, :member_roles,
           :trackers, :projects_trackers, :enabled_modules, :issue_statuses,
           :enumerations, :workflows

  def setup
    User.current = nil
  end

  def test_create_pairwise_relations_for_multiple_issues
    @request.session[:user_id] = 1
    project = Project.find(1)
    issue_one = Issue.generate!(project: project)
    issue_two = Issue.generate!(project: project)
    issue_three = Issue.generate!(project: project)
    back_url = "/issues"

    assert_difference "IssueRelation.count", 3 do
      post(
        :create,
        params: {
          ids: [issue_one.id, issue_two.id, issue_three.id],
          back_url: back_url
        }
      )
    end

    assert_redirected_to back_url
  end

  def test_create_skips_existing_relations
    @request.session[:user_id] = 1
    project = Project.find(1)
    issue_one = Issue.generate!(project: project)
    issue_two = Issue.generate!(project: project)
    issue_three = Issue.generate!(project: project)
    IssueRelation.create!(
      issue_from: issue_one,
      issue_to: issue_two,
      relation_type: IssueRelation::TYPE_RELATES
    )

    assert_difference "IssueRelation.count", 2 do
      post(
        :create,
        params: { ids: [issue_one.id, issue_two.id, issue_three.id] }
      )
    end
  end

  def test_create_requires_manage_relations_permission
    # A logged-in non-member gets the "Non member" role, which has
    # manage_issue_relations in Redmine's fixtures: take it away explicitly.
    Role.non_member.remove_permission!(:manage_issue_relations)
    user = User.generate!
    @request.session[:user_id] = user.id
    project = Project.find(1)
    issue_one = Issue.generate!(project: project)
    issue_two = Issue.generate!(project: project)

    assert_no_difference "IssueRelation.count" do
      post(
        :create,
        params: { ids: [issue_one.id, issue_two.id] }
      )
    end

    assert_response 403
  end

  def test_destroy_removes_relation_and_redirects
    @request.session[:user_id] = 1
    project = Project.find(1)
    issue_one = Issue.generate!(project: project)
    issue_two = Issue.generate!(project: project)
    relation = IssueRelation.create!(
      issue_from: issue_one,
      issue_to: issue_two,
      relation_type: IssueRelation::TYPE_RELATES
    )
    back_url = "/issues"

    assert_difference "IssueRelation.count", -1 do
      delete(
        :destroy,
        params: { id: relation.id, back_url: back_url }
      )
    end

    assert_redirected_to back_url
  end

  def test_destroy_requires_manage_relations_permission
    Role.non_member.remove_permission!(:manage_issue_relations)
    user = User.generate!
    @request.session[:user_id] = user.id
    project = Project.find(1)
    relation = IssueRelation.create!(
      issue_from: Issue.generate!(project: project),
      issue_to: Issue.generate!(project: project),
      relation_type: IssueRelation::TYPE_RELATES
    )

    assert_no_difference "IssueRelation.count" do
      delete :destroy, params: { id: relation.id }
    end

    assert_response 403
  end

  def test_destroy_unknown_relation_returns_404
    @request.session[:user_id] = 1

    delete :destroy, params: { id: 999_999 }

    assert_response 404
  end
end
