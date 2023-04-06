import { 
  getModalHtml,
} from "@utilities/showUserAlertModal";


describe('ShowUserAlert Utility', () => {
  it('should return modal html', () => {
    const modalHtml = getModalHtml("Sample text", "Sample Confirm Text");
    expect(modalHtml).toContain('Sample text');
  });

  // it('should return the specified modal html', () => {
  //   const modal = getModal("Sample text", "Sample Confirm Text");
  //   const textDiv = modal.querySelector(".color-base-70");
  //   expect(textDiv).toContain('Sample text');
  // });
});