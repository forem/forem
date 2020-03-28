import PropTypes from 'prop-types';
import { tagPropTypes } from './tag-prop-types';
import { organizationPropType } from './organization-prop-type';

export const articleSnippetResultPropTypes = PropTypes.shape({
  body_text: PropTypes.shape({
    matchLevel: PropTypes.oneOf(['full', 'none']),
    value: PropTypes.string.isRequired,
  }),
  comments_blob: PropTypes.shape({
    matchLevel: PropTypes.oneOf(['full', 'none']),
    value: PropTypes.string.isRequired,
  }),
});

export const articlePropTypes = PropTypes.shape({
  id: PropTypes.number.isRequired,
  title: PropTypes.string.isRequired,
  path: PropTypes.string.isRequired,
  cloudinary_video_url: PropTypes.string,
  video_duration_in_minutes: PropTypes.number,
  type_of: PropTypes.oneOf(['podcast_episodes']),
  class_name: PropTypes.oneOf(['PodcastEpisode', 'User', 'Article']),
  flare_tag: tagPropTypes,
  tag_list: PropTypes.arrayOf(PropTypes.string),
  cached_tag_list_array: PropTypes.arrayOf(PropTypes.string),
  podcast: PropTypes.shape({
    slug: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired,
    image_url: PropTypes.string.isRequired,
  }),
  user_id: PropTypes.string.isRequired,
  user: PropTypes.shape({
    username: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired,
  }),
  organization: organizationPropType,
  _snippetResult: articleSnippetResultPropTypes,
  positive_reactions_count: PropTypes.number,
  reactions_count: PropTypes.number,
  comments_count: PropTypes.number,
});
