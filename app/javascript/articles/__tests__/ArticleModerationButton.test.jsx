/* eslint-disable no-irregular-whitespace */
import { h } from 'preact';
import { render } from '@testing-library/preact';
import '@testing-library/jest-dom';
import { Article } from '..';
import { article } from './utilities/articleUtilities';

const commonProps = {
  commentsIcon: '/images/comments-bubble.png',
  videoIcon: '/images/video-camera.svg',
};

describe('<Article /> moderation button', () => {
  it('renders a moderation button for articles when trusted-visible block is present', () => {
    const { container } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        bookmarkClick={jest.fn()}
        article={article}
        currentTag="javascript"
      />,
    );

    const modButton = container.querySelector('.mod-actions-menu-btn');

    expect(modButton).toBeInTheDocument();
    expect(modButton).toHaveAttribute('data-article-path', article.path);
    expect(modButton).toHaveAttribute('aria-label', 'Moderation');
  });
});
