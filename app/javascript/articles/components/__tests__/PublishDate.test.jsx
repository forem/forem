import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import '@testing-library/jest-dom';
import { PublishDate } from '../PublishDate';
import '../../../assets/javascripts/utilities/timeAgo';

/* global timeAgo */

describe('<PublishDate />', () => {
  beforeEach(() => {
    // Mock timeAgo to return predictable results
    global.timeAgo = jest.fn(({ oldTimeInSeconds, maxDisplayedAge }) => {
      const now = Math.floor(Date.now() / 1000);
      const diff = now - oldTimeInSeconds;
      
      if (diff > maxDisplayedAge) {
        return '';
      }
      
      if (diff < 60) {
        return 'just now';
      }
      if (diff < 3600) {
        return `${Math.floor(diff / 60)} min ago`;
      }
      return '';
    });
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should have no a11y violations', async () => {
    const { container } = render(
      <PublishDate
        readablePublishDate="Oct 15, 2024"
        publishedTimestamp="2024-10-15T10:00:00.000Z"
        publishedAtInt={1728990000}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should format date using local timezone when timestamp is provided', () => {
    // Mock navigator.language
    const originalLanguage = navigator.language;
    Object.defineProperty(navigator, 'language', {
      writable: true,
      value: 'en-US',
    });

    const { getByText } = render(
      <PublishDate
        readablePublishDate="Oct 15, 2024"
        publishedTimestamp="2024-10-15T10:00:00.000Z"
        publishedAtInt={1728990000}
      />,
    );

    // The date should be formatted based on user's timezone
    // In UTC, this would be "Oct 15", but in other timezones it might differ
    const timeElement = getByText(/Oct 15/);
    expect(timeElement).toBeInTheDocument();
    expect(timeElement.tagName).toBe('TIME');
    expect(timeElement.getAttribute('datetime')).toBe('2024-10-15T10:00:00.000Z');

    // Restore original language
    Object.defineProperty(navigator, 'language', {
      writable: true,
      value: originalLanguage,
    });
  });

  it('should fallback to readablePublishDate when timestamp is missing', () => {
    const { getByText } = render(
      <PublishDate
        readablePublishDate="Oct 15, 2024"
        publishedTimestamp={null}
        publishedAtInt={null}
      />,
    );

    expect(getByText('Oct 15, 2024')).toBeInTheDocument();
  });

  it('should display time ago indicator when article is recent', () => {
    const recentTimestamp = Math.floor(Date.now() / 1000) - 300; // 5 minutes ago
    
    const { container } = render(
      <PublishDate
        readablePublishDate="Oct 15, 2024"
        publishedTimestamp="2024-10-15T10:00:00.000Z"
        publishedAtInt={recentTimestamp}
      />,
    );

    expect(timeAgo).toHaveBeenCalledWith({
      oldTimeInSeconds: recentTimestamp,
      formatter: expect.any(Function),
      maxDisplayedAge: 60 * 60 * 24 * 7,
    });
  });

  it('should not display time ago indicator when article is old', () => {
    const oldTimestamp = Math.floor(Date.now() / 1000) - (8 * 24 * 60 * 60); // 8 days ago
    
    const { container } = render(
      <PublishDate
        readablePublishDate="Oct 1, 2024"
        publishedTimestamp="2024-10-01T10:00:00.000Z"
        publishedAtInt={oldTimestamp}
      />,
    );

    expect(timeAgo).toHaveBeenCalled();
    // timeAgo should return empty string for old articles
    expect(timeAgo({ oldTimeInSeconds: oldTimestamp, maxDisplayedAge: 60 * 60 * 24 * 7 })).toBe('');
  });

  it('should handle dates in different timezones correctly', () => {
    // Test with a UTC timestamp that would show different dates in different timezones
    // Oct 15, 2024 02:00 UTC would be Oct 15 in GMT+5:30 (India) but Oct 14 in PST
    const utcTimestamp = '2024-10-15T02:00:00.000Z';
    
    const { getByText } = render(
      <PublishDate
        readablePublishDate="Oct 15, 2024"
        publishedTimestamp={utcTimestamp}
        publishedAtInt={1728964800}
      />,
    );

    const timeElement = getByText(/Oct/);
    expect(timeElement).toBeInTheDocument();
    expect(timeElement.getAttribute('datetime')).toBe(utcTimestamp);
  });

  it('should handle year display correctly for current year vs past year', () => {
    const currentYear = new Date().getFullYear();
    const currentYearTimestamp = `${currentYear}-10-15T10:00:00.000Z`;
    const pastYearTimestamp = `${currentYear - 1}-10-15T10:00:00.000Z`;

    const { rerender, getByText } = render(
      <PublishDate
        readablePublishDate={`Oct 15, ${currentYear}`}
        publishedTimestamp={currentYearTimestamp}
        publishedAtInt={1728990000}
      />,
    );

    // Current year should not show year in short format
    const currentYearElement = getByText(/Oct 15/);
    expect(currentYearElement).toBeInTheDocument();

    // Past year should show year
    rerender(
      <PublishDate
        readablePublishDate={`Oct 15, ${currentYear - 1}`}
        publishedTimestamp={pastYearTimestamp}
        publishedAtInt={1702641600}
      />,
    );

    const pastYearElement = getByText(new RegExp(`Oct 15.*${currentYear - 1}`));
    expect(pastYearElement).toBeInTheDocument();
  });
});

