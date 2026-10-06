// REST API (README "REST API example"): the registered extra relation types are accepted by
// the core relations API, duplicates per type are refused, and the API keeps its permissions.
// Also: two relates-like types between the same issues (migration 002, unique per type).
import { createRequire } from 'node:module';
import { e2e } from '../../.codex/e2e/lib.mjs';
const { expect, issueId, relations, api } = createRequire(import.meta.url)('./support/ivc.cjs');

const t = await e2e('rest_api');
await t.login('admin');
const parent = await issueId(t, 'IVC parent');
const spare = await issueId(t, 'IVC spare');
const log = [];
async function call(method, path, opts = {}) {
  const r = await api(t, method, path, opts);
  log.push(`${opts.login || 'admin'} ${method} ${path} ${opts.data ? JSON.stringify(opts.data) : ''} -> ${r.status} ${r.body && r.body.errors ? JSON.stringify(r.body.errors) : ''}`);
  return r;
}
for (const r of await relations(t, parent)) {
  if ([r.issue_id, r.issue_to_id].includes(spare)) await api(t, 'DELETE', `/relations/${r.id}.json`);
}

const create = (type, login) => call('POST', `/issues/${parent}/relations.json`,
  { login, data: { relation: { issue_to_id: spare, relation_type: type } } });

let r = await create('relates_to_wiki');
expect(t, r.status === 201 && r.body.relation.relation_type === 'relates_to_wiki', `create relates_to_wiki: ${r.status}`);
const wikiRel = r.body && r.body.relation && r.body.relation.id;
r = await create('relates');
expect(t, r.status === 201, `create relates next to relates_to_wiki between the same issues: ${r.status}`);
const relatesRel = r.body && r.body.relation && r.body.relation.id;
r = await create('relates_to_wiki');
expect(t, r.status === 422, `duplicate relates_to_wiki: ${r.status}, expected 422`);
r = await create('no_such_type');
expect(t, r.status === 422, `unknown relation type: ${r.status}, expected 422`);
r = await create('relates_business', 'reporter');
expect(t, r.status === 403, `reporter creates a relation: ${r.status}, expected 403`);
r = await call('GET', `/issues/${parent}.json?include=relations`, { login: 'reporter' });
expect(t, r.status === 200 && r.body.issue.relations.some(x => x.relation_type === 'relates_to_wiki'),
  'reporter cannot read the relates_to_wiki relation');

await t.go(`/issues/${parent}`);
expect(t, await t.page.locator('#relations tr.ivc-relation-row', { hasText: 'Relates to Wiki' }).count() === 1,
  'the API relation is not shown on the issue page');
await t.shot('api-relations', 'Relations created by the REST API: "Relates to Wiki" and "Related to" between #7 and the spare issue');

r = await call('DELETE', `/relations/${wikiRel}.json`, { login: 'reporter' });
expect(t, r.status === 403, `reporter deletes: ${r.status}, expected 403`);
for (const id of [wikiRel, relatesRel]) {
  r = await call('DELETE', `/relations/${id}.json`);
  expect(t, r.status === 204, `delete relation ${id}: ${r.status}`);
}
console.log(log.join('\n'));
await t.done();
