import { setupCopyOrgSecret } from '../../settings/copyOrgSecret';
import { setupRssFetchTime } from '../../settings/rssFetchTime';
import { setupMobilePageSel } from '../../settings/mobilePageSel';

export function initializeSettings() {
  setupCopyOrgSecret();
  setupRssFetchTime();
  setupMobilePageSel();
}
