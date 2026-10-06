// Shared steps for the scenarios in test/e2e/*.mjs. A .cjs file, so e2e.sh does not run it
// as a scenario. Data comes from test/e2e/seed.rb; issues are looked up by subject.
const PASSWORD = process.env.RMP_USER_PASSWORD || process.env.RMP_ADMIN_PASSWORD || 'Redmine7Test!';
const ADMIN_PASSWORD = process.env.RMP_ADMIN_PASSWORD || 'Redmine7Test!';

function basic(login) {
  const pw = login === 'admin' ? ADMIN_PASSWORD : PASSWORD;
  return 'Basic ' + Buffer.from(`${login}:${pw}`).toString('base64');
}

// Records a failed expectation; done() then fails the run.
function expect(t, cond, message) {
  if (!cond) t.problems.push(message);
  return !!cond;
}

// Redmine's confirm() dialogs ("Are you sure?") are accepted; call after every login.
function acceptDialogs(t) {
  t.page.on('dialog', d => d.accept().catch(() => {}));
}

// REST call through the browser context, authenticated as `login` with HTTP basic auth.
async function api(t, method, path, { login = 'admin', data } = {}) {
  const res = await t.page.request.fetch(t.BASE + path, {
    method,
    headers: { Authorization: basic(login), 'Content-Type': 'application/json' },
    data: data ? JSON.stringify(data) : undefined,
    failOnStatusCode: false,
  });
  let body = null;
  try { body = await res.json(); } catch { /* empty body */ }
  return { status: res.status(), body };
}

async function issueId(t, subject) {
  const r = await api(t, 'GET', `/issues.json?status_id=*&limit=100&subject=${encodeURIComponent('~' + subject)}`);
  const issue = (r.body && r.body.issues || []).find(i => i.subject === subject);
  if (!issue) throw new Error(`issue "${subject}" not found (seed missing?)`);
  return issue.id;
}

async function projectId(t, identifier) {
  const r = await api(t, 'GET', `/projects/${identifier}.json`);
  return r.body.project.id;
}

async function relations(t, id) {
  const r = await api(t, 'GET', `/issues/${id}/relations.json`);
  return r.body ? r.body.relations : [];
}

// POST to a plugin URL as the logged-in browser user, with the page's CSRF token.
async function postForm(t, path, form) {
  const token = await t.page.locator('meta[name=csrf-token]').getAttribute('content');
  const body = new URLSearchParams({ authenticity_token: token });
  for (const [key, value] of Object.entries(form)) {
    for (const v of [].concat(value)) body.append(key, String(v));
  }
  const res = await t.page.request.post(t.BASE + path, {
    data: body.toString(), headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    maxRedirects: 0, failOnStatusCode: false,
  });
  return res.status();
}

// Project tab "Issue columns" through the form, as the logged-in user.
async function saveProjectTab(t, project, { limit, group }) {
  await t.go(`/projects/${project}/settings/issue_view_columns`);
  const form = t.page.locator('#tab-content-issue_view_columns form');
  if (limit !== undefined) await form.locator('#relations_limit').fill(String(limit));
  if (group !== undefined) await form.locator('input[type=checkbox]#relations_group_by_type').setChecked(group);
  await form.locator('input[type=submit][name=commit]').click();
  await t.settle();
  t.check(`save project tab ${project}`);
  expect(t, await t.page.locator('#flash_notice').count(), `project tab ${project}: no notice after Save`);
}

// Plugin settings page (administrator).
async function saveGlobal(t, { limit, group }) {
  await t.go('/settings/plugin/redmine_issue_view_columns');
  if (limit !== undefined) await t.page.fill('input[name="settings[relations_display_limit]"]', String(limit));
  if (group !== undefined) await t.page.locator('input[type=checkbox][name="settings[relations_group_by_type]"]').setChecked(group);
  await t.page.locator('form[action$="/settings/plugin/redmine_issue_view_columns"] input[type=submit]').click();
  await t.settle();
  t.check('save plugin settings');
}

// Rows of the related issues table that the user can see.
async function visibleRelationRows(t) {
  return t.page.locator('#relations tr.ivc-relation-row:visible').count();
}

module.exports = {
  expect, acceptDialogs, api, issueId, projectId, relations, postForm, saveProjectTab, saveGlobal,
  visibleRelationRows,
};
