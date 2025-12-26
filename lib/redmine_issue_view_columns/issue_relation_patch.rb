module RedmineIssueViewColumns
  module IssueRelationPatch
    class << self
      def apply!
        return if @applied

        IssueRelation.prepend RedmineIssueViewColumns::IssueRelationPatch
        configure_validations!
        @applied = true
      end

      def configure_validations!
        validators = IssueRelation._validators[:issue_to_id] || []
        validators.select { |validator| validator.is_a?(ActiveRecord::Validations::UniquenessValidator) }
                  .each do |validator|
          IssueRelation._validators[:issue_to_id].delete(validator)
          IssueRelation.skip_callback(:validate, :before, validator)
        end

        IssueRelation.validate :validate_relation_uniqueness
      end
    end

    def reverse_if_needed
      return if RedmineIssueViewColumns::RelationTypes.relates_like?(relation_type) &&
                relation_type != IssueRelation::TYPE_RELATES

      super
    end

    def circular_dependency?
      if RedmineIssueViewColumns::RelationTypes.relates_like?(relation_type) &&
          relation_type != IssueRelation::TYPE_RELATES
        return false unless issue_from_id && issue_to_id

        return self.class.where(
          issue_from_id: issue_to_id,
          issue_to_id: issue_from_id,
          relation_type: relation_type
        ).present?
      end

      super
    end

    def validate_relation_uniqueness
      return unless issue_from_id && issue_to_id

      from_id = issue_from_id
      to_id = issue_to_id

      if RedmineIssueViewColumns::RelationTypes.relates_like?(relation_type) ||
          relation_type == IssueRelation::TYPE_RELATES
        if from_id > to_id
          from_id, to_id = to_id, from_id
        end
      end

      scope = {
        issue_from_id: from_id,
        issue_to_id: to_id
      }

      if RedmineIssueViewColumns::RelationTypes.relates_like?(relation_type) ||
          relation_type == IssueRelation::TYPE_RELATES
        relation_types = [relation_type, IssueRelation::TYPES.dig(relation_type, :sym)].compact.uniq
        scope[:relation_type] = relation_types
      end

      relation_scope = self.class.where(scope)
      relation_scope = relation_scope.where.not(id: id) if id

      return unless relation_scope.exists?

      if RedmineIssueViewColumns::RelationTypes.relates_like?(relation_type) ||
          relation_type == IssueRelation::TYPE_RELATES
        label_key = IssueRelation::TYPES.dig(relation_type, :name)
        relation_label = label_key ? I18n.t(label_key) : relation_type
        message = I18n.t(
          "redmine_issue_view_columns.relation_already_exists",
          default: "Relation %{relation} to #%{id} already exists",
          relation: relation_label,
          id: issue_to_id
        )
        errors.add(:base, message)
      else
        errors.add(:issue_to_id, :taken)
      end
    end
  end
end
