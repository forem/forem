import { 
  showModalAfterError, 
  getModal, 
  getModalHtml, 
  buildRateLimitText 
} from "@utilities/showUserAlertModal";


describe('ShowUserAlert Utility', () => {
  it('should return modal html', () => {
    const modalHtml = getModalHtml("Sample text", "Sample Confirm Text");
    expect(modalHtml).toContain('Sample text');
  });
});