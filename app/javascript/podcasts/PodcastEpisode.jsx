import { h } from 'preact';
import { articlePropTypes } from '../src/components/common-prop-types';

export const PodcastEpisode = ({ episode }) => {
  return (
    <div className="crayons-podcast-episode">
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
        <h2 className="crayons-story__title mb-0">
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
