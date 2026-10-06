require File.expand_path("../../test_helper", __dir__)

class GlobalColumnsTest < ActiveSupport::TestCase
  def setup
    @original_plugin = Setting.plugin_redmine_issue_view_columns
    @original_core = Setting.related_issues_default_columns if core?
  end

  def teardown
    Setting.plugin_redmine_issue_view_columns = @original_plugin
    Setting.related_issues_default_columns = @original_core if core?
  end

  def test_column_names_come_from_core_on_redmine_6_1_and_later
    Setting.plugin_redmine_issue_view_columns = { "issue_view_default_columns" => %w[priority] }
    if core?
      Setting.related_issues_default_columns = %w[status assigned_to]
      assert_equal %w[status assigned_to], RedmineIssueViewColumns::GlobalColumns.column_names
    else
      assert_equal %w[priority], RedmineIssueViewColumns::GlobalColumns.column_names
    end
  end

  def test_copy_plugin_columns_to_core
    Setting.plugin_redmine_issue_view_columns = { "issue_view_default_columns" => %w[tracker priority due_date] }

    copied = RedmineIssueViewColumns::GlobalColumns.copy_plugin_columns_to_core!

    if core?
      assert copied
      assert_equal %w[priority due_date], Setting.related_issues_default_columns
      # kept, for a rollback to an older plugin version
      assert_equal %w[tracker priority due_date], Setting.plugin_redmine_issue_view_columns["issue_view_default_columns"]
    else
      assert_equal false, copied
    end
  end

  def test_copy_without_plugin_columns_leaves_core_alone
    Setting.related_issues_default_columns = %w[status] if core?
    Setting.plugin_redmine_issue_view_columns = { "issue_view_default_columns" => [""] }

    assert_equal false, RedmineIssueViewColumns::GlobalColumns.copy_plugin_columns_to_core!
    assert_equal %w[status], Setting.related_issues_default_columns if core?
  end

  private

  def core?
    RedmineIssueViewColumns::GlobalColumns.core_setting?
  end
end
