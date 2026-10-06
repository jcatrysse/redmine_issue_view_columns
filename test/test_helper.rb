# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + "/../../../test/test_helper")

# Saves and restores the relation type registry around a test, and starts from core's relation
# types even when a config/redmine_issue_view_columns.local.rb registered extra types at boot.
module IssueViewColumnsRelationTypesState
  STATE = %i[@relates_like_types @registered_types @base_types].freeze

  def save_relation_types_state
    @saved_relation_types = IssueRelation::TYPES
    @saved_relation_types_state = STATE.to_h { |ivar| [ivar, RedmineIssueViewColumns::RelationTypes.instance_variable_get(ivar)] }
    core_types = @saved_relation_types_state[:@base_types] || @saved_relation_types
    IssueRelation.send(:remove_const, :TYPES)
    IssueRelation.const_set(:TYPES, core_types)
    RedmineIssueViewColumns::RelationTypes.instance_variable_set(:@relates_like_types, [])
    RedmineIssueViewColumns::RelationTypes.instance_variable_set(:@registered_types, {})
    RedmineIssueViewColumns::RelationTypes.instance_variable_set(:@base_types, core_types)
    core_types
  end

  def restore_relation_types_state
    IssueRelation.send(:remove_const, :TYPES)
    IssueRelation.const_set(:TYPES, @saved_relation_types)
    @saved_relation_types_state.each { |ivar, value| RedmineIssueViewColumns::RelationTypes.instance_variable_set(ivar, value) }
  end
end
