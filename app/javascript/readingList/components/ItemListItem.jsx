// Item list item
import { h } from 'preact';
import { PropTypes } from 'preact-compat';

export const ItemListItem = ({ item, children }) => {
  const adaptedItem = {
    path: item.reactable.path,
    title: item.reactable.title,
    user: item.reactable.user,
    publishedDate: item.reactable.published_date_string,
    readingTime: item.reactable.reading_time,
    tags: item.reactable.tags,
  };

  // update readingTime to 1 min if the reading time is less than 1 min
  adaptedItem.readingTime = Math.max(1, adaptedItem.readingTime || null);
  return (
    <div className="item-wrapper">
      <a className="item" href={adaptedItem.path}>
        <div className="item-title">{adaptedItem.title}</div>

        <div className="item-details">
          <a className="item-user" href={`/${adaptedItem.user.username}`}>
            <img src={adaptedItem.user.profile_image_90} alt="Profile Pic" />
            {`${adaptedItem.user.name}・`}
            {`${adaptedItem.publishedDate}・`}
            {`${adaptedItem.readingTime} min read・`}
          </a>

          {adaptedItem.tags.length > 0 ? (
            <span className="item-tags">
              {adaptedItem.tags.map((tag) => (
                <a className="item-tag" href={`/t/${tag.name}`}>
                  {`#${tag.name}`}
                </a>
              ))}
            </span>
          ) : (
            ''
          )}

          {children}
        </div>
      </a>
    </div>
  );
};

const readingListItemPropTypes = PropTypes.shape({
  reactable: {
    path: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired,
    reading_time: PropTypes.number.isRequired,
    published_date_string: PropTypes.string.isRequired,
    user: PropTypes.shape({
      username: PropTypes.string.isRequired,
      profile_image_90: PropTypes.string.isRequired,
      name: PropTypes.string.isRequired,
    }),
    tags: PropTypes.arrayOf(PropTypes.string).isRequired,
  },
});

ItemListItem.defaultProps = {
  children: {},
};

ItemListItem.propTypes = {
  item: PropTypes.oneOfType([readingListItemPropTypes]).isRequired,
  children: PropTypes.element,
};
