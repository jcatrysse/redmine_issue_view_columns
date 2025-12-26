# Redmine Issue View Columns Plugin

Redmine plugin to customize shown columns in subtasks and related issues on issue page

![screenshot](https://github.com/jcatrysse/redmine_issue_view_columns/doc/screenshot.png)

Basic functionality
-------------------

* Provide configurable list of columns that are shown for subtasks list in issue view
* Provide configurable list of columns that are shown for related issues in issue view
* Configuration is possible per project
* There is a possibility to define global configuration in admin area. Global configuration is then applied to all projects that don't have the plugin module activated.
* Subject and tracker columns are not configurable by this plugin. This information is always shown, as this is the default behavior of these sections in Redmine
* Related issues contain an icon that is used to remove the relation from corresponding ticket. This icon is always shown as the last column on the right side of the related issues table
* Limit the number of related issues shown at once with a configurable "show more" toggle (global default and per-project overrides)
* Group related issues by relation type with global and per-project configuration
* Same configuration is applied to both subtasks and related issues sections
* Extend the available relation types via the plugin initializer (see below)

Compatibility
-------------

Plugin is compatible with Redmine 5.0.x on MySQL 8.x.x. Newer or older versions may work but have not been tested yet.

Installation
------------

* Clone https://github.com/jcatrysse/redmine_issue_view_columns or download zip to **redmine_dir/plugins/** folder
```
$ git clone https://github.com/jcatrysse/redmine_issue_view_columns.git
```
* From redmine root directory, run:
```
$ RAILS_ENV=production bundle exec rake redmine:plugins:migrate NAME=redmine_issue_view_columns
```
* This migration updates the unique index on `issue_relations` so multiple relates-like relation types can exist between the same issues while still preventing duplicates per relation type.
* Restart redmine

Relation types
--------------

This plugin can extend Redmine's built-in issue relation types (e.g., "relates", "blocks") with additional
"relates-like" relations. These are configured in `init.rb` and are loaded at startup, so Redmine must be restarted
after changes.

Example:

* `relates_business` → "Relates to (business)"
* `relates_technical` → "Relates to (technical)"

By default, no extra relation types are registered. To add or rename relation types, create a local config file at
`config/redmine_issue_view_columns.local.rb` (see the example file below). For update-proof translations, load a
separate locale file outside the plugin and keep labels in that YAML file instead of inline in the config.

Local config file
-----------------

Copy the example file below to `config/redmine_issue_view_columns.local.rb` and adjust it to fit your needs. The
`config/redmine_issue_view_columns.local.rb` file is ignored by git so it won't be overwritten by plugin updates.

The example shows how to load a custom locale file outside the plugin so updates won't overwrite your translations.
Start from `config/redmine_issue_view_columns.locales.yml.example`, copy it outside the plugin, and point the
`custom_locales_path` setting at that file.

RelationTypes should be no more than 30 characters!

- Example: `config/redmine_issue_view_columns.local.rb.example`

Example snippet:

```ruby
custom_locales_path = "/etc/redmine/redmine_issue_view_columns_locales.yml"
I18n.load_path << custom_locales_path if File.exist?(custom_locales_path)

RedmineIssueViewColumns::RelationTypes.register!(
  {
    "relates_business" => {
      name: :label_relates_to_business,
      sym_name: :label_relates_to_business,
      order: 1.1,
      sym: "relates_business"
    },
    "relates_technical" => {
      name: :label_relates_to_technical,
      sym_name: :label_relates_to_technical,
      order: 1.2,
      sym: "relates_technical"
    },
    "relates_to_wiki" => {
      name: :label_relates_to_wiki,
      sym_name: :label_related_from_wiki,
      order: 1.3,
      sym: "related_from_wiki"
    },
    "related_from_wiki" => {
      name: :label_related_from_wiki,
      sym_name: :label_relates_to_wiki,
      order: 1.4,
      sym: "relates_to_wiki"
    }
  },
  relates_like: %w[relates_business relates_technical relates_to_wiki related_from_wiki]
)

```

Example locale file (`/etc/redmine/redmine_issue_view_columns_locales.yml`):

```yaml
en:
  label_relates_to_business: "Relates to (business)"
  label_relates_to_technical: "Relates to (technical)"
  label_relates_to_wiki: "Relates to Wiki"
  label_related_from_wiki: "Related from Wiki"
```

REST API example
----------------

Once the plugin is loaded (and Redmine restarted), the standard Redmine relations REST API accepts the new
`relation_type` values because they are registered in `IssueRelation::TYPES`.

Example `curl` request:

```
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Redmine-API-Key: YOUR_API_KEY" \
  -d '{
    "relation": {
      "issue_to_id": 1234,
      "relation_type": "relates_business"
    }
  }' \
  https://redmine.example.com/issues/5678/relations.json
```

Testing
-------

From your Redmine root directory, run:

```
RAILS_ENV=test bundle exec rake redmine:plugins:test NAME=redmine_issue_view_columns
```

Credits
-------

Plugin is inspired by http://www.redmine.org/plugins/subtaskcolumns and http://www.redmine.org/plugins/subtask_list_columns
Original author: Kenan Dervišević
