module RedmineIssueViewColumns
  module RelationTypes
    class << self
      def register!(additional_types, relates_like: [], labels: {})
        return if additional_types.nil? || additional_types.empty?

        register_labels!(labels)
        relates_like_types.concat(relates_like.map(&:to_s))
        relates_like_types.uniq!
        apply_issue_relation_patch!
        register_types!(additional_types)
        refresh_issue_query_relation_filters!
        refresh_relation_type_validator!
      end

      def relates_like?(relation_type)
        relates_like_types.include?(relation_type.to_s)
      end

      def base_type_keys
        (@base_types || IssueRelation::TYPES).keys
      end

      def sort_key(relation_type)
        type = IssueRelation::TYPES[relation_type] || {}
        return [1, type[:ivc_order_index]] if type[:ivc_order_index]

        [0, type[:order] || Float::INFINITY, relation_type.to_s]
      end

      private

      def relates_like_types
        @relates_like_types ||= []
      end

      def apply_issue_relation_patch!
        return if @issue_relation_patch_applied

        require_dependency File.join(__dir__, "issue_relation_patch")
        RedmineIssueViewColumns::IssueRelationPatch.apply!
        @issue_relation_patch_applied = true
      end

      def register_labels!(labels)
        return if labels.nil? || labels.empty?

        labels.each do |locale, translations|
          I18n.backend.store_translations(locale, translations)
        end
      end

      def register_types!(additional_types)
        @base_types ||= IssueRelation::TYPES
        @registered_types ||= {}
        index_offset = @registered_types.length
        additional_types.each_with_index do |(key, value), index|
          entry = value.dup
          entry[:ivc_order_index] ||= index_offset + index
          @registered_types[key] = entry
        end
        new_types = @base_types.merge(@registered_types).freeze
        IssueRelation.send(:remove_const, :TYPES)
        IssueRelation.const_set(:TYPES, new_types)
      end

      def refresh_issue_query_relation_filters!
        return unless defined?(IssueQuery) && IssueQuery.method_defined?(:sql_for_relations)

        IssueRelation::TYPES.each_key do |relation_type|
          method_name = "sql_for_#{relation_type}_field"
          next if IssueQuery.method_defined?(method_name)

          IssueQuery.class_eval do
            alias_method method_name, :sql_for_relations
          end
        end
      end

      def refresh_relation_type_validator!
        validators = IssueRelation._validators[:relation_type] || []
        return if validators.empty?

        validators.each do |validator|
          next unless validator.is_a?(ActiveModel::Validations::InclusionValidator)

          types = IssueRelation::TYPES.keys
          options = validator.options.dup
          options[:in] = types
          validator.instance_variable_set(:@options, options)
          validator.instance_variable_set(:@delimiter, types)
        end
      end
    end
  end
end
