require File.expand_path("../../test_helper", __dir__)

class ContextMenuHelperTest < ActiveSupport::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles

  def setup
    User.current = User.find(1)
    @helper = Class.new do
      include IssueViewColumnsContextMenuHelper
    end.new
  end

  def test_relates_clique_available_returns_false_when_all_pairs_exist
    project = Project.find(1)
    issue_one = Issue.generate!(project: project)
    issue_two = Issue.generate!(project: project)
    issue_three = Issue.generate!(project: project)

    IssueRelation.create!(issue_from: issue_one, issue_to: issue_two, relation_type: IssueRelation::TYPE_RELATES)
    IssueRelation.create!(issue_from: issue_one, issue_to: issue_three, relation_type: IssueRelation::TYPE_RELATES)
    IssueRelation.create!(issue_from: issue_two, issue_to: issue_three, relation_type: IssueRelation::TYPE_RELATES)

    assert_equal false, @helper.relates_clique_available?([issue_one, issue_two, issue_three])
  end

  def test_relates_clique_available_returns_true_when_missing_pair
    project = Project.find(1)
    issue_one = Issue.generate!(project: project)
    issue_two = Issue.generate!(project: project)
    issue_three = Issue.generate!(project: project)

    IssueRelation.create!(issue_from: issue_one, issue_to: issue_two, relation_type: IssueRelation::TYPE_RELATES)

    assert_equal true, @helper.relates_clique_available?([issue_one, issue_two, issue_three])
  end

  def test_relates_clique_available_returns_false_across_projects_when_not_allowed
    issue_one = Issue.generate!(project: Project.find(1))
    issue_two = Issue.generate!(project: Project.find(2))

    with_settings cross_project_issue_relations: "0" do
      assert_equal false, @helper.relates_clique_available?([issue_one, issue_two])
    end
    with_settings cross_project_issue_relations: "1" do
      assert_equal true, @helper.relates_clique_available?([issue_one, issue_two])
    end
  end

  def test_relates_clique_available_returns_false_for_a_parent_and_its_subtask
    parent = Issue.generate!(project: Project.find(1))
    child = Issue.generate!(project: Project.find(1), parent_issue_id: parent.id)

    assert_equal false, @helper.relates_clique_available?([parent.reload, child.reload])
  end

  def test_relates_clique_available_does_not_query_per_pair
    issues = Array.new(20) { Issue.generate!(project: Project.find(1)) }
    queries = 0
    counter = ->(*) { queries += 1 }

    result = ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      @helper.relates_clique_available?(issues)
    end

    assert_equal true, result
    # linear in the issues (permission per issue), not per pair: 190 pairs took about 4 queries each
    assert_operator queries, :<, 3 * issues.size
  end
end
