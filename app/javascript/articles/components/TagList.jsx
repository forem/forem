import { h } from 'preact';
import { tagPropTypes } from '../../common-prop-types';

export const TagList = ({ tags = [], flare_tag }) => {
  let tagsToDisplay = tags;
  if (flare_tag) {
    tagsToDisplay = tagsToDisplay.filter((tag) => tag !== flare_tag.name);
  }
  return (
    <div className="crayons-story__tags">
      {flare_tag && (
        <a
          className="crayons-tag"
          href={`/t/${flare_tag.name}`}
          style={{
            background: flare_tag.bg_color_hex,
            color: flare_tag.text_color_hex,
          }}
        >
          <span className="crayons-tag__prefix">#</span>
          {flare_tag.name}
        </a>
      )}
      {tagsToDisplay.map((tag) => (
        <a className="crayons-tag" href={`/t/${tag}`}>
          <span className="crayons-tag__prefix">#</span>
          {tag}
        </a>
      ))}
    </div>
  );
};

TagList.propTypes = {
  tags: tagPropTypes.isRequired,
};

TagList.displayName = 'TagList';
