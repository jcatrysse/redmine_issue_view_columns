module RedmineIssueViewColumns
  module IssueRelationsHelperPatch
    def collection_for_relation_type_select
      project = @issue&.project || @project
      allowed_types = RedmineIssueViewColumns::RelationTypeSettings.allowed_relation_types_for(project)
      values = IssueRelation::TYPES
      values.keys
            .select { |key| allowed_types.include?(key.to_s) }
            .sort_by { |key| RedmineIssueViewColumns::RelationTypes.sort_key(key) }
            .map { |key| [l(values[key][:name]), key] }
    end
  end
end

IssueRelationsHelper.prepend RedmineIssueViewColumns::IssueRelationsHelperPatch
