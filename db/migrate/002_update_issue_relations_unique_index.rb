class UpdateIssueRelationsUniqueIndex < Rails.version < "5.1" ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def up
    if index_exists?(:issue_relations, [:issue_from_id, :issue_to_id],
                     name: "index_issue_relations_on_issue_from_id_and_issue_to_id")
      remove_index :issue_relations, name: "index_issue_relations_on_issue_from_id_and_issue_to_id"
    end

    unless index_exists?(:issue_relations, [:issue_from_id, :issue_to_id, :relation_type],
                         unique: true,
                         name: "index_issue_relations_on_from_to_type")
      add_index :issue_relations,
                [:issue_from_id, :issue_to_id, :relation_type],
                unique: true,
                name: "index_issue_relations_on_from_to_type"
    end
  end

  def down
    if index_exists?(:issue_relations, [:issue_from_id, :issue_to_id, :relation_type],
                     name: "index_issue_relations_on_from_to_type")
      remove_index :issue_relations, name: "index_issue_relations_on_from_to_type"
    end

    unless index_exists?(:issue_relations, [:issue_from_id, :issue_to_id],
                         unique: true,
                         name: "index_issue_relations_on_issue_from_id_and_issue_to_id")
      add_index :issue_relations,
                [:issue_from_id, :issue_to_id],
                unique: true,
                name: "index_issue_relations_on_issue_from_id_and_issue_to_id"
    end
  end
end
