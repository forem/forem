import { h } from 'preact';
import { render } from '@testing-library/preact';
import { MinimalProfilePreviewCard } from '../MinimalProfilePreviewCard';

describe('MinimalProfilePreviewCard', () => {
  it('renders the follow button with an initial accessible name', () => {
    const { getByRole } = render(
      <MinimalProfilePreviewCard
        triggerId="profile-preview-card-trigger"
        contentId="profile-preview-card-content"
        username="testuser"
        name="Test User"
        profileImage="https://example.com/avatar.png"
        userId={123}
        subscriber="false"
        communityLeader="false"
      />,
    );

    expect(
      getByRole('button', { name: 'Follow user: Test User' }).textContent,
    ).toBe('Follow');
  });
});
