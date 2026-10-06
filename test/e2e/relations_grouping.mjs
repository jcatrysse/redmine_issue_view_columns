// "Group related issues by relation type" per project: a header row per type, in the order of
// the relation types (core types first, then the extra relates-like types).
import { createRequire } from 'node:module';
import { e2e } from '../../.codex/e2e/lib.mjs';
const { expect, issueId, saveProjectTab } = createRequire(import.meta.url)('./support/ivc.cjs');

const P = 'e2e-project';
const t = await e2e('relations_grouping');
await t.login('admin');
const parent = await issueId(t, 'IVC parent');

await t.login('manager');
await saveProjectTab(t, P, { limit: '', group: true });
await t.go(`/issues/${parent}`);
const headers = await t.page.locator('#relations tr.ivc-relation-group-header').allInnerTexts();
expect(t, JSON.stringify(headers.map(h => h.trim())) === JSON.stringify(['Related to', 'Blocks', 'Relates to (business)']),
  `group headers: ${JSON.stringify(headers)}`);
for (const [type, n] of [['relates', 2], ['blocks', 1], ['relates_business', 1]]) {
  const rows = await t.page.locator(`#relations tr.ivc-relation-row[data-relation-group="${type}"]`).count();
  expect(t, rows === n, `group ${type}: ${rows} rows, expected ${n}`);
}
await t.shot('grouped', 'Grouped: "Related to" (2), "Blocks" (1), "Relates to (business)" (1)');

// the blocked issue sees the reverse type as its group
const blocked = await issueId(t, 'IVC blocked');
await t.go(`/issues/${blocked}`);
expect(t, (await t.page.locator('#relations tr.ivc-relation-group-header').allInnerTexts()).map(h => h.trim()).includes('Blocked by'),
  'blocked issue: no "Blocked by" group');
await t.shot('reverse', 'From the other side the group is the reverse type "Blocked by"');

await saveProjectTab(t, P, { group: false });
await t.go(`/issues/${parent}`);
expect(t, await t.page.locator('#relations tr.ivc-relation-group-header').count() === 0, 'not grouped: headers still shown');
await t.shot('not-grouped', 'Grouping off: one list without headers');

await t.done();
