# Plugin data for the end-to-end scenarios in test/e2e/, run by .codex/start_server.sh after
# the generic seed. Idempotent. Extra relation types come from
# config/redmine_issue_view_columns.local.rb when it exists (copy the .example files).
#
# e2e-project (module issue_view_columns on): columns status, assigned_to, priority;
#   "IVC parent" with two subtasks and four relations (relates x2, blocks, and
#   relates_business when that type is registered); "IVC menu A/B/C" for the context menu.
# e2e-nomodule (module off): falls back to the global default columns of the plugin.

admin = User.find_by!(login: 'admin')
User.current = admin
project = Project.find_by!(identifier: 'e2e-project')
private_project = Project.find_by!(identifier: 'e2e-private')

nomodule = Project.find_by(identifier: 'e2e-nomodule') ||
           Project.new(identifier: 'e2e-nomodule', name: 'E2E without module',
                       description: 'Project without the issue_view_columns module.')
nomodule.is_public = true
nomodule.enabled_module_names = %w[issue_tracking]
nomodule.trackers = Tracker.all
nomodule.save!

IssueViewColumns.where(project_id: project.id).delete_all
%w[status assigned_to priority].each_with_index do |ident, i|
  IssueViewColumns.create!(project_id: project.id, ident: ident, order: i + 1)
end

def ivc_issue(project, subject, attrs = {})
  Issue.find_by(project_id: project.id, subject: subject) ||
    Issue.create!({ project: project, tracker: project.trackers.first, subject: subject,
                    author: User.current, priority: IssuePriority.default || IssuePriority.first }.merge(attrs))
end

def ivc_relate(from, to, type)
  return if IssueRelation.where(issue_from_id: [from.id, to.id], issue_to_id: [from.id, to.id], relation_type: type).exists?

  IssueRelation.create!(issue_from: from, issue_to: to, relation_type: type)
end

parent = ivc_issue(project, 'IVC parent')
ivc_issue(project, 'IVC child one', parent_issue_id: parent.id)
ivc_issue(project, 'IVC child two', parent_issue_id: parent.id, assigned_to: User.find_by(login: 'manager'))
r1 = ivc_issue(project, 'IVC related one')
r2 = ivc_issue(project, 'IVC related two')
r3 = ivc_issue(project, 'IVC blocked')
ivc_relate(parent, r1, 'relates')
ivc_relate(parent, r2, 'relates')
ivc_relate(parent, r3, 'blocks')
ivc_relate(parent, r1, 'relates_business') if IssueRelation::TYPES.key?('relates_business')
ivc_issue(project, 'IVC spare')

%w[A B C].each { |x| ivc_issue(project, "IVC menu #{x}") }

np = ivc_issue(nomodule, 'IVC no module parent')
ivc_relate(np, ivc_issue(nomodule, 'IVC no module related'), 'relates')
ivc_relate(np, ivc_issue(nomodule, 'IVC no module blocked'), 'blocks')

ivc_issue(private_project, 'IVC private issue')

# Plugin settings: a clean start, the global defaults used by e2e-nomodule
Setting.plugin_redmine_issue_view_columns = {
  'issue_view_default_columns' => %w[status priority],
  'relations_display_limit' => '',
  'relations_group_by_type' => '0',
  'project_relations_limits' => {},
  'project_relations_group_by_type' => {},
  'project_relation_types' => {},
  'project_relation_types_all' => {}
}

puts "IVC seed: parent ##{parent.id}, nomodule parent ##{np.id}, " \
     "extra relation types: #{(IssueRelation::TYPES.keys - %w[relates duplicates duplicated blocks blocked precedes follows copied_to copied_from]).join(', ')}"
