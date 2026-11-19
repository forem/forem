import '@testing-library/jest-dom';

jest.mock('../preactRuntime', () => ({}), { virtual: true });

const mockOrgPageEditor = jest.fn(() => null);
const mockGetCsrfToken = jest.fn(() => 'meta-csrf-token');
const mockGetUserDataAndCsrfToken = jest.fn();

jest.mock('../../orgPageEditor/OrgPageEditor', () => ({
  OrgPageEditor: mockOrgPageEditor,
}));

jest.mock('../../Snackbar', () => ({
  Snackbar: () => null,
}));

jest.mock('@utilities/getUserDataAndCsrfToken', () => ({
  getCsrfToken: mockGetCsrfToken,
  getUserDataAndCsrfToken: mockGetUserDataAndCsrfToken,
}));

describe('orgPageEditor pack', () => {
  beforeEach(() => {
    jest.resetModules();
    mockOrgPageEditor.mockClear();
    mockGetCsrfToken.mockClear();
    mockGetUserDataAndCsrfToken.mockReset();
    document.body.className = '';
    delete document.body.dataset.user;
    document.body.innerHTML = '';
  });

  it('preserves text typed into the fallback textarea before Preact mounts in admin layout', async () => {
    document.body.className = 'admin';
    document.body.innerHTML = `
      <div id="org-page-editor-root"
           data-default-value="Initial server markdown"
           data-textarea-name="page[body_markdown]"
           data-preview-url="/admin/events/1/pages/preview"
           data-placeholder="Write markdown">
        <textarea>Edited while loading</textarea>
      </div>
    `;

    await import('../orgPageEditor');
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(mockGetUserDataAndCsrfToken).not.toHaveBeenCalled();
    expect(mockOrgPageEditor).toHaveBeenCalledWith(
      expect.objectContaining({
        defaultValue: 'Edited while loading',
        textAreaName: 'page[body_markdown]',
        previewUrl: '/admin/events/1/pages/preview',
        placeholder: 'Write markdown',
      }),
      expect.anything(),
    );
  });

  it('falls back cleanly and preserves typed fallback textarea input when user data lookup fails', async () => {
    mockGetUserDataAndCsrfToken.mockRejectedValueOnce(new Error('timeout'));
    document.body.innerHTML = `
      <div id="org-page-editor-root"
           data-default-value="Initial server markdown"
           data-textarea-name="page[body_markdown]"
           data-preview-url="/org/settings/pages/preview">
        <textarea>Draft typed before fallback</textarea>
      </div>
    `;

    await import('../orgPageEditor');
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(mockGetUserDataAndCsrfToken).toHaveBeenCalledTimes(1);
    expect(mockOrgPageEditor).toHaveBeenCalledWith(
      expect.objectContaining({
        defaultValue: 'Draft typed before fallback',
      }),
      expect.anything(),
    );
  });
});
