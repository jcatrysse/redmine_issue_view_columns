# frozen_string_literal: true

module IssueViewColumnsContextMenuHelper
  # Redmine 6.0 renamed label_relation_delete to label_relation_remove
  def ivc_relation_remove_label
    ::I18n.t(:label_relation_remove, default: :label_relation_delete)
  end

  # SVG icon with label on Redmine 6+ (sprite_icon); the label alone on 5.1, where icon CSS draws it
  def ivc_icon_with_label(icon, label)
    respond_to?(:sprite_icon) ? sprite_icon(icon, label) : label
  end

  def relates_clique_available?(issues)
    return false if issues.blank? || issues.size < 2
    return false unless issues.all? { |issue| User.current.allowed_to?(:manage_issue_relations, issue.project) }

    issue_ids = issues.map(&:id)
    existing_pairs = IssueRelation.where(
      issue_from_id: issue_ids,
      issue_to_id: issue_ids,
      relation_type: IssueRelation::TYPE_RELATES
    ).pluck(:issue_from_id, :issue_to_id).each_with_object({}) do |pair, memo|
      memo[pair.sort] = true
    end

    missing_pairs = issues.combination(2).filter_map do |issue_from, issue_to|
      pair = [issue_from.id, issue_to.id].sort
      next if existing_pairs[pair]

      [issue_from, issue_to]
    end
    return false if missing_pairs.empty?

    missing_pairs.all? do |issue_from, issue_to|
      relation = IssueRelation.new(
        issue_from: issue_from,
        issue_to: issue_to,
        relation_type: IssueRelation::TYPE_RELATES
      )
      relation.valid?
    end
  end

  def relates_relation_for_context_menu(issues)
    return nil unless issues.size == 2

    issue_ids = issues.map(&:id).sort
    IssueRelation.find_by(
      issue_from_id: issue_ids.first,
      issue_to_id: issue_ids.last,
      relation_type: IssueRelation::TYPE_RELATES
    )
  end
end
