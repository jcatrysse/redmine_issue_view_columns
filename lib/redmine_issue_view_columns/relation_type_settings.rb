module RedmineIssueViewColumns
  module RelationTypeSettings
    class << self
      def allowed_relation_types_for(project)
        base_types = RedmineIssueViewColumns::RelationTypes.base_type_keys
        additional_types = additional_relation_type_keys
        selected_additional = if project_relation_types_all?(project)
                                additional_types
                              else
                                project_relation_types(project)
                              end

        selected_additional &= additional_types if selected_additional.any?

        (base_types + selected_additional).uniq
      end

      def project_relation_types(project)
        return [] unless project

        project_types = plugin_settings.fetch("project_relation_types", {})
        Array(project_types[project.id.to_s]).reject(&:blank?).map(&:to_s)
      end

      def project_relation_types_all?(project)
        return false unless project

        project_all = plugin_settings.fetch("project_relation_types_all", {})
        ActiveModel::Type::Boolean.new.cast(project_all[project.id.to_s])
      end

      private

      def plugin_settings
        Setting.plugin_redmine_issue_view_columns || {}
      end

      def additional_relation_type_keys
        base_types = RedmineIssueViewColumns::RelationTypes.base_type_keys
        IssueRelation::TYPES.keys.map(&:to_s) - base_types.map(&:to_s)
      end
    end
  end
end
