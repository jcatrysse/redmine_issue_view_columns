// "Maximum related issues to display" per project: the rows after the limit are hidden behind
// "Show all related issues", grouped or not; empty, 0 or invalid input shows everything.
import { createRequire } from 'node:module';
import { e2e } from '../../.codex/e2e/lib.mjs';
const { expect, issueId, projectId, postForm, saveProjectTab, visibleRelationRows } = createRequire(import.meta.url)('./support/ivc.cjs');

const P = 'e2e-project';
const t = await e2e('relations_limit');
await t.login('admin');
const parent = await issueId(t, 'IVC parent');
const projectNo = await projectId(t, P);

await t.login('manager');
await saveProjectTab(t, P, { limit: 2, group: false });
await t.shot('setting', 'Project tab: limit 2, not grouped, saved');

await t.go(`/issues/${parent}`);
const toggle = t.page.locator('#relations .ivc-relations-toggle');
expect(t, await t.page.locator('#relations tr.ivc-relation-row').count() === 4, 'expected 4 relation rows');
expect(t, await visibleRelationRows(t) === 2, `collapsed: ${await visibleRelationRows(t)} rows visible, expected 2`);
expect(t, await toggle.isVisible() && (await toggle.innerText()) === 'Show all related issues', 'collapsed: no "Show all related issues" button');
await t.shot('collapsed', 'Limit 2 of 4, not grouped: 2 rows and "Show all related issues"');

await toggle.click();
expect(t, await visibleRelationRows(t) === 4, 'expanded: not all 4 rows visible');
expect(t, (await toggle.innerText()) === 'Show fewer related issues', 'expanded: label is not "Show fewer related issues"');
await t.shot('expanded', 'After the click: all 4 rows and "Show fewer related issues"');
await toggle.click();
expect(t, await visibleRelationRows(t) === 2, 'collapsed again: expected 2 rows');

await saveProjectTab(t, P, { limit: 2, group: true });
await t.go(`/issues/${parent}`);
expect(t, await visibleRelationRows(t) === 2, 'grouped: expected 2 visible rows');
const headers = await t.page.locator('#relations tr.ivc-relation-group-header:visible').allInnerTexts();
expect(t, headers.length >= 1 && headers.length < 3, `grouped and collapsed: headers ${headers}`);
await t.shot('collapsed-grouped', 'Limit 2, grouped: headers of fully hidden groups are hidden too');

// reporter sees the same limit (view only)
await t.login('reporter');
await t.go(`/issues/${parent}`);
expect(t, await visibleRelationRows(t) === 2, 'reporter: limit not applied');
await t.shot('reporter', 'Reporter: the same limit and button');

// invalid input posted directly: no limit stored
await t.login('manager');
await t.go(`/projects/${P}/settings/issue_view_columns`);
for (const value of ['-3', 'abc', '0']) {
  const status = await postForm(t, '/issue_view_columns', { project_id: projectNo, 'c[]': ['status', 'assigned_to', 'priority'], relations_limit: value, relations_group_by_type: '0' });
  expect(t, status === 302, `limit "${value}": HTTP ${status}`);
  await t.go(`/issues/${parent}`);
  expect(t, await t.page.locator('#relations .ivc-relations-toggle').count() === 0 && await visibleRelationRows(t) === 4,
    `limit "${value}": rows are still limited`);
}
await t.shot('invalid-limit', 'Limit "-3", "abc" or "0" posted: stored as no limit, all 4 rows, no button');

await t.go(`/projects/${P}/settings/issue_view_columns`);
await t.page.fill('#relations_limit', '-1');
await t.page.click('#tab-content-issue_view_columns input[type=submit][name=commit]');
const invalid = await t.page.locator('#relations_limit').evaluate(el => !el.checkValidity());
expect(t, invalid, 'the browser accepted a negative limit');
await t.shot('negative-blocked', 'The form refuses a negative limit (min 0) before it is sent');

await saveProjectTab(t, P, { limit: '', group: false });
await t.done();
