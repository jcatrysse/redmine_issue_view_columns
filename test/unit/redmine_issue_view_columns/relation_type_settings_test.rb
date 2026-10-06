require File.expand_path("../../test_helper", __dir__)

# Extra relation types are offered in the "Add relation" dropdown per project (84f6c58)
class RelationTypeSettingsTest < ActiveSupport::TestCase
  fixtures :projects

  class HelperHost
    include Redmine::I18n
    include IssueRelationsHelper

    def initialize(project)
      @project = project
    end
  end

  def setup
    @original_types = IssueRelation::TYPES
    @original_settings = Setting.plugin_redmine_issue_view_columns
    RedmineIssueViewColumns::RelationTypes.instance_variable_set(:@relates_like_types, [])
    RedmineIssueViewColumns::RelationTypes.instance_variable_set(:@registered_types, {})
    RedmineIssueViewColumns::RelationTypes.instance_variable_set(:@base_types, @original_types)
    RedmineIssueViewColumns::RelationTypes.register!(
      {
        "relates_business" => { name: :label_relates_to_business, sym_name: :label_relates_to_business,
                                order: 1.1, sym: "relates_business" },
        "relates_technical" => { name: :label_relates_to_technical, sym_name: :label_relates_to_technical,
                                 order: 1.2, sym: "relates_technical" }
      },
      relates_like: %w[relates_business relates_technical]
    )
    @project = Project.find(1)
  end

  def teardown
    Setting.plugin_redmine_issue_view_columns = @original_settings
    IssueRelation.send(:remove_const, :TYPES)
    IssueRelation.const_set(:TYPES, @original_types)
    RedmineIssueViewColumns::RelationTypes.instance_variable_set(:@relates_like_types, [])
    RedmineIssueViewColumns::RelationTypes.instance_variable_set(:@registered_types, {})
    RedmineIssueViewColumns::RelationTypes.instance_variable_set(:@base_types, @original_types)
  end

  def test_extra_types_are_hidden_by_default
    keys = dropdown_keys

    assert_includes keys, IssueRelation::TYPE_RELATES
    assert_includes keys, IssueRelation::TYPE_BLOCKS
    assert_not_includes keys, "relates_business"
    assert_not_includes keys, "relates_technical"
  end

  def test_selected_extra_types_are_offered_for_that_project_only
    settings("project_relation_types" => { @project.id.to_s => %w[relates_business] })

    assert_includes dropdown_keys, "relates_business"
    assert_not_includes dropdown_keys, "relates_technical"
    assert_not_includes dropdown_keys(Project.find(2)), "relates_business"
  end

  def test_all_relations_offers_every_extra_type
    settings("project_relation_types_all" => { @project.id.to_s => true })

    assert_includes dropdown_keys, "relates_business"
    assert_includes dropdown_keys, "relates_technical"
  end

  def test_unknown_selected_types_are_ignored
    settings("project_relation_types" => { @project.id.to_s => %w[relates_business no_such_type] })

    assert_not_includes dropdown_keys, "no_such_type"
  end

  private

  def dropdown_keys(project = @project)
    HelperHost.new(project).collection_for_relation_type_select.map(&:last)
  end

  def settings(values)
    Setting.plugin_redmine_issue_view_columns = (Setting.plugin_redmine_issue_view_columns || {}).merge(values)
  end
end
