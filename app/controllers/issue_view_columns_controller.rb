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
    limit_param = params[:relations_limit].to_s

    if limit_param.present? && limit_param.to_i.positive?
      project_limits[@project.id.to_s] = limit_param.to_i
    else
      project_limits.delete(@project.id.to_s)
    end

    plugin_settings = plugin_settings.merge("project_relations_limits" => project_limits)
    Setting.plugin_redmine_issue_view_columns = plugin_settings

    redirect_to :back, notice: l(:label_issue_columns_created_sucessfully)
  end
end
