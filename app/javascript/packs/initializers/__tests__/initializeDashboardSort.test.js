import { initializeDashboardSort } from '../initializeDashboardSort';

describe('initializeDashboardSort', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div>
        <select id="dashboard_sort" <option value="views-desc">Most Views</option> </select>
        <select id="dashboard_author" <option value="/dashboard">Personal</option> </select>
        <select id="mobile_nav_dashboard" <option value="/dashboard">Posts (1)</option> </select>
      </div>
    `;
  });

  test('should add event listener to dashboard sort select when the element exists', async () => {
    const sortSelect = document.getElementById('dashboard_sort');
    sortSelect.addEventListener = jest.fn();
    initializeDashboardSort();
    expect(sortSelect.addEventListener).toHaveBeenCalled();
  });

  test('should add event listener to dashboard author select when the element exists', async () => {
    const authorSelect = document.getElementById('dashboard_author');
    authorSelect.addEventListener = jest.fn();
    initializeDashboardSort();
    expect(authorSelect.addEventListener).toHaveBeenCalled();
  });

  test('should add event listener to mobile nav dashboard select when the element exists', async () => {
    const navSelect = document.getElementById('mobile_nav_dashboard');
    navSelect.addEventListener = jest.fn();
    initializeDashboardSort();
    expect(navSelect.addEventListener).toHaveBeenCalled();
  });
});
