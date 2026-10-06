// Project tab "Issue columns": choose the columns of the subtask and related issue tables,
// the related issues limit and the grouping, per project. Only with manage_issue_view_columns
// and the module enabled; refused to everyone else, also when posted directly.
import { createRequire } from 'node:module';
import { e2e } from '../../.codex/e2e/lib.mjs';
const { expect, issueId, projectId, postForm, saveProjectTab } = createRequire(import.meta.url)('./support/ivc.cjs');

const P = 'e2e-project';
const t = await e2e('project_columns');

await t.login('admin');
const parent = await issueId(t, 'IVC parent');
const projectNo = await projectId(t, P);
const privateNo = await projectId(t, 'e2e-private');

await t.login('manager');
await t.go(`/projects/${P}/settings/issue_view_columns`);
expect(t, await t.page.locator('#list-definition #available_c').isVisible(), 'tab: column selector not shown');
const boxes = await Promise.all(['#available_c', '#selected_c'].map(s => t.page.locator(s).boundingBox()));
expect(t, boxes[0] && boxes[1] && Math.abs(boxes[0].y - boxes[1].y) < 5, 'tab: available and selected columns are not side by side');
await t.shot('tab', 'Project tab "Issue columns" as manager: selector side by side, limit, grouping, Save and a Cancel link');

// add "Due date" and save
await t.page.selectOption('#available_c', 'due_date');
await t.page.click('#tab-content-issue_view_columns button.move-right');
await t.page.click('#tab-content-issue_view_columns input[type=submit][name=commit]');
await t.settle();
t.check('save columns');
expect(t, /Columns updated successfully/.test(await t.page.locator('#flash_notice').innerText().catch(() => '')), 'save: no success notice');
expect(t, await t.page.locator('#selected_c option[value=due_date]').count() === 1, 'save: Due date not among the selected columns');
await t.shot('saved', 'After Save: notice, and Due date is a selected column');

await t.go(`/issues/${parent}`);
expect(t, await t.page.locator('#relations th', { hasText: 'Due date' }).count() === 1, 'issue: no Due date column in related issues');
expect(t, await t.page.locator('#issue_tree th', { hasText: 'Due date' }).count() === 1, 'issue: no Due date column in subtasks');
await t.shot('issue-new-column', 'The issue shows the new Due date column in subtasks and related issues');

// Cancel discards
await t.go(`/projects/${P}/settings/issue_view_columns`);
await t.page.fill('#relations_limit', '9');
await t.page.locator('#tab-content-issue_view_columns a', { hasText: 'Cancel' }).click();
await t.settle();
t.check('cancel');
expect(t, (await t.page.inputValue('#relations_limit')) === '', 'cancel: the limit typed before Cancel was saved');
await t.shot('cancel', 'Cancel leaves the tab without saving: the limit is still empty');

// label toggles its checkbox
await t.page.click('label[for=relations_group_by_type]');
expect(t, await t.page.isChecked('input[type=checkbox]#relations_group_by_type'), 'label click does not toggle the grouping checkbox');

// restore: remove Due date again
await t.go(`/projects/${P}/settings/issue_view_columns`);
await t.page.selectOption('#selected_c', 'due_date');
await t.page.click('#tab-content-issue_view_columns button.move-left');
await t.page.click('#tab-content-issue_view_columns input[type=submit][name=commit]');
await t.settle();
expect(t, await t.page.locator('#selected_c option[value=due_date]').count() === 0, 'restore: Due date still selected');

// refusals
await t.login('reporter');
await t.go(`/projects/${P}/settings`, { status: 403 });
await t.shot('reporter-refused', 'Reporter (no plugin permission, no settings permission): project settings refused');
let status = await postForm(t, '/issue_view_columns', { project_id: projectNo, 'c[]': 'status', relations_limit: '1' });
expect(t, status === 403, `reporter POST /issue_view_columns: HTTP ${status}, expected 403`);
console.log(`reporter POST /issue_view_columns project_id=${projectNo}: HTTP ${status}`);

await t.login('outsider');
await t.go('/projects/e2e-project');
status = await postForm(t, '/issue_view_columns', { project_id: privateNo, 'c[]': 'status' });
expect(t, status === 403, `outsider POST /issue_view_columns for the private project: HTTP ${status}, expected 403`);
console.log(`outsider POST /issue_view_columns project_id=${privateNo} (private): HTTP ${status}`);
status = await postForm(t, '/issue_view_columns/relation_types', { project_id: privateNo, [`project_relation_types_all[${privateNo}]`]: '1' });
expect(t, status === 403, `outsider POST relation_types for the private project: HTTP ${status}, expected 403`);
console.log(`outsider POST /issue_view_columns/relation_types project_id=${privateNo}: HTTP ${status}`);

await t.anonymous();
await t.go('/login');
status = await postForm(t, '/issue_view_columns', { project_id: projectNo, 'c[]': 'status' });
expect(t, status === 302, `anonymous POST /issue_view_columns: HTTP ${status}, expected a redirect to the login`);
console.log(`anonymous POST /issue_view_columns: HTTP ${status}`);

// module off: no columns tab, the relation types tab stays for the administrator
await t.login('admin');
await t.go('/projects/e2e-nomodule/settings');
expect(t, await t.page.locator('#tab-issue_view_columns').count() === 0, 'module off: the Issue columns tab is shown');
await t.shot('module-off', 'Module disabled (e2e-nomodule, admin): no "Issue columns" tab');

// the manager's settings are unchanged by the refused posts
await t.login('manager');
await t.go(`/projects/${P}/settings/issue_view_columns`);
expect(t, (await t.page.inputValue('#relations_limit')) === '', 'refused posts changed the limit');
expect(t, await t.page.locator('#selected_c option').count() === 3, 'refused posts changed the columns');
await t.shot('unchanged', 'After the refused posts the project keeps its 3 columns and no limit');

await t.done();
