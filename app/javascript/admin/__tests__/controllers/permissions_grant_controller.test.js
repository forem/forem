import { Application } from '@hotwired/stimulus';
import PermissionsGrantController from '../../controllers/permissions_grant_controller';

describe('PermissionsGrantController', () => {
  const config = {
    Billboard: {
      resource_type: 'Billboard',
      title: 'Billboard Sub-permissions',
      baseline_hint: 'Always permitted: drafts and takedowns.',
      clauses: [
        {
          key: 'approve',
          label: 'Approve billboards',
          description: 'Mark billboards as approved.',
        },
        {
          key: 'publish',
          label: 'Publish billboards',
          description: 'Set billboards live.',
        },
      ],
    },
  };

  beforeEach(() => {
    document.body.innerHTML = `
      <form
        data-controller="permissions-grant"
        data-permissions-grant-config-value='${JSON.stringify(config)}'
        data-permissions-grant-summary-full-value="Will grant: Full unrestricted access"
        data-permissions-grant-summary-restricted-none-value="Will grant: Restricted — baseline only"
        data-permissions-grant-summary-restricted-count-value="Will grant: Restricted — %{count} of %{total} allowed"
      >
        <select
          data-permissions-grant-target="roleSelect"
          data-action="change->permissions-grant#handleRoleChange"
        >
          <option value="">Select a role...</option>
          <option value="admin">Admin</option>
          <option value="single_resource_admin|Billboard">Billboard Admin</option>
        </select>

        <div hidden data-permissions-grant-target="panel">
          <span data-permissions-grant-target="panelTitle"></span>
          <label data-permissions-grant-target="modeCard" data-restricted="0">
            <input
              type="radio"
              name="restricted"
              value="0"
              checked
              data-permissions-grant-target="modeRadio"
              data-action="change->permissions-grant#syncMode"
            />
          </label>
          <label data-permissions-grant-target="modeCard" data-restricted="1">
            <input
              type="radio"
              name="restricted"
              value="1"
              data-permissions-grant-target="modeRadio"
              data-action="change->permissions-grant#syncMode"
            />
          </label>

          <div hidden data-permissions-grant-target="clausesSection">
            <button type="button" id="preset-none" data-action="click->permissions-grant#selectNone">Draft-only</button>
            <button type="button" id="preset-all" data-action="click->permissions-grant#selectAll">Select all</button>
            <div data-permissions-grant-target="clausesList"></div>
            <p data-permissions-grant-target="baselineHint" hidden></p>
          </div>

          <span data-permissions-grant-target="summary"></span>
        </div>
      </form>
    `;

    const application = Application.start();
    application.register('permissions-grant', PermissionsGrantController);
  });

  it('reveals sub-permissions panel for configurable roles and hides it for others', () => {
    const select = document.querySelector('select');
    const panel = document.querySelector(
      '[data-permissions-grant-target="panel"]',
    );

    expect(panel.hidden).toBe(true);

    select.value = 'single_resource_admin|Billboard';
    select.dispatchEvent(new Event('change'));

    expect(panel.hidden).toBe(false);
    expect(
      document.querySelector('[data-permissions-grant-target="panelTitle"]')
        .textContent,
    ).toBe('Billboard Sub-permissions');
    expect(
      document.querySelectorAll('input[name="allow[]"]').length,
    ).toBe(2);

    select.value = 'admin';
    select.dispatchEvent(new Event('change'));

    expect(panel.hidden).toBe(true);
    expect(document.querySelectorAll('input[name="allow[]"]').length).toBe(0);
  });

  it('toggles clauses section and updates summary when switching modes and presets', () => {
    const select = document.querySelector('select');
    select.value = 'single_resource_admin|Billboard';
    select.dispatchEvent(new Event('change'));

    const restrictedRadio = document.querySelector(
      'input[name="restricted"][value="1"]',
    );
    const clausesSection = document.querySelector(
      '[data-permissions-grant-target="clausesSection"]',
    );
    const summary = document.querySelector(
      '[data-permissions-grant-target="summary"]',
    );

    expect(clausesSection.hidden).toBe(true);
    expect(summary.textContent).toBe('Will grant: Full unrestricted access');

    restrictedRadio.checked = true;
    restrictedRadio.dispatchEvent(new Event('change'));

    expect(clausesSection.hidden).toBe(false);
    expect(summary.textContent).toBe('Will grant: Restricted — baseline only');

    document.getElementById('preset-all').click();
    expect(summary.textContent).toBe(
      'Will grant: Restricted — 2 of 2 allowed',
    );

    document.getElementById('preset-none').click();
    expect(summary.textContent).toBe('Will grant: Restricted — baseline only');
  });
});
