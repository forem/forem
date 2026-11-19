import { Application } from '@hotwired/stimulus';
import SubPermissionsEditorController from '../../controllers/sub_permissions_editor_controller';

describe('SubPermissionsEditorController', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <details
        open
        data-controller="sub-permissions-editor"
        data-sub-permissions-editor-summary-none-value="0 of %{total} selected"
        data-sub-permissions-editor-summary-count-value="%{count} of %{total} selected"
        data-sub-permissions-editor-full-access-summary-value="Full Billboard access"
      >
        <summary>Configure</summary>
        <form data-sub-permissions-editor-target="form">
          <label data-sub-permissions-editor-target="modeCard" data-restricted="0">
            <input
              type="radio"
              name="restricted"
              value="0"
              checked
              data-sub-permissions-editor-target="modeRadio"
              data-action="change->sub-permissions-editor#syncMode"
            />
          </label>
          <label data-sub-permissions-editor-target="modeCard" data-restricted="1">
            <input
              type="radio"
              name="restricted"
              value="1"
              data-sub-permissions-editor-target="modeRadio"
              data-action="change->sub-permissions-editor#syncMode"
            />
          </label>

          <div data-sub-permissions-editor-target="clausesSection">
            <button
              type="button"
              id="btn-none"
              data-sub-permissions-editor-target="presetButton"
              data-action="click->sub-permissions-editor#selectNone"
            >Draft-only</button>
            <button
              type="button"
              id="btn-all"
              data-sub-permissions-editor-target="presetButton"
              data-action="click->sub-permissions-editor#selectAll"
            >Select all</button>
            <input
              type="checkbox"
              name="allow[]"
              value="approve"
              data-sub-permissions-editor-target="clauseCheckbox"
              data-action="change->sub-permissions-editor#updateSummary"
            />
            <input
              type="checkbox"
              name="allow[]"
              value="publish"
              data-sub-permissions-editor-target="clauseCheckbox"
              data-action="change->sub-permissions-editor#updateSummary"
            />
          </div>

          <span data-sub-permissions-editor-target="summary"></span>
          <button
            type="button"
            id="btn-cancel"
            data-action="click->sub-permissions-editor#cancel"
          >Cancel</button>
        </form>
      </details>
    `;

    const application = Application.start();
    application.register(
      'sub-permissions-editor',
      SubPermissionsEditorController,
    );
  });

  it('disables clause checkboxes in full access mode and enables them in restricted mode', () => {
    const checkboxes = document.querySelectorAll('input[name="allow[]"]');
    const restrictedRadio = document.querySelector(
      'input[name="restricted"][value="1"]',
    );
    const summary = document.querySelector(
      '[data-sub-permissions-editor-target="summary"]',
    );

    expect(checkboxes[0].disabled).toBe(true);
    expect(summary.textContent).toBe('Full Billboard access');

    restrictedRadio.checked = true;
    restrictedRadio.dispatchEvent(new Event('change'));

    expect(checkboxes[0].disabled).toBe(false);
    expect(summary.textContent).toBe('0 of 2 selected');

    checkboxes[1].checked = true;
    checkboxes[1].dispatchEvent(new Event('change'));
    expect(summary.textContent).toBe('1 of 2 selected');
  });

  it('resets unsaved changes and closes details on cancel', () => {
    const details = document.querySelector('details');
    const restrictedRadio = document.querySelector(
      'input[name="restricted"][value="1"]',
    );
    const checkboxes = document.querySelectorAll('input[name="allow[]"]');

    restrictedRadio.checked = true;
    restrictedRadio.dispatchEvent(new Event('change'));
    document.getElementById('btn-all').click();
    expect(checkboxes[0].checked).toBe(true);

    document.getElementById('btn-cancel').click();
    expect(details.open).toBe(false);
    expect(checkboxes[0].checked).toBe(false);
    expect(checkboxes[0].disabled).toBe(true);
  });
});
