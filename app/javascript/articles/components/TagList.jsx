import { h } from 'preact';
import PropTypes from 'prop-types';

export const TagList = ({ tags = [], flare_tag }) => {
  let tagsToDisplay = tags;
  if (flare_tag) {
    tagsToDisplay = tagsToDisplay.filter((tag) => tag !== flare_tag.name);
  }
  return (
    <div className="crayons-story__tags">
      {flare_tag && (
        <a
          className="crayons-tag crayons-tag--filled"
          href={`/t/${flare_tag.name}`}
          style={{
            '--tag-bg': `${flare_tag.bg_color_hex}1a`,
            '--tag-prefix': flare_tag.bg_color_hex,
            '--tag-bg-hover': `${flare_tag.bg_color_hex}1a`,
            '--tag-prefix-hover': flare_tag.bg_color_hex,
          }}
        >
          <span className="crayons-tag__prefix">#</span>
          {flare_tag.name}
        </a>
      )}
      {tagsToDisplay.map((tag) => (
        <a key={`tag-${tag}`} className="crayons-tag" href={`/t/${tag}`}>
          <span className="crayons-tag__prefix">#</span>
          {tag}
        </a>
      ))}
    </div>
  );
};

TagList.propTypes = {
  tags: PropTypes.arrayOf(PropTypes.string).isRequired,
};

TagList.displayName = 'TagList';
