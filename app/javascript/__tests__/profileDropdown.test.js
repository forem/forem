import '@testing-library/jest-dom';
import { initBlock } from '../profileDropdown/blockButton';
import { initFlag } from '../profileDropdown/flagButton';
import { initSpam } from '../profileDropdown/spamButton';
import { initializeDropdown } from '@utilities/dropdownUtils';


jest.mock('../profileDropdown/blockButton');
jest.mock('../profileDropdown/flagButton');
jest.mock('../profileDropdown/spamButton');
jest.mock('@utilities/dropdownUtils');
// Define global.userData mock
const fakeUser = () => ({
  username: 'user123',
});
global.userData = jest.fn(fakeUser);

describe('initDropdown', () => {
  beforeEach(() => {
    // Setup a basic DOM structure
    document.body.innerHTML = `
      <div class="profile-dropdown" data-username="user456">
        <div class="report-abuse-link-wrapper" data-path="/report-abuse/user456"></div>
      </div>
    `;

    // Reset mocks
    jest.clearAllMocks();
  });

  it('initializes dropdown for other users', () => {
    require('../packs/profileDropdown.js');
    expect(initializeDropdown).toHaveBeenCalledWith({
      triggerElementId: 'user-profile-dropdown',
      dropdownContentId: 'user-profile-dropdownmenu',
    });
    expect(initBlock).toHaveBeenCalled();
    expect(initFlag).toHaveBeenCalled();
    expect(initSpam).toHaveBeenCalled();
  });

  it('does not initialize dropdown for the current user', () => {
    document.querySelector('.profile-dropdown').dataset.username = 'user123'; // Simulate current user
    require('../packs/profileDropdown.js')

    expect(initializeDropdown).not.toHaveBeenCalled();
    expect(initBlock).not.toHaveBeenCalled();
    expect(initFlag).not.toHaveBeenCalled();
    expect(initSpam).not.toHaveBeenCalled();
  });

  it('does not initialize dropdown if already initialized', () => {
    document.querySelector('.profile-dropdown').dataset.dropdownInitialized = 'true';
    require('../packs/profileDropdown.js')

    expect(initializeDropdown).not.toHaveBeenCalled();
  });
});

