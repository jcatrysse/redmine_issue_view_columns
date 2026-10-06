// Adding and removing a relation on the issue page (AJAX, ca689ee): the related issues block is
// re-rendered with the plugin's table and the "show more" button keeps the right label.
import { createRequire } from 'node:module';
import { e2e } from '../../.codex/e2e/lib.mjs';
const { expect, acceptDialogs, issueId, relations, api, saveProjectTab } = createRequire(import.meta.url)('./support/ivc.cjs');

const P = 'e2e-project';
const t = await e2e('ajax_relations');
await t.login('admin');
const parent = await issueId(t, 'IVC parent');
const spare = await issueId(t, 'IVC spare');
for (const r of await relations(t, parent)) {
  if ([r.issue_id, r.issue_to_id].includes(spare)) await api(t, 'DELETE', `/relations/${r.id}.json`);
}

await t.login('manager');
acceptDialogs(t);
await saveProjectTab(t, P, { limit: 2, group: false });
await t.go(`/issues/${parent}`);
await t.page.click('#relations .contextual a.icon-link-add');
await t.page.selectOption('#relation_relation_type', 'relates');
await t.page.fill('#relation_issue_to_id', String(spare));
await t.page.click('#new-relation-form input[type=submit][name=commit]');
await t.page.waitForSelector('#relations tr.ivc-relation-row:has-text("IVC spare")', { timeout: 10000 })
  .catch(() => t.problems.push('add: the new relation did not appear'));
await t.settle();
t.check('add relation');
const heads = await t.page.locator('#relations thead th').allInnerTexts();
expect(t, heads.includes('Priority') && heads.includes('Action'), `after add: not the plugin table (${heads})`);
expect(t, await t.page.locator('#relations tr.ivc-relation-row').count() === 5, 'after add: expected 5 relation rows');
const toggle = t.page.locator('#relations .ivc-relations-toggle');
expect(t, await toggle.isVisible(), 'after add: the "show more" button is gone');
const label = await toggle.innerText();
const visible = await t.page.locator('#relations tr.ivc-relation-row:visible').count();
expect(t, (visible === 5 && label === 'Show fewer related issues') || (visible === 2 && label === 'Show all related issues'),
  `after add: ${visible} rows visible with label "${label}"`);
await t.shot('added', `Relation added by AJAX: plugin table with 5 rows, ${visible} visible, button "${label}"`);

await t.page.locator('#relations tr.ivc-relation-row', { hasText: 'IVC spare' }).locator('a.icon-link-break').click();
await t.page.waitForSelector('#relations tr.ivc-relation-row:has-text("IVC spare")', { state: 'detached', timeout: 10000 })
  .catch(() => t.problems.push('remove: the relation row is still there'));
await t.settle();
t.check('remove relation');
expect(t, await t.page.locator('#relations tr.ivc-relation-row').count() === 4, 'after remove: expected 4 rows');
expect(t, !(await relations(t, parent)).some(r => [r.issue_id, r.issue_to_id].includes(spare)), 'remove: relation still in the database');
await t.shot('removed', 'Relation removed through the icon (confirmed): row gone, 4 left');

// invalid input: an issue that does not exist (the form stays open after an add)
if (!(await t.page.locator('#new-relation-form').isVisible())) await t.page.click('#relations .contextual a.icon-link-add');
await t.page.fill('#relation_issue_to_id', '999999');
await t.page.click('#new-relation-form input[type=submit][name=commit]');
await t.page.waitForSelector('#relations #errorExplanation, #new-relation-form #errorExplanation', { timeout: 10000 })
  .catch(() => t.problems.push('invalid issue: no error shown'));
t.check('invalid relation');
expect(t, await t.page.locator('#relations tr.ivc-relation-row').count() === 4, 'invalid issue: the table changed');
await t.shot('invalid', 'Relating to #999999: the error is shown, the plugin table stays');

await saveProjectTab(t, P, { limit: '', group: false });
await t.done();
