import { h } from 'preact';
import { render } from '@testing-library/preact';
import { PodcastEpisode } from '../PodcastEpisode';
import { podcastArticle } from '../../articles/__tests__/utilities/articleUtilities';
import { TodaysPodcasts } from '../TodaysPodcasts';

describe('<TodaysPodcasts /> component', () => {
  it(`should render a today's podcasts`, () => {
    const { getByText, getByTestId, getAllByTestId } = render(
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
