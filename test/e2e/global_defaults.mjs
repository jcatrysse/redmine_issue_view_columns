// Global settings for projects without columns of their own. Redmine 6.1+: the columns come from
// core's "Related and sub issues list defaults" (Administration > Settings > Issue tracking), the
// plugin settings page links there and keeps the global limit and grouping. Core's "display table
// headers" setting also drives the plugin's tables. Only administrators reach either page.
import { createRequire } from 'node:module';
import { e2e } from '../../.codex/e2e/lib.mjs';
const { expect, issueId, saveGlobal, visibleRelationRows } = createRequire(import.meta.url)('./support/ivc.cjs');

const t = await e2e('global_defaults');
await t.login('admin');
const np = await issueId(t, 'IVC no module parent');
const parent = await issueId(t, 'IVC parent');

async function coreIssueSettings({ add, remove, headers }) {
  await t.go('/settings?tab=issues');
  await t.sudo();
  const tab = t.page.locator('#tab-content-issues');
  // core's own moveOptions(), what the arrow buttons next to the lists call
  const move = (from, to) => t.page.evaluate(([f, d]) => moveOptions(document.getElementById(f), document.getElementById(d)), [from, to]);
  if (add) {
    await tab.locator('#available_settings_related_issues_default_columns').selectOption(add);
    await move('available_settings_related_issues_default_columns', 'selected_settings_related_issues_default_columns');
  }
  if (remove) {
    await tab.locator('#selected_settings_related_issues_default_columns').selectOption(remove);
    await move('selected_settings_related_issues_default_columns', 'available_settings_related_issues_default_columns');
  }
  if (headers !== undefined) {
    await tab.locator('input[type=checkbox][name="settings[display_related_issues_table_headers]"]').setChecked(headers);
  }
  await tab.locator('input[type=submit][name=commit]').click();
  await t.settle();
  t.check('save core issue settings');
}

await t.go('/settings/plugin/redmine_issue_view_columns');
const link = t.page.locator('p.ivc-core-columns a');
expect(t, await link.count() === 1 && /tab=issues/.test(await link.getAttribute('href')), 'plugin settings: no link to core issue settings');
expect(t, await t.page.locator('#selected_settings_issue_view_default_columns').count() === 0, 'plugin settings: still its own column selector');
await t.shot('settings', 'Plugin settings: columns now link to core\'s issue tracking settings; limit, grouping and relation types stay here');

await t.go(`/issues/${np}`);
let cols = await t.page.locator('#relations thead th').allInnerTexts();
expect(t, cols.includes('Status') && cols.includes('Priority') && !cols.includes('Assignee'), `module off: columns ${cols}`);
expect(t, await t.page.locator('#relations tr.ivc-relation-row').count() === 2, 'module off: not the plugin table');
await t.shot('defaults', 'Project without the module: the plugin table with core\'s columns Status, Priority');

await coreIssueSettings({ add: 'assigned_to' });
await t.shot('core-columns', 'Core setting "Related and sub issues list defaults" with Assignee added (Administration > Settings > Issue tracking)', { full: true });
await t.go(`/issues/${np}`);
cols = await t.page.locator('#relations thead th').allInnerTexts();
expect(t, cols.includes('Assignee'), `after adding Assignee in core's setting: ${cols}`);
await t.shot('core-columns-applied', 'The project without the module follows core\'s setting: Assignee column added');

await coreIssueSettings({ headers: false });
await t.go(`/issues/${np}`);
expect(t, await t.page.locator('#relations table thead').count() === 0, 'headers off: the plugin table still has a header row');
expect(t, await t.page.locator('#relations tr.ivc-relation-row').count() === 2, 'headers off: rows missing');
await t.shot('headers-off', 'Core "Display table headers" off: the plugin table has no header row, like core\'s');
await coreIssueSettings({ remove: 'assigned_to', headers: true });

await saveGlobal(t, { limit: 1, group: true });
expect(t, await t.page.locator('#flash_notice').count() === 1, 'plugin settings: no notice after Apply');
await t.go(`/issues/${np}`);
expect(t, await visibleRelationRows(t) === 1, `global limit 1: ${await visibleRelationRows(t)} rows visible`);
expect(t, await t.page.locator('#relations tr.ivc-relation-group-header').count() === 2, 'global grouping: expected 2 headers');
await t.shot('global-limit-grouped', 'Global limit 1 and grouping: one row, the "Show all" button, headers per type');

// a project with the module keeps its own settings (no limit, not grouped)
await t.go(`/issues/${parent}`);
expect(t, await visibleRelationRows(t) === 4 && await t.page.locator('#relations tr.ivc-relation-group-header').count() === 0,
  'project with the module follows the global limit or grouping');
await t.shot('project-overrides', 'A project with the module keeps its own settings: 4 rows, not grouped');

await t.login('manager');
await t.go('/settings/plugin/redmine_issue_view_columns', { status: 403 });
await t.shot('manager-refused', 'A non-administrator cannot open the plugin settings (403)');

await t.login('admin');
await saveGlobal(t, { limit: '', group: false });
await t.done();
