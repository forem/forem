import { h } from 'preact';

export const PodcastFeed = ({podcastItems}) => {
  const podcastItemDivs = podcastItems.map(ep => (
    <a class="individual-podcast-link" href={`/${ep.podcast.slug}/${ep.slug}`}>
      <img src={ep.podcast.image_90} /><div class="individual-podcast-link-details"><strong>{ep.title}</strong> {ep.podcast.title}</div>
    </a>
  ));
  return (
    <div class="single-article single-article-podcast-div">
      <h3><a href="/pod">Today's Podcasts</a></h3>
      {podcastItemDivs}
    </div>
  );
};

