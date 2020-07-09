import { h } from 'preact';
import { articlePropTypes } from '../common-prop-types';

export const PodcastEpisode = ({ episode }) => {
  return (
    <div data-testid="podcast-episode" className="crayons-podcast-episode">
      <a
        href={`/${episode.podcast.slug}/${episode.slug}`}
        className="crayons-podcast-episode__cover"
      >
        <img src={episode.podcast.image_90} alt={episode.title} />
      </a>

      <div>
        <p className="crayons-podcast-episode__author">
          {episode.podcast.title}
        </p>
        <h2 className="crayons-podcast-episode__title crayons-story__title mb-0">
          <a href={`/${episode.podcast.slug}/${episode.slug}`}>
            {episode.title}
          </a>
        </h2>
      </div>
    </div>
  );
};

PodcastEpisode.propTypes = {
  episode: articlePropTypes.isRequired,
};

PodcastEpisode.displayName = 'PodcastEpisode';
