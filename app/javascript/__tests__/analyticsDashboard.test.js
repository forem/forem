/**
 * Regression test for the analytics dashboard org selector. The previous
 * implementation queried `getElementsByClassName('organization')`, but the
 * view renders org tabs as `<a data-organization-id="...">` with no
 * `organization` class. The result was an empty HTMLCollection, the early `else`
 * branch was never taken, and every analytics page (personal AND org) booted
 * with `organizationId: null` — the org dashboards rendered the user's
 * personal stats.
 */

import { getActiveOrganizationId } from '../packs/analyticsDashboard';

function renderNav({ activeOrgId = null, personalActive = false, orgs = [] } = {}) {
  const personalAttrs = personalActive ? 'aria-current="page"' : '';
  const orgItems = orgs
    .map((id) => {
      const isActive = String(id) === String(activeOrgId);
      const attrs = isActive ? 'aria-current="page"' : '';
      return `<li><a href="/dashboard/analytics/org/${id}" data-organization-id="${id}" ${attrs}>Org ${id}</a></li>`;
    })
    .join('');

  document.body.innerHTML = `
    <nav>
      <ul class="analytics-nav">
        <li><a href="/dashboard/analytics" ${personalAttrs}>Your analytics</a></li>
        ${orgItems}
      </ul>
    </nav>
  `;
}

describe('analyticsDashboard.getActiveOrganizationId', () => {
  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('returns null when the personal tab is active', () => {
    renderNav({ personalActive: true, orgs: [42, 99] });

    expect(getActiveOrganizationId()).toBeNull();
  });

  it('returns the data-organization-id of the active org tab', () => {
    renderNav({ activeOrgId: 42, orgs: [42, 99] });

    expect(getActiveOrganizationId()).toBe('42');
  });

  it('returns the active org id even when other org tabs are present', () => {
    renderNav({ activeOrgId: 99, orgs: [42, 99, 7] });

    expect(getActiveOrganizationId()).toBe('99');
  });

  it('returns null when no nav is present (defensive)', () => {
    document.body.innerHTML = '';

    expect(getActiveOrganizationId()).toBeNull();
  });
});
