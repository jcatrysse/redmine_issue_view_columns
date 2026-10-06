// Issue list context menu: "Related to" relates every selected issue with every other one
// (missing pairs only); "Remove relation" removes the "relates" relation between two selected
// issues. Only with manage_issue_relations on all of them.
import { createRequire } from 'node:module';
import { e2e } from '../../.codex/e2e/lib.mjs';
const { expect, acceptDialogs, issueId, relations, api, postForm } = createRequire(import.meta.url)('./support/ivc.cjs');

const P = 'e2e-project';
const t = await e2e('context_menu');
await t.login('admin');
const ids = { A: await issueId(t, 'IVC menu A'), B: await issueId(t, 'IVC menu B'), C: await issueId(t, 'IVC menu C') };
const all = Object.values(ids);

async function relatesAmong() {
  const seen = new Map();
  for (const id of all) {
    for (const r of await relations(t, id)) {
      if (r.relation_type === 'relates' && all.includes(r.issue_id) && all.includes(r.issue_to_id)) seen.set(r.id, r);
    }
  }
  return [...seen.values()];
}
for (const r of await relatesAmong()) await api(t, 'DELETE', `/relations/${r.id}.json`);

const list = `/projects/${P}/issues?set_filter=1&f[]=subject&op[subject]=~&v[subject][]=IVC+menu&sort=id`;
async function openMenu(keys) {
  await t.go(list);
  for (const k of keys) await t.page.locator(`tr#issue-${ids[k]} td.checkbox input`).check();
  await t.page.locator(`tr#issue-${ids[keys[0]]} td.status`).click({ button: 'right' });
  await t.page.waitForSelector('#context-menu ul', { timeout: 10000 }).catch(() => t.problems.push('context menu did not open'));
  return t.page.locator('#context-menu');
}

await t.login('manager');
acceptDialogs(t);
let menu = await openMenu(['A', 'B', 'C']);
const relate = menu.locator('a', { hasText: 'Related to' });
expect(t, await relate.count() === 1, 'A+B+C: no "Related to" entry');
expect(t, await relate.locator('svg use').count() === 1, '"Related to" has no icon');
expect(t, await menu.locator('a', { hasText: 'Remove relation' }).count() === 0, 'A+B+C: "Remove relation" offered for three issues');
await t.shot('relate-three', 'Three unrelated issues selected: "Related to" with its link icon', { full: false });
await relate.click();
await t.settle();
t.check('relate three');
let rels = await relatesAmong();
expect(t, rels.length === 3, `after "Related to": ${rels.length} relates relations among A, B, C, expected 3`);
await t.shot('related', `After the click the list is shown again; A, B and C are related pairwise (${rels.length} relations)`);

menu = await openMenu(['A', 'B', 'C']);
expect(t, await menu.locator('a', { hasText: 'Related to' }).count() === 0, 'all pairs related: "Related to" still offered');
await t.shot('nothing-missing', 'Every pair already related: "Related to" is not offered again', { full: false });

menu = await openMenu(['A', 'B']);
const remove = menu.locator('a', { hasText: 'Remove relation' });
expect(t, await remove.count() === 1 && await remove.locator('svg use').count() === 1, 'A+B: no "Remove relation" with icon');
expect(t, !/translation missing/i.test(await menu.innerText()), 'context menu: "translation missing"');
await t.shot('remove-offered', 'Two related issues: "Remove relation" with its icon', { full: false });
await remove.click();
await t.settle();
t.check('remove relation');
rels = await relatesAmong();
expect(t, rels.length === 2, `after "Remove relation": ${rels.length} relations, expected 2`);

menu = await openMenu(['A', 'B']);
expect(t, await menu.locator('a', { hasText: 'Related to' }).count() === 1, 'A+B unrelated again: "Related to" not offered');
await t.shot('relate-again', 'After removing, A and B can be related again', { full: false });

// without manage_issue_relations
await t.login('reporter');
menu = await openMenu(['A', 'B']);
expect(t, await menu.locator('a', { hasText: 'Related to' }).count() === 0, 'reporter: "Related to" offered');
expect(t, await menu.locator('a', { hasText: 'Remove relation' }).count() === 0, 'reporter: "Remove relation" offered');
await t.shot('reporter', 'Reporter (no manage_issue_relations): neither entry in the menu', { full: false });
let status = await postForm(t, `/issue_view_columns/relations?ids[]=${ids.A}&ids[]=${ids.B}`, {});
expect(t, status === 403, `reporter POST /issue_view_columns/relations: HTTP ${status}`);
const relId = rels[0].id;
const token = await t.page.locator('meta[name=csrf-token]').getAttribute('content');
const del = await t.page.request.delete(`${t.BASE}/issue_view_columns/relations/${relId}`, {
  headers: { 'X-CSRF-Token': token }, maxRedirects: 0, failOnStatusCode: false });
expect(t, del.status() === 403, `reporter DELETE /issue_view_columns/relations/${relId}: HTTP ${del.status()}`);
console.log(`reporter POST relations: HTTP ${status}; reporter DELETE relation ${relId}: HTTP ${del.status()}`);
expect(t, (await relatesAmong()).length === 2, 'reporter changed the relations');

// a private issue is not found for an outsider
await t.login('outsider');
await t.go('/projects/e2e-project');
const priv = await (async () => { await t.login('admin'); return issueId(t, 'IVC private issue'); })();
await t.login('outsider');
await t.go('/projects/e2e-project');
status = await postForm(t, `/issue_view_columns/relations?ids[]=${priv}&ids[]=${ids.A}`, {});
expect(t, status === 404 || status === 403, `outsider relating a private issue: HTTP ${status}`);
console.log(`outsider POST relations with a private issue: HTTP ${status}`);

await t.login('admin');
for (const r of await relatesAmong()) await api(t, 'DELETE', `/relations/${r.id}.json`);
await t.done();
