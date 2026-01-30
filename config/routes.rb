# See: http://guides.rubyonrails.org/routing.html
get "issue_view_columns", to: "issue_view_columns#index"
post "issue_view_columns", to: "issue_view_columns#update", as: "update_issue_view_columns"
post "issue_view_columns/relation_types", to: "issue_view_columns#update_relation_types", as: "update_issue_view_columns_relation_types"
post "issue_view_columns/relations", to: "issue_view_columns_relations#create", as: "issue_view_columns_relations"
delete "issue_view_columns/relations/:id", to: "issue_view_columns_relations#destroy", as: "issue_view_columns_relation"
# resources :subtask_columns
