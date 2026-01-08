module IssueViewColumnsHelper
  include QueriesHelper

  def build_query_for_project
    @selected_columns = IssueViewColumns.all.select { |c| c.project_id == @project.id }.sort_by { |o| o.order }.collect { |f| f.ident }
    @selected_columns = ["#"] unless @selected_columns.count > 0
    @query = IssueQuery.new(column_names: @selected_columns)
    @query.project = @project
    @query
  end

  def relations_display_limit_for(project)
    settings = Setting.plugin_redmine_issue_view_columns || {}

    if project.module_enabled?(:issue_view_columns)
      project_limit = project_relations_display_limit(project)
      limit = project_limit.presence
    else
      limit = settings["relations_display_limit"].presence
    end

    limit = limit.to_i if limit.present?
    limit&.positive? ? limit : nil
  end

  def project_relations_display_limit(project)
    return nil unless project.module_enabled?(:issue_view_columns)

    settings = Setting.plugin_redmine_issue_view_columns || {}
    project_limits = settings["project_relations_limits"] || {}
    project_limits[project.id.to_s]
  end

  def relations_grouped_by_type_for(project)
    settings = Setting.plugin_redmine_issue_view_columns || {}

    if project.module_enabled?(:issue_view_columns)
      project_grouping = project_relations_group_by_type(project)
      return project_grouping unless project_grouping.nil?
    end

    ActiveModel::Type::Boolean.new.cast(settings["relations_group_by_type"])
  end

  def project_relations_group_by_type(project)
    return nil unless project.module_enabled?(:issue_view_columns)

    settings = Setting.plugin_redmine_issue_view_columns || {}
    project_groupings = settings["project_relations_group_by_type"] || {}
    value = project_groupings[project.id.to_s]
    return nil if value.nil?

    ActiveModel::Type::Boolean.new.cast(value)
  end

  def ordered_relation_type_keys
    IssueRelation::TYPES.keys.sort_by { |key| IssueRelation::TYPES[key][:order] }
  end

  def additional_relation_type_keys
    base_types = RedmineIssueViewColumns::RelationTypes.base_type_keys
    ordered_relation_type_keys.reject { |key| base_types.include?(key) }
                             .sort_by { |key| RedmineIssueViewColumns::RelationTypes.sort_key(key) }
  end

  def project_relation_types_override(project)
    RedmineIssueViewColumns::RelationTypeSettings.project_relation_types(project)
  end

  def project_relation_types_all?(project)
    RedmineIssueViewColumns::RelationTypeSettings.project_relation_types_all?(project)
  end
end
