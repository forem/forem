import { h } from 'preact';
import { articlePropTypes } from '../src/components/common-prop-types';

export const PodcastEpisode = ({ episode }) => {
  return (
    <a
      className="individual-podcast-link"
      href={`/${episode.podcast.slug}/${episode.slug}`}
    >
      <img src={episode.podcast.image_90} alt={episode.title} />
      <div className="individual-podcast-link-details">
        <strong>{episode.title}</strong> 
        {' '}
        {episode.podcast.title}
      </div>
    </a>
  );
};

PodcastEpisode.propTypes = {
  episode: articlePropTypes.isRequired,
};

PodcastEpisode.displayName = 'PodcastEpisode';
