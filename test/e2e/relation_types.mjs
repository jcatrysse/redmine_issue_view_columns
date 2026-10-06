// Extra relation types (config/redmine_issue_view_columns.local.rb): hidden in "Add relation"
// until selected per project, on the project tab "Relation types" or in the administrator's
// matrix on the plugin settings page; "All relations" selects every extra type.
import { createRequire } from 'node:module';
import { e2e } from '../../.codex/e2e/lib.mjs';
const { expect, acceptDialogs, issueId, projectId, relations, api, postForm } = createRequire(import.meta.url)('./support/ivc.cjs');

const P = 'e2e-project';
const t = await e2e('relation_types');
await t.login('admin');
const parent = await issueId(t, 'IVC parent');
const spare = await issueId(t, 'IVC spare');
const projectNo = await projectId(t, P);
// clean start: no relation between parent and spare
for (const r of await relations(t, parent)) {
  if ([r.issue_id, r.issue_to_id].includes(spare)) await api(t, 'DELETE', `/relations/${r.id}.json`);
}

async function dropdown() {
  await t.go(`/issues/${parent}`);
  return t.page.locator('#relation_relation_type option').evaluateAll(os => os.map(o => o.value));
}

async function saveTab(check) {
  await t.go(`/projects/${P}/settings/issue_view_columns_relations`);
  const form = t.page.locator('#tab-content-issue_view_columns_relations form');
  for (const [value, on] of Object.entries(check)) {
    const box = value === 'all' ? form.locator('input.ivc-check-all-toggle') : form.locator(`input.ivc-relation-checkbox[value="${value}"]`);
    await box.setChecked(on);
  }
  return form;
}

await t.login('manager');
acceptDialogs(t);
let types = await dropdown();
expect(t, types.includes('relates') && !types.some(v => v.startsWith('relates_') || v.endsWith('_wiki')), `default dropdown: ${types}`);
await t.page.click('#relations .contextual a.icon-link-add');
await t.shot('default-dropdown', 'By default "Add relation" offers only the core relation types');

let form = await saveTab({ relates_technical: true });
await t.shot('tab', 'Project tab "Relation types": Relates to (technical) selected');
await form.locator('input[type=submit][name=commit]').click();
await t.settle();
t.check('save relation types');
expect(t, await t.page.locator('#flash_notice').count() === 1, 'relation types: no notice after Save');

types = await dropdown();
expect(t, types.includes('relates_technical') && !types.includes('relates_business'), `after selecting technical: ${types}`);
await t.page.click('#relations .contextual a.icon-link-add');
await t.page.selectOption('#relation_relation_type', 'relates_technical');
await t.page.fill('#relation_issue_to_id', String(spare));
await t.page.click('#new-relation-form input[type=submit][name=commit]');
await t.page.waitForSelector(`#relations tr.ivc-relation-row:has-text("IVC spare")`, { timeout: 10000 }).catch(() => {});
t.check('add technical relation');
expect(t, await t.page.locator('#relations tr.ivc-relation-row', { hasText: 'Relates to (technical)' }).count() === 1,
  'the new "Relates to (technical)" relation is not in the table');
await t.shot('added', 'A "Relates to (technical)" relation added through the form, shown in the plugin table');

// All relations: every extra checkbox checked and locked
form = await saveTab({ all: true });
const locked = await form.locator('input.ivc-relation-checkbox').evaluateAll(bs => bs.every(b => b.checked && b.disabled));
expect(t, locked, '"All relations" does not check and lock the row');
await t.shot('all', '"All relations" checks and locks every extra type');
await form.locator('input[type=submit][name=commit]').click();
await t.settle();
types = await dropdown();
expect(t, ['relates_business', 'relates_technical', 'relates_to_wiki', 'related_from_wiki'].every(v => types.includes(v)), `all: ${types}`);

// the administrator's matrix on the plugin settings page
await t.login('admin');
await t.go('/settings/plugin/redmine_issue_view_columns');
const row = t.page.locator('table.ivc-relation-types-matrix tr', { hasText: 'E2E project' });
expect(t, await row.locator('input.ivc-check-all-toggle').isChecked(), 'matrix: "All relations" of E2E project not shown as checked');
await row.locator('input.ivc-check-all-toggle').setChecked(false);
await row.locator('input.ivc-relation-checkbox').evaluateAll(bs => bs.forEach(b => { b.checked = false; }));
await t.shot('matrix', 'Administrator matrix: E2E project row cleared before Apply');
await t.page.locator('form[action$="/settings/plugin/redmine_issue_view_columns"] input[type=submit]').click();
await t.settle();
t.check('apply matrix');

await t.login('manager');
types = await dropdown();
expect(t, !types.some(v => v.startsWith('relates_') || v.endsWith('_wiki')), `after clearing in the matrix: ${types}`);
// an existing relation of a hidden type stays visible
expect(t, await t.page.locator('#relations tr.ivc-relation-row', { hasText: 'Relates to (technical)' }).count() === 1,
  'hiding the type removed the existing relation from the table');
await t.page.click('#relations .contextual a.icon-link-add');
await t.shot('cleared', 'Types hidden again: the dropdown is back to core, existing relations of that type stay listed');

// refusals
await t.login('reporter');
await t.go(`/projects/${P}/settings/issue_view_columns_relations`, { status: 403 });
const status = await postForm(t, '/issue_view_columns/relation_types', { project_id: projectNo, [`project_relation_types_all[${projectNo}]`]: '1' });
expect(t, status === 403, `reporter POST relation_types: HTTP ${status}`);
console.log(`reporter POST /issue_view_columns/relation_types: HTTP ${status}`);
await t.shot('reporter-refused', 'Reporter: the relation types tab is refused (403), a direct POST too');

await t.login('admin');
for (const r of await relations(t, parent)) {
  if ([r.issue_id, r.issue_to_id].includes(spare)) await api(t, 'DELETE', `/relations/${r.id}.json`);
}
await t.done();
