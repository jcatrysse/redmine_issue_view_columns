module IssueViewColumnsIssuesHelper
  include IssueViewColumnsHelper
  def render_descendants_tree(issue)
    columns_list = get_fields_for_project(issue)
    # no field defined, then use render from core redmine (or whatever by other plugins loaded before this)
    unless columns_list.count > 0
      return super
    end

    # continue here if there are fields defined
    field_values = ""
    s = +'<table class="list issues odd-even">'
    headers = []

    if respond_to?(:check_box_tag)
      headers << content_tag(:th, check_box_tag('check_all', '', false,
                                             class: 'toggle-selection',
                                             title: "#{l(:button_check_all)} / #{l(:button_uncheck_all)}"),
                             class: 'checkbox hide-when-print')
    else
      headers << '<th class="checkbox hide-when-print"><input type="checkbox" name="check_all" class="toggle-selection" '
                  "title=\"#{I18n.t(:button_check_all)} / #{I18n.t(:button_uncheck_all)}\"></th>"
    end

    headers << content_tag(:th, l(:field_subject), style: 'text-align:left')
    columns_list.each do |column|
      headers << content_tag(:th, column.caption, style: 'text-align:left')
    end
    headers << content_tag(:th, l(:label_actions), style: 'text-align:right') if Redmine::VERSION::MAJOR >= 4

    s << content_tag(:thead, content_tag(:tr, safe_join(headers)))
    # set data
    issue_list(issue.descendants.visible.preload(:status, :priority, :tracker, :assigned_to).sort_by(&:lft)) do |child, level|
      css = "issue issue-#{child.id} hascontextmenu #{child.css_classes}"
      css << " idnt idnt-#{level}" if level > 0
      css << cycle(" odd", " even")

      field_content = content_tag("td", check_box_tag("ids[]", child.id, false, id: nil), class: "checkbox") +
        content_tag("td", link_to_issue(child, project: (issue.project_id != child.project_id)), class: "subject", style: "width: 30%; text-align:left")

      columns_list.each do |column|
        field_content << content_tag("td", column_content(column, child), class: "#{column.css_classes}", style: "text-align:left")
      end

      if (Redmine::VERSION::MAJOR >= 4)
        field_content << content_tag('td', link_to_context_menu, class: 'buttons', style: "text-align:right")
      end

      field_values << content_tag("tr", field_content, class: css).html_safe
    end

    s << field_values
    s << "</table>"
    s.html_safe
  end

  # Renders the list of related issues on the issue details view
  def render_issue_relations(issue, relations)
    columns_list = get_fields_for_project(issue)
    unless columns_list.count > 0
      return super
    end

    manage_relations = User.current.allowed_to?(:manage_issue_relations, issue.project)

    s = +'<table class="list issues odd-even">'
    headers = []

    if respond_to?(:check_box_tag)
      headers << content_tag(:th, check_box_tag('check_all', '', false,
                                             class: 'toggle-selection',
                                             title: "#{l(:button_check_all)} / #{l(:button_uncheck_all)}"),
                             class: 'checkbox hide-when-print')
    else
      headers << '<th class="checkbox hide-when-print"><input type="checkbox" name="check_all" class="toggle-selection" '
                  "title=\"#{I18n.t(:button_check_all)} / #{I18n.t(:button_uncheck_all)}\"></th>"
    end

    headers << content_tag(:th, l(:field_subject), style: 'text-align:left')
    columns_list.each do |column|
      headers << content_tag(:th, column.caption, style: 'text-align:left')
    end
    headers << content_tag(:th, l(:label_actions), style: 'text-align:right') if Redmine::VERSION::MAJOR >= 4

    s << content_tag(:thead, content_tag(:tr, safe_join(headers)))

    relations.each do |relation|
      other_issue = relation.other_issue(issue)
      css = "issue hascontextmenu #{other_issue.css_classes} #{relation.css_classes_for(other_issue)}"
      css << cycle(" odd", " even")
      link = manage_relations ? link_to(l(:label_relation_delete),
                                        relation_path(relation, issue_id: issue.id),
                                        remote: true,
                                        method: :delete,
                                        data: { confirm: l(:text_are_you_sure) },
                                        title: l(:label_relation_delete),
                                        class: "icon-only icon-link-break") : ""

      field_content = content_tag("td", check_box_tag("ids[]", other_issue.id, false, id: nil), class: "checkbox") +
        content_tag("td", relation.to_s(@issue) { |other| link_to_issue(other, project: Setting.cross_project_issue_relations?) }.html_safe, class: "subject", style: "width: 30%; text-align:left")

      columns_list.each do |column|
        field_content << content_tag("td", column_content(column, other_issue), class: "#{column.css_classes}", style: "text-align:left")
      end

      buttons = link
      buttons << link_to_context_menu if Redmine::VERSION::MAJOR >= 4
      field_content << content_tag('td', buttons, {class: 'buttons', style: 'text-align: right'}, false)

      s << content_tag("tr", field_content,
                       id: "relation-#{relation.id}",
                       class: css)
    end

    s << "</table>"
    table_html = s.html_safe

    limit = relations_display_limit_for(issue.project)
    return table_html unless limit && relations.size > limit

    toggle_button = content_tag(:button,
                                l(:label_issue_view_columns_show_more_relations),
                                type: 'button',
                                class: 'ivc-relations-toggle',
                                data: {
                                  collapsed_label: l(:label_issue_view_columns_show_more_relations),
                                  expanded_label: l(:label_issue_view_columns_show_less_relations)
                                })

    content_tag(:div, table_html + toggle_button,
                class: 'ivc-relations-wrapper',
                data: { limit: limit })
  end

  private

  def get_fields_for_project(issue)
    query = IssueQuery.new()
    query.project = issue.project
    available_fields = query.available_inline_columns
    subtask_fields = []

    unless issue.project.module_enabled?(:issue_view_columns)
      all_fields = Setting.plugin_redmine_issue_view_columns["issue_view_default_columns"] || []
    else
      all_fields = IssueViewColumns.all.select { |c| c.project_id == issue.project_id }.sort_by { |o| o.order }.collect { |f| f.ident } || []
    end

    all_fields.each do |field|
      if ["tracker", "subject"].include? field
        next
      end
      proj_field = available_fields.select { |f| f.name.to_s == field }
      subtask_fields << proj_field[0] if proj_field.count > 0
    end
    subtask_fields # this should be an array of QueryColumn
  end
end
