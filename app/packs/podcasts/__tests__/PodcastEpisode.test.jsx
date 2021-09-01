import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { PodcastEpisode } from '../PodcastEpisode';
import { podcastArticle } from '../../articles/__tests__/utilities/articleUtilities';

describe('<PodcastEpisode /> component', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<PodcastEpisode episode={podcastArticle} />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render a podcast episode', () => {
    const { getByText, getByAltText } = render(
      <PodcastEpisode episode={podcastArticle} />,
    );

    const imgTag = getByAltText('monitor recontextualize');
    expect(imgTag.getAttribute('src')).toEqual('/images/16.png');
    expect(imgTag.closest('a').getAttribute('href')).toEqual(
      '/monitor-recontextualize/episode-slug',
    );

    getByText('Rubber local');
    const episodeLink = getByText('monitor recontextualize');
    expect(episodeLink.getAttribute('href')).toEqual(
      '/monitor-recontextualize/episode-slug',
    );
  });
});
