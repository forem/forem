jest.mock('@utilities/localDateTime', () => ({
  timestampToLocalDateTime: jest.fn(),
}));
import { timestampToLocalDateTime } from '@utilities/localDateTime';

const importModule = async () => import('../initializeSettings');

describe('initializeSettings Tests', () => {
  describe('OrgSecretCopy Tests', () => {
    let CopyOrgSecret, valueToCopy;
    let copyToClipboardMock;

    const getCopyBtn = () =>
      document.getElementById('settings-org-secret-copy-btn');

    beforeAll(async () => {
      valueToCopy = 'abc123';

      document.body.innerHTML = `
        <input type="text" id="settings-org-secret" value="${valueToCopy}" readonly>
        <button id="settings-org-secret-copy-btn"></button>
        <div id="copy-text-announcer" class="hidden"></div>
      `;

      ({ CopyOrgSecret } = await importModule());
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

      CopyOrgSecret.initialize();
      expect(spyButton).toHaveBeenCalledWith(
        'click',
        CopyOrgSecret.copyToClipboardListener,
      );
    });

    it('after button is clicked, copyToClipboard called + announcer shown', async () => {
      getCopyBtn().click();

      expect(copyToClipboardMock).toHaveBeenCalledWith(valueToCopy);

      await Promise.resolve();
      const announcer = document.getElementById('copy-text-announcer');
      expect(announcer.classList.contains('hidden')).toBe(false);
    });
  });

  describe('RSSFetchTime Tests', () => {
    let RssFetchTime;

    beforeAll(async () => {
      document.body.innerHTML =
        '<time id="rss-fetch-time" datetime="2023-07-10T20:02:16Z"></time>';
      ({ RssFetchTime } = await importModule());
    });

    it('timestampToLocalDateTime is called', () => {
      RssFetchTime.initialize();
      expect(timestampToLocalDateTime).toHaveBeenCalled();
    });
  });

  describe('MobilePageSel Tests', () => {
    let MobilePageSel;

    beforeAll(async () => {
      document.body.innerHTML = '<div id="mobile-page-selector" />';
      ({ MobilePageSel } = await importModule());
    });

    it('attaches onchange listener to mobile page selector', () => {
      const spySel = jest.spyOn(
        document.getElementById('mobile-page-selector'),
        'addEventListener',
      );

      MobilePageSel.initialize();
      expect(spySel).toHaveBeenCalledWith('change', MobilePageSel.listener);
    });
  });
});
