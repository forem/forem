import { setupCopyOrgSecret, copyToClipboardListener } from '../copyOrgSecret';

describe('OrgSecretCopy Tests', () => {
  let copyToClipboardMock, valueToCopy;

  const getCopyBtn = () =>
    document.getElementById('settings-org-secret-copy-btn');

  beforeAll(async () => {
    valueToCopy = 'abc123';

    document.body.innerHTML = `
      <input type="text" id="settings-org-secret" value="${valueToCopy}" readonly>
      <button id="settings-org-secret-copy-btn"></button>
      <div id="copy-text-announcer" class="hidden"></div>
    `;
  });

  beforeEach(() => {
    // Mock window.Forem.Runtime.copyToClipboard
    copyToClipboardMock = jest.fn().mockResolvedValue({});
    global.window.Forem = {
      Runtime: {
        copyToClipboard: copyToClipboardMock,
      },
    };
  });

  it('attaches listener to button', () => {
    const spyButton = jest.spyOn(getCopyBtn(), 'addEventListener');

    setupCopyOrgSecret();
    expect(spyButton).toHaveBeenCalledWith('click', copyToClipboardListener);
  });

  it('after button is clicked, copyToClipboard called + announcer shown', async () => {
    getCopyBtn().click();

    expect(copyToClipboardMock).toHaveBeenCalledWith(valueToCopy);

    await Promise.resolve();
    const announcer = document.getElementById('copy-text-announcer');
    expect(announcer.classList.contains('hidden')).toBe(false);
  });
});
