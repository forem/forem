import { h, Component } from 'preact';
import PropTypes from 'prop-types';
// eslint-disable-next-line import/no-unresolved
import heartImage from 'images/emoji/emoji-one-heart.png';
// eslint-disable-next-line import/no-unresolved
import unicornImage from 'images/emoji/emoji-one-unicorn.png';
// eslint-disable-next-line import/no-unresolved
import bookmarkImage from 'images/emoji/emoji-one-bookmark.png';

export default class Article extends Component {
  static propTypes = {
    resource: PropTypes.shape({
      id: PropTypes.string,
    }).isRequired,
  };

  constructor(props) {
    super(props);
    this.state = {
      userReactions: [],
      optimisticUserReaction: null,
    };
  }

  componentDidMount() {
    const { resource } = this.props;
    fetch(`/reactions?article_id=${resource.id}`, {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      credentials: 'same-origin',
    })
      .then(response => response.json())
      .then(this.displayReactions)
      .catch(this.displayReactionsFailure);
  }

  displayReactions = response => {
    this.setState({ userReactions: response.reactions });
  };

  displayReactionsFailure = response => {
    // eslint-disable-next-line no-console
    console.log(response);
  };

  handleNewReactionResponse = response => {
    let { userReactions: oldUserReactions } = this.state;
    const foundReactions = oldUserReactions.filter(obj => {
      return obj.category === response.category;
    });
    if (foundReactions.length === 0 && response.result === 'create') {
      oldUserReactions.push({ category: response.category });
    } else {
      oldUserReactions = oldUserReactions.filter(obj => {
        return obj.category !== response.category;
      });
    }
    this.setState({
      userReactions: oldUserReactions,
      optimisticUserReaction: null,
    });
  };

  handleNewReactionFailure = response => {
    // eslint-disable-next-line no-console
    console.log(response);
  };

  handleReactionClick = e => {
    e.preventDefault();
    const { target } = e;
    const { resource: article } = this.props;
    this.setState({ optimisticUserReaction: target.dataset.category });
    fetch('/reactions', {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        reactable_type: 'Article',
        reactable_id: article.id,
        category: target.dataset.category,
      }),
      credentials: 'same-origin',
    })
      .then(response => response.json())
      .then(this.handleNewReactionResponse)
      .catch(this.handleNewReactionFailure);
  };

  actionButton = props => {
    const types = {
      heart: ['heart-reaction-button', 'like', heartImage],
      unicorn: ['unicorn-reaction-button', 'unicorn', unicornImage],
      readinglist: [
        'readinglist-reaction-button',
        'readinglist',
        bookmarkImage,
      ],
    };

    const curType = types[props.reaction];

    return (
      <button
        type="button"
        className={`${curType[0]} ${props.reactedClass}`}
        onClick={this.handleReactionClick}
        data-category={curType[1]}
      >
        <img
          src={curType[2]}
          data-category={curType[1]}
          alt={`${curType[1]} reaction`}
        />
      </button>
    );
  };

  render() {
    const { resource: article } = this.props;
    let heartReactedClass = '';
    let unicornReactedClass = '';
    let bookmarkReactedClass = '';
    const { state } = this;
    state.userReactions.forEach(reaction => {
      if (
        reaction.category === 'like' ||
        state.optimisticUserReaction === 'like'
      ) {
        heartReactedClass = 'active';
      }
      if (
        reaction.category === 'unicorn' ||
        state.optimisticUserReaction === 'unicorn'
      ) {
        unicornReactedClass = 'active';
      }
      if (
        reaction.category === 'readinglist' ||
        state.optimisticUserReaction === 'readinglist'
      ) {
        bookmarkReactedClass = 'active';
      }
    });
    let coverImage = '';
    if (article.cover_image) {
      coverImage = (
        <section>
          <div
            className="image image-final"
            style={{ backgroundImage: `url(${article.cover_image}` }}
          />
        </section>
      );
    }
    return (
      <div className="activechatchannel__activeArticle">
        <div className="activechatchannel__activeArticleDetails">
          <a href={article.path} target="_blank" rel="noopener noreferrer">
            <span className="activechatchannel__activeArticleDetailsPath">
              {article.path}
            </span>
          </a>
        </div>
        <div className="container">
          {coverImage}
          <div className="title">
            <h1>{article.title}</h1>
            <h3>
              <a
                href={`/${article.user.username}`}
                className="author"
                data-content={`/users/${article.user.id}`}
              >
                <img
                  className="profile-pic"
                  src={article.user.profile_image_90}
                  alt={article.user.username}
                />
                <span>
                  {article.user.name}
                  {' '}
                </span>
                <span className="published-at">
                  {' '}
                  | 
                  {' '}
                  {article.readable_publish_date}
                </span>
              </a>
            </h3>
          </div>
          <div className="body">
            {/* eslint-disable-next-line react/no-danger */}
            <div dangerouslySetInnerHTML={{ __html: article.body_html }} />
          </div>
        </div>
        <div className="activechatchannel__activeArticleActions">
          <this.actionButton
            reaction="heart"
            reactedClass={heartReactedClass}
          />
          <this.actionButton
            reaction="unicorn"
            reactedClass={unicornReactedClass}
          />
          <this.actionButton
            reaction="readinglist"
            reactedClass={bookmarkReactedClass}
          />
        </div>
      </div>
    );
  }
}
