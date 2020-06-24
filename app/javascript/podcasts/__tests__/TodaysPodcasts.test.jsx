import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { PodcastEpisode } from '../PodcastEpisode';
import { podcastArticle } from '../../articles/__tests__/utilities/articleUtilities';
import { TodaysPodcasts } from '../TodaysPodcasts';

describe('<TodaysPodcasts /> component', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <TodaysPodcasts>
        <PodcastEpisode episode={podcastArticle} />
        <PodcastEpisode episode={podcastArticle} />
        <PodcastEpisode episode={podcastArticle} />
      </TodaysPodcasts>,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it(`should render a today's podcasts`, () => {
    const { getByText, getAllByTestId } = render(
      <TodaysPodcasts>
        <PodcastEpisode episode={podcastArticle} />
        <PodcastEpisode episode={podcastArticle} />
        <PodcastEpisode episode={podcastArticle} />
      </TodaysPodcasts>,
    );

    expect(getByText("Today's Podcasts").getAttribute('href')).toBe('/pod');
    expect(getAllByTestId('podcast-episode').length).toEqual(3);
  });
});
