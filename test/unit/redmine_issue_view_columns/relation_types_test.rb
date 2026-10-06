require File.expand_path("../../test_helper", __dir__)

class RelationTypesTest < ActiveSupport::TestCase
  include IssueViewColumnsRelationTypesState

  def setup
    @original_types = save_relation_types_state
  end

  def teardown
    restore_relation_types_state
  end

  def test_register_adds_types_and_relates_like
    RedmineIssueViewColumns::RelationTypes.register!(
      {
        "relates_custom" => {
          name: :label_relates_to,
          sym_name: :label_relates_to,
          order: 9.9,
          sym: "relates_custom"
        }
      },
      relates_like: %w[relates_custom relates_custom]
    )

    assert IssueRelation::TYPES.key?("relates_custom")
    assert RedmineIssueViewColumns::RelationTypes.relates_like?("relates_custom")
    assert_equal 1, RedmineIssueViewColumns::RelationTypes.send(:relates_like_types).uniq.size
    assert IssueQuery.method_defined?(:sql_for_relates_custom_field)
  end

  def test_refresh_validator_handles_missing_validator
    IssueRelation.singleton_class.alias_method(:_validators_original, :_validators)
    IssueRelation.define_singleton_method(:_validators) { {} }

    assert_nothing_raised do
      RedmineIssueViewColumns::RelationTypes.send(:refresh_relation_type_validator!)
    end
  ensure
    if IssueRelation.singleton_class.method_defined?(:_validators_original)
      IssueRelation.singleton_class.alias_method(:_validators, :_validators_original)
      IssueRelation.singleton_class.remove_method(:_validators_original)
    end
  end

  def test_register_merges_types_without_overwriting_previous
    RedmineIssueViewColumns::RelationTypes.register!(
      {
        "relates_alpha" => {
          name: :label_relates_to,
          sym_name: :label_relates_to,
          order: 9.1,
          sym: "relates_alpha"
        }
      }
    )

    RedmineIssueViewColumns::RelationTypes.register!(
      {
        "relates_beta" => {
          name: :label_relates_to,
          sym_name: :label_relates_to,
          order: 9.2,
          sym: "relates_beta"
        }
      }
    )

    assert IssueRelation::TYPES.key?("relates_alpha")
    assert IssueRelation::TYPES.key?("relates_beta")
    assert IssueRelation::TYPES.key?(@original_types.keys.first)
  end
end
