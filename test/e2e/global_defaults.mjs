// Plugin settings (Administration > Plugins): default columns, limit and grouping for every
// project without the module. Only administrators reach the page.
import { createRequire } from 'node:module';
import { e2e } from '../../.codex/e2e/lib.mjs';
const { expect, issueId, saveGlobal, visibleRelationRows } = createRequire(import.meta.url)('./support/ivc.cjs');

const t = await e2e('global_defaults');
await t.login('admin');
const np = await issueId(t, 'IVC no module parent');
const parent = await issueId(t, 'IVC parent');

await t.go('/settings/plugin/redmine_issue_view_columns');
const boxes = await Promise.all(['#available_settings_issue_view_default_columns', '#selected_settings_issue_view_default_columns']
  .map(s => t.page.locator(s).boundingBox()));
expect(t, boxes[0] && boxes[1] && Math.abs(boxes[0].y - boxes[1].y) < 5, 'settings: selectors not side by side');
await t.shot('settings', 'Plugin settings: default columns Status, Priority; limit; grouping; extra relation types per project');

await t.go(`/issues/${np}`);
const cols = await t.page.locator('#relations thead th').allInnerTexts();
expect(t, cols.includes('Status') && cols.includes('Priority') && !cols.includes('Assignee'), `module off: columns ${cols}`);
expect(t, await t.page.locator('#relations .ivc-relations-toggle').count() === 0, 'no global limit yet, but a toggle');
await t.shot('defaults', 'Project without the module uses the global columns Status, Priority');

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
