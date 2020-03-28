import { h } from 'preact';
import render from 'preact-render-to-json';
import { PodcastEpisode } from '../PodcastEpisode';
import { podcastArticle } from '../../articles/__tests__/utilities/articleUtilities';

describe('<PodcastEpisode /> component', () => {
  it('should render a podcast episode', () => {
    const tree = render(<PodcastEpisode episode={podcastArticle} />);
    expect(tree).toMatchSnapshot();
  });
});
