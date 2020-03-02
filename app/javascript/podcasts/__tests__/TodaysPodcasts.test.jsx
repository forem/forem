import { h } from 'preact';
import render from 'preact-render-to-json';
import { PodcastEpisode } from '../PodcastEpisode';
import { podcastArticle } from '../../articles/__tests__/utilities/articleUtilities';
import { TodaysPodcasts } from '../TodaysPodcasts';

describe('<TodaysPodcasts /> component', () => {
  it(`should render a today's podcasts`, () => {
    const tree = render(
      <TodaysPodcasts>
        <PodcastEpisode episode={podcastArticle} />
        <PodcastEpisode episode={podcastArticle} />
        <PodcastEpisode episode={podcastArticle} />
      </TodaysPodcasts>,
    );
    expect(tree).toMatchSnapshot();
  });
});
