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
    project_relation_types = (plugin_settings["project_relation_types"] || {}).dup
    project_relation_types_all = (plugin_settings["project_relation_types_all"] || {}).dup
    limit_param = params[:relations_limit].to_s
    group_param = params[:relations_group_by_type].to_s
    relation_types_param = Array(params[:relation_types]).reject(&:blank?)

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

    if params.key?(:relation_types)
      update_project_relation_types(project_relation_types, relation_types_param)
      update_project_relation_types_all(project_relation_types_all, params[:relation_types_all])
    end

    plugin_settings = plugin_settings.merge(
      "project_relations_limits" => project_limits,
      "project_relations_group_by_type" => project_groupings,
      "project_relation_types" => project_relation_types,
      "project_relation_types_all" => project_relation_types_all
    )
    Setting.plugin_redmine_issue_view_columns = plugin_settings

    redirect_back(
      fallback_location: url_for(controller: "issue_view_columns", action: "index", project_id: @project),
      notice: l(:label_issue_columns_created_sucessfully)
    )
  end

  def update_relation_types
    plugin_settings = Setting.plugin_redmine_issue_view_columns || {}
    project_relation_types = (plugin_settings["project_relation_types"] || {}).dup
    project_relation_types_all = (plugin_settings["project_relation_types_all"] || {}).dup
    relation_types_param = if params[:project_relation_types].present?
                             relation_types_input = params[:project_relation_types]
                             relation_types_input = relation_types_input.to_unsafe_h if relation_types_input.respond_to?(:to_unsafe_h)
                             Array(relation_types_input[@project.id.to_s]).reject(&:blank?)
                           else
                             []
                           end

    update_project_relation_types(project_relation_types, relation_types_param)
    update_project_relation_types_all(project_relation_types_all, params[:project_relation_types_all])

    plugin_settings = plugin_settings.merge(
      "project_relation_types" => project_relation_types,
      "project_relation_types_all" => project_relation_types_all
    )
    Setting.plugin_redmine_issue_view_columns = plugin_settings

    redirect_back(
      fallback_location: url_for(controller: "issue_view_columns", action: "index", project_id: @project),
      notice: l(:label_issue_columns_created_sucessfully)
    )
  end

  private

  def update_project_relation_types(project_relation_types, relation_types_param)
    if relation_types_param.any?
      project_relation_types[@project.id.to_s] = relation_types_param
    else
      project_relation_types.delete(@project.id.to_s)
    end
  end

  def update_project_relation_types_all(project_relation_types_all, input_param)
    input = input_param
    input = input.to_unsafe_h if input.respond_to?(:to_unsafe_h)
    value = if input.respond_to?(:[])
              input[@project.id.to_s].to_s
            else
              input.to_s
            end
    if value == "1"
      project_relation_types_all[@project.id.to_s] = true
    else
      project_relation_types_all.delete(@project.id.to_s)
    end
  end
end
