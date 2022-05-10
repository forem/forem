import { h } from 'preact';
import { cleanup, render, screen, within } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { PodcastArticle } from '..';
import '@testing-library/jest-dom';

const defaultProps = {
  article: {
    id: 1,
    title: 'article_title',
    podcast: {
      slug: 'podcast_slug',
      image_url: '/',
      title: 'podcast_title',
    },
    path: '/',
  },
};

const setup = (props = defaultProps) => {
  return render(<PodcastArticle {...props} />);
};

describe('<PodcastArticle />', () => {
  beforeEach(() => {
    setup();
  });

  describe('Accessbility check', () => {
    beforeEach(cleanup);
    it('should have no a11y violations', async () => {
      const { container } = render(<PodcastArticle {...defaultProps} />);
      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });
  });

  it('should render podcast image with link', () => {
    expect(
      screen.getByRole('img', { name: defaultProps.article.podcast.title }),
    ).toBeInTheDocument();

    const linkToPodcast = screen.getAllByRole('link', {
      name: defaultProps.article.podcast.title,
    });

    expect(linkToPodcast[0].getAttribute('href')).toStrictEqual(
      `/${defaultProps.article.podcast.slug}`,
    );
  });

  it('should render the article title with podcast tag', () => {
    const name = `podcast ${defaultProps.article.title}`;
    const articleLink = screen.getByRole('link', { name });
    expect(articleLink).toBeInTheDocument();

    const articleTitle = screen.getByRole('heading', { name, level: 3 });
    expect(articleTitle).toBeInTheDocument();
  });

  it('should render podcast title with link', () => {
    const heading = screen.getByRole('heading', {
      name: defaultProps.article.podcast.title,
      level: 4,
    });
    const insideHeading = within(heading);
    const link = insideHeading.getByRole('link');

    expect(heading).toBeInTheDocument();
    expect(link.getAttribute('href')).toStrictEqual(
      `/${defaultProps.article.podcast.slug}`,
    );
  });
});
