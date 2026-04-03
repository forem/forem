import { toggleArchived } from '../dashboardDropdowns';

jest.mock('@utilities/dropdownUtils', () => ({
  initializeDropdown: jest.fn().mockReturnValue({ closeDropdown: jest.fn() }),
}));

describe('toggleArchived', () => {
  beforeEach(() => {
    global.InstantClick = {
      preload: jest.fn(),
      display: jest.fn(),
    };
  });

  afterEach(() => {
    delete global.InstantClick;
  });

  it('calls InstantClick.preload with the current page URL', () => {
    toggleArchived();
    expect(global.InstantClick.preload).toHaveBeenCalledWith(window.location.href);
  });

  it('calls InstantClick.display with the current page URL', () => {
    toggleArchived();
    expect(global.InstantClick.display).toHaveBeenCalledWith(window.location.href);
  });
});
