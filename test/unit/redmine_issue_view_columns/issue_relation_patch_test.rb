require File.expand_path("../../test_helper", __dir__)

class IssueRelationPatchTest < ActiveSupport::TestCase
  def setup
    @original_types = IssueRelation::TYPES
    RedmineIssueViewColumns::RelationTypes.instance_variable_set(:@relates_like_types, [])
    RedmineIssueViewColumns::RelationTypes.instance_variable_set(:@registered_types, {})
    RedmineIssueViewColumns::RelationTypes.instance_variable_set(:@base_types, @original_types)
    RedmineIssueViewColumns::RelationTypes.register!(
      {
        "relates_custom" => {
          name: :label_relates_to,
          sym_name: :label_relates_to,
          order: 9.9,
          sym: "relates_custom"
        },
        "relates_other" => {
          name: :label_relates_to,
          sym_name: :label_relates_to,
          order: 9.8,
          sym: "relates_other"
        }
      },
      relates_like: ["relates_custom", "relates_other"]
    )
  end

  def teardown
    IssueRelation.send(:remove_const, :TYPES)
    IssueRelation.const_set(:TYPES, @original_types)
    RedmineIssueViewColumns::RelationTypes.instance_variable_set(:@relates_like_types, [])
    RedmineIssueViewColumns::RelationTypes.instance_variable_set(:@registered_types, {})
    RedmineIssueViewColumns::RelationTypes.instance_variable_set(:@base_types, @original_types)
  end

  def test_circular_dependency_returns_false_when_ids_missing
    relation = IssueRelation.new(relation_type: "relates_custom")

    assert_equal false, relation.circular_dependency?
  end

  def test_relates_like_allows_multiple_relation_types_between_same_issues
    issue_from = Issue.generate!
    issue_to = Issue.generate!

    relation_one = IssueRelation.create!(
      issue_from: issue_from,
      issue_to: issue_to,
      relation_type: "relates_custom"
    )

    relation_two = IssueRelation.new(
      issue_from: issue_from,
      issue_to: issue_to,
      relation_type: IssueRelation::TYPE_RELATES
    )

    relation_three = IssueRelation.new(
      issue_from: issue_from,
      issue_to: issue_to,
      relation_type: "relates_other"
    )

    assert relation_one.persisted?
    assert relation_two.valid?
    assert relation_three.valid?
  end

  def test_relates_like_prevents_duplicates_when_direction_is_swapped
    issue_from = Issue.generate!
    issue_to = Issue.generate!

    relation_one = IssueRelation.create!(
      issue_from: issue_to,
      issue_to: issue_from,
      relation_type: "relates_custom"
    )

    relation_two = IssueRelation.new(
      issue_from: issue_from,
      issue_to: issue_to,
      relation_type: "relates_custom"
    )

    assert relation_one.persisted?
    assert_equal false, relation_two.valid?
  end

  def test_relates_like_does_not_swap_issue_direction
    issue_from = Issue.generate!
    issue_to = Issue.generate!
    issue_from, issue_to = issue_to, issue_from if issue_from.id < issue_to.id

    relation = IssueRelation.create!(
      issue_from: issue_from,
      issue_to: issue_to,
      relation_type: "relates_custom"
    )

    assert_equal issue_from.id, relation.issue_from_id
    assert_equal issue_to.id, relation.issue_to_id
  end
end
