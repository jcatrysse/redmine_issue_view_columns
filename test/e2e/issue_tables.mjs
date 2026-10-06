// Subtasks and related issues on the issue page with the project's columns (status, assignee,
// priority): every user who can see the issue gets the columns, only users with
// manage_issue_relations get the "Remove relation" icon; a private issue stays invisible.
import { createRequire } from 'node:module';
import { e2e } from '../../.codex/e2e/lib.mjs';
const { expect, issueId } = createRequire(import.meta.url)('./support/ivc.cjs');

const t = await e2e('issue_tables');

await t.login('admin');
const parent = await issueId(t, 'IVC parent');
const privateIssue = await issueId(t, 'IVC private issue');

async function columns(scope) {
  return t.page.locator(`${scope} thead th`).allInnerTexts();
}

await t.login('manager');
await t.go(`/issues/${parent}`);
const sub = await columns('#issue_tree');
const rel = await columns('#relations');
expect(t, ['Status', 'Assignee', 'Priority'].every(c => sub.includes(c)), `subtasks columns: ${sub}`);
expect(t, ['Status', 'Assignee', 'Priority'].every(c => rel.includes(c)), `related issues columns: ${rel}`);
expect(t, await t.page.locator('#issue_tree tr.issue').count() === 2, 'subtasks: expected 2 rows');
expect(t, await t.page.locator('#relations tr.ivc-relation-row').count() === 4, 'related issues: expected 4 rows');
const remove = t.page.locator('#relations a.icon-link-break[title="Remove relation"]');
expect(t, await remove.count() === 4, 'manager: expected a "Remove relation" link per row');
expect(t, await remove.first().locator('svg use').count() === 1, 'manager: the remove link has no SVG icon');
expect(t, !/translation missing/i.test(await t.page.locator('#relations').innerText()), 'related issues: "translation missing"');
await t.shot('manager', 'Manager: subtasks and related issues with Status, Assignee, Priority; an SVG "Remove relation" icon per relation; two relates-like types between #7 and #10 (unique index per type)');

await t.page.locator('#relations a.icon-link-break').first().hover();
await t.shot('remove-hover', 'Hovering the remove icon highlights it (title "Remove relation", label hidden as in core)', { full: false });

await t.login('reporter');
await t.go(`/issues/${parent}`);
expect(t, (await columns('#relations')).includes('Priority'), 'reporter: related issues without the project columns');
expect(t, await t.page.locator('#relations a.icon-link-break').count() === 0, 'reporter: sees "Remove relation" without manage_issue_relations');
await t.shot('reporter', 'Reporter (no manage_issue_relations): same columns, no remove icons, only the actions menu');

await t.login('outsider');
await t.go(`/issues/${parent}`);
expect(t, (await columns('#relations')).includes('Priority'), 'outsider: public issue without the project columns');
await t.shot('outsider-public', 'Outsider on the public project: columns shown read-only');
await t.go(`/issues/${privateIssue}`, { status: 403 });
await t.shot('outsider-private', 'Outsider: an issue of the private project is refused (403)');

await t.done();
