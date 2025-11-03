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
end
