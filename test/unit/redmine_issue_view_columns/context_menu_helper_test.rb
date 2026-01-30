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
end
