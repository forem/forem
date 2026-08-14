import { h } from 'preact';
import { render } from '@testing-library/preact';
import '@testing-library/jest-dom';
import { MinimalProfilePreviewCard } from '../MinimalProfilePreviewCard';

describe('<MinimalProfilePreviewCard />', () => {
  const defaultProps = {
    triggerId: 'trigger-123',
    contentId: 'content-123',
    username: 'janedoe',
    name: 'Jane Doe',
    profileImage: 'https://example.com/avatar.jpg',
    userId: 42,
    subscriber: 'false',
    communityLeader: 'false',
  };

  it('renders trigger button and dropdown content', () => {
    const { getByRole, getByTestId, getByText } = render(
      <MinimalProfilePreviewCard {...defaultProps} />,
    );

    const trigger = getByRole('button', { name: 'Jane Doe profile details' });
    expect(trigger).toHaveAttribute('id', 'trigger-123');
    expect(trigger).toHaveAttribute('aria-controls', 'content-123');

    const previewCard = getByTestId('profile-preview-card');
    expect(previewCard).toHaveAttribute('id', 'content-123');
    expect(getByText('Jane Doe', { selector: 'span.crayons-subtitle-2' })).toBeInTheDocument();
  });

  it('renders follow button without hardcoded text children to prevent hydration/lifecycle conflicts', () => {
    const { container } = render(
      <MinimalProfilePreviewCard {...defaultProps} />,
    );

    const followButton = container.querySelector('.follow-action-button');
    expect(followButton).toBeInTheDocument();
    expect(followButton).toHaveClass('follow-user', 'w-100', 'c-btn--primary');
    expect(followButton.textContent).toBe('');

    const parsedInfo = JSON.parse(followButton.getAttribute('data-info'));
    expect(parsedInfo).toEqual({
      id: 42,
      className: 'User',
      name: 'Jane Doe',
      style: 'full',
    });
  });

  it('renders subscriber badge when subscriber is true', () => {
    document.body.dataset.subscriptionIcon = '/assets/sub-icon.svg';
    const { container } = render(
      <MinimalProfilePreviewCard {...defaultProps} subscriber="true" />,
    );

    const subIcon = container.querySelector('.subscription-icon');
    expect(subIcon).toBeInTheDocument();
    expect(subIcon).toHaveAttribute('src', '/assets/sub-icon.svg');
    expect(subIcon).toHaveAttribute('alt', 'Subscriber');
  });

  it('renders metadata placeholder with author id', () => {
    const { container } = render(
      <MinimalProfilePreviewCard {...defaultProps} />,
    );

    const metadataPlaceholder = container.querySelector('.author-preview-metadata-container');
    expect(metadataPlaceholder).toBeInTheDocument();
    expect(metadataPlaceholder).toHaveAttribute('data-author-id', '42');
  });
});
