import { h } from 'preact';
import { articlePropTypes } from '../../common-prop-types';

const isYouTubeEmbed = (url) => {
  try {
    const parsed = new URL(url);
    const allowedHosts = ["youtube.com", "www.youtube.com"];
    return allowedHosts.includes(parsed.host) && parsed.pathname.startsWith("/embed/");
  } catch {
    return false;
  }
};

export const Video = ({ article }) => {
  if (isYouTubeEmbed(article.video)) {
    // Force 16:9 aspect ratio for YouTube videos
    return (
      <div
        className="crayons-article__cover crayons-article__cover__image__feed"
        style={{
          width: "100%",
          aspectRatio: "16 / 9",
          position: "relative",
        }}
      >
        <iframe
          src={article.video}
          style={{
            border: 0,
            position: "absolute",
            top: 0,
            left: 0,
            width: "100%",
            height: "100%",
          }}
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
          allowFullScreen
          title={article.title}
        />
      </div>
    );
  }
  return (
    <a
      href={article.url}
      className="crayons-story__video"
      style={`background-image:url(${article.cloudinary_video_url})`}
    >
      <span title="Video duration" className="crayons-story__video__time">
        {article.video_duration_in_minutes}
      </span>
    </a>
  );
};

Video.propTypes = {
  article: articlePropTypes.isRequired,
};

Video.displayName = 'Video';
