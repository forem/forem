import { h } from 'preact';
import PropTypes from 'prop-types';

export const PodcastFeed = ({ podcastItems }) => {
  const podcastItemDivs = podcastItems.map((ep) => (
    <a
      className="individual-podcast-link"
      href={`/${ep.podcast.slug}/${ep.slug}`}
    >
      <img src={ep.podcast.image_90} alt={ep.podcast.title} />
      <div className="individual-podcast-link-details">
        <strong>{ep.title}</strong>
        {ep.podcast.title}
      </div>
    </a>
  ));
  return (
    <div className="single-article single-article-podcast-div">
      <h3>
        <a href="/pod">Today&apos;s Podcasts</a>
      </h3>
      {podcastItemDivs}
    </div>
  );
};

PodcastFeed.propTypes = {
  podcastItems: PropTypes.arrayOf(PropTypes.object).isRequired,
};
