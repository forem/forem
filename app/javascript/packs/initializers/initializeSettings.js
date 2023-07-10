import { timestampToLocalDateTime } from '@utilities/localDateTime';

export class CopyOrgSecret {
  static copyToClipboardListener() {
    const settingsOrgSecretInput = document.getElementById(
      'settings-org-secret',
    );
    if (settingsOrgSecretInput === null) return;

    const { value } = settingsOrgSecretInput;
    return window.Forem.Runtime.copyToClipboard(value).then(() => {
      // Show the confirmation message
      document.getElementById('copy-text-announcer').classList.remove('hidden');
    });
  }

  static initialize() {
    document
      .getElementById('settings-org-secret-copy-btn')
      ?.addEventListener('click', this.copyToClipboardListener);
  }
}

export class RssFetchTime {
  static initialize() {
    // shows RSS fetch time in local time
    const timeNode = document.getElementById('rss-fetch-time');
    if (timeNode) {
      const timeStamp = timeNode.getAttribute('datetime');
      const timeOptions = {
        month: 'long',
        day: 'numeric',
        hour: 'numeric',
        minute: 'numeric',
        second: 'numeric',
      };

      timeNode.textContent = timestampToLocalDateTime(
        timeStamp,
        navigator.language,
        timeOptions,
      );
    }
  }
}

export class MobilePageSel {
  static listener(event) {
    const url = event.target.value;
    InstantClick.preload(url);
    InstantClick.display(url);
  }

  static initialize() {
    document
      .getElementById('mobile-page-selector')
      ?.addEventListener('change', this.listener);
  }
}

export function initializeSettings() {
  CopyOrgSecret.initialize();
  RssFetchTime.initialize();
  MobilePageSel.initialize();
}
