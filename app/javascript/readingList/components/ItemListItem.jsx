// Item list item
import { h } from 'preact';
import PropTypes from 'prop-types';

export const ItemListItem = ({ item, children }) => {
  const adaptedItem = {
    path: item.reactable.path,
    title: item.reactable.title,
    user: item.reactable.user,
    publishedDate: item.reactable.readable_publish_date_string,
    readingTime: item.reactable.reading_time,
    tags: item.reactable.tags,
  };

  // update readingTime to 1 min if the reading time is less than 1 min
  adaptedItem.readingTime = Math.max(1, adaptedItem.readingTime || null);
  return (
    <article className="flex px-6 py-4">
      <a
        href={`/${adaptedItem.user.username}`}
        datatestid="item-user"
        className="crayons-avatar crayons-avatar--l shrink-0"
      >
        <img
          src={adaptedItem.user.profile_image_90}
          alt={adaptedItem.user.name}
          className="crayons-avatar__image"
        />
      </a>

      <div className="flex-1 pl-4">
        <a href={adaptedItem.path} class="flex crayons-link">
          <h2
            className="fs-l fw-bold m-0 break-word"
            // eslint-disable-next-line react/no-danger
            dangerouslySetInnerHTML={{ __html: filterXSS(adaptedItem.title) }}
          />
        </a>
        <p className="fs-s">
          <a
            href={`/${adaptedItem.user.username}`}
            className="crayons-link fw-medium"
          >
            {adaptedItem.user.name}
          </a>
          <span class="color-base-30"> • </span>
          <span className="color-base-60">
            {adaptedItem.publishedDate}
            <span class="color-base-30"> • </span>
            {`${adaptedItem.readingTime} min read`}
          </span>
          {adaptedItem.tags.length > 0 ? (
            <span datatestid="item-tags">
              <span class="color-base-30"> • </span>
              {adaptedItem.tags.map((tag) => (
                <a className="crayons-tag" href={`/t/${tag.name}`}>
                  {`#${tag.name}`}
                </a>
              ))}
            </span>
          ) : (
            ''
          )}
        </p>
      </div>

      <div className="self-center">{children}</div>
    </article>
  );
};

const readingListItemPropTypes = PropTypes.shape({
  reactable: {
    path: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired,
    reading_time: PropTypes.number.isRequired,
    readable_publish_date_string: PropTypes.string.isRequired,
    user: PropTypes.shape({
      username: PropTypes.string.isRequired,
      profile_image_90: PropTypes.string.isRequired,
      name: PropTypes.string.isRequired,
    }),
    tags: PropTypes.arrayOf(PropTypes.string).isRequired,
  },
});

ItemListItem.propTypes = {
  item: PropTypes.oneOfType([readingListItemPropTypes]).isRequired,
};
