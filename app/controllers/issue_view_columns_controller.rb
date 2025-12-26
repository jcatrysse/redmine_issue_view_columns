class IssueViewColumnsController < ApplicationController
  include QueriesHelper
  include IssueViewColumnsHelper
  before_action :find_project_by_project_id
  before_action :build_query_for_project

  def index
    @query
  end

  # refactor update, it's not good to do save like this
  def update
    update_selected_columns = params[:c] || []
    IssueViewColumns.where("project_id = ?", params[:project_id]).delete_all
    order = 0
    update_selected_columns.each do |col|
      # tracker and subject are always included in the first column
      next if ["tracker", "subject"].include? col
      c = IssueViewColumns.new
      order += 1
      c.project_id = params[:project_id]
      c.ident = col
      c.order = order
      c.save
    end

    plugin_settings = Setting.plugin_redmine_issue_view_columns || {}
    project_limits = (plugin_settings["project_relations_limits"] || {}).dup
    project_groupings = (plugin_settings["project_relations_group_by_type"] || {}).dup
    limit_param = params[:relations_limit].to_s
    group_param = params[:relations_group_by_type].to_s

    if limit_param.present? && limit_param.to_i.positive?
      project_limits[@project.id.to_s] = limit_param.to_i
    else
      project_limits.delete(@project.id.to_s)
    end

    if group_param.present?
      project_groupings[@project.id.to_s] = group_param == "1"
    else
      project_groupings.delete(@project.id.to_s)
    end

    plugin_settings = plugin_settings.merge(
      "project_relations_limits" => project_limits,
      "project_relations_group_by_type" => project_groupings
    )
    Setting.plugin_redmine_issue_view_columns = plugin_settings

    redirect_back(
      fallback_location: url_for(controller: "issue_view_columns", action: "index", project_id: @project),
      notice: l(:label_issue_columns_created_sucessfully)
    )
  end
end
