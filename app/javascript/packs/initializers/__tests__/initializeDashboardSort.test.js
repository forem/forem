import {
  buildNavigationUrl,
  initializeDashboardSort,
  selectNavigation,
} from '../initializeDashboardSort';

describe('initializeDashboardSort', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div>
        <select id="dashboard_sort">
          <option value="views-desc">Most Views</option>
        </select>
        <select id="dashboard_author">
          <option value="/dashboard">Personal</option>
          <option value="/dashboard/organization/123">Organization</option>
        </select>
        <select id="mobile_nav_dashboard">
          <option value="/dashboard">Posts (1)</option>
          <option value="/dashboard/following">Following</option>
        </select>
      </div>
    `;
    global.InstantClick = {
      preload: jest.fn(),
      display: jest.fn(),
    };
    window.history.pushState({}, '', '/dashboard?show_archived=true&state=status');
  });

  afterEach(() => {
    document.body.innerHTML = '';
    window.history.pushState({}, '', '/dashboard');
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

  test('should not throw when a dashboard navigation select is missing', () => {
    expect(() => selectNavigation('missing_select')).not.toThrow();
  });

  test('should preserve current dashboard query params when building a navigation URL', () => {
    expect(buildNavigationUrl('/dashboard?sort=views-desc')).toContain('sort=views-desc');
    expect(buildNavigationUrl('/dashboard?sort=views-desc')).toContain('show_archived=true');
    expect(buildNavigationUrl('/dashboard?sort=views-desc')).toContain('state=status');
  });

  test('should not overwrite explicit destination query params', () => {
    expect(buildNavigationUrl('/dashboard?sort=created-desc')).toContain('sort=created-desc');
    expect(buildNavigationUrl('/dashboard?sort=created-desc')).not.toContain('sort=views-desc');
  });

  test('should preserve url hash fragments', () => {
    expect(buildNavigationUrl('/dashboard?sort=views-desc#archived')).toContain('#archived');
  });

  test('should return the destination URL unchanged when there are no current query params', () => {
    window.history.pushState({}, '', '/dashboard');
    expect(buildNavigationUrl('/dashboard?sort=views-desc')).toBe('/dashboard?sort=views-desc');
  });

  test('should return a path-relative URL without the origin', () => {
    const result = buildNavigationUrl('/dashboard?sort=views-desc');
    expect(result).toMatch(/^\//);
    expect(result).not.toContain('http');
  });

  test('should keep show_archived when changing dashboard sort', () => {
    const sortSelect = document.getElementById('dashboard_sort');
    selectNavigation('dashboard_sort', '/dashboard?sort=');

    sortSelect.value = 'views-desc';
    sortSelect.dispatchEvent(new Event('change'));

    expect(global.InstantClick.preload).toHaveBeenCalledWith(
      expect.stringContaining('sort=views-desc'),
    );
    expect(global.InstantClick.preload).toHaveBeenCalledWith(
      expect.stringContaining('show_archived=true'),
    );
    expect(global.InstantClick.preload).toHaveBeenCalledWith(
      expect.stringContaining('state=status'),
    );
    expect(global.InstantClick.display).toHaveBeenCalledWith(
      expect.stringContaining('show_archived=true'),
    );
  });

  test('should keep show_archived when changing dashboard author', () => {
    const authorSelect = document.getElementById('dashboard_author');
    selectNavigation('dashboard_author');

    authorSelect.value = '/dashboard/organization/123';
    authorSelect.dispatchEvent(new Event('change'));

    expect(global.InstantClick.preload).toHaveBeenCalledWith(
      expect.stringContaining('/dashboard/organization/123'),
    );
    expect(global.InstantClick.preload).toHaveBeenCalledWith(
      expect.stringContaining('show_archived=true'),
    );
  });

  test('should keep show_archived when changing mobile nav dashboard', () => {
    const navSelect = document.getElementById('mobile_nav_dashboard');
    selectNavigation('mobile_nav_dashboard');

    navSelect.value = '/dashboard/following';
    navSelect.dispatchEvent(new Event('change'));

    expect(global.InstantClick.preload).toHaveBeenCalledWith(
      expect.stringContaining('/dashboard/following'),
    );
    expect(global.InstantClick.preload).toHaveBeenCalledWith(
      expect.stringContaining('show_archived=true'),
    );
  });
});
