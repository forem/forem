

import { h, Component } from 'preact';
import heartImage from 'images/emoji/emoji-one-heart.png';
import unicornImage from 'images/emoji/emoji-one-unicorn.png';
import bookmarkImage from 'images/emoji/emoji-one-bookmark.png';

export default class Article extends Component {
  constructor(props) {
    super(props);
    this.state = {
      reactionCounts: [],
      userReactions: [],
      optimisticUserReaction: null,
    }

  }

  componentDidMount() {
    fetch("/reactions?article_id="+this.props.resource.id, {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      credentials: 'same-origin',
    })
    .then(response => response.json())
    .then(this.displayReactions)
    .catch(this.displayReactionsFailure);
  }

  displayReactions = response => {
    this.setState({userReactions:response.reactions})
  }

  displayReactionsFailure = response => {
    console.log(response)
  }

  handleNewReactionResponse = (response) => {
    let oldUserReactions = this.state.userReactions;
    let foundReactions = oldUserReactions.filter(obj => {
      return obj.category === response.category
    })
    if (foundReactions.length === 0 && response.result === 'create') {
      oldUserReactions.push({category: response.category})
    } else {
      oldUserReactions = oldUserReactions.filter(obj => {
        return obj.category != response.category
      })
    }
    this.setState({userReactions: oldUserReactions, optimisticUserReaction: null})
  }

  handleNewReactionFailure = response => {
    console.log(response)
  }

  handleReactionClick = e => {
    e.preventDefault();
    const target = e.target;
    console.log(target.dataset.category)
    this.setState({optimisticUserReaction: target.dataset.category })
    const article = this.props.resource
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
      
  }

  render() {
    const article = this.props.resource;
    let heartReactedClass = ''
    let unicornReactedClass = ''
    let bookmarkReactedClass = ''
    const state = this.state;
    state.userReactions.forEach((reaction) => {
      if (reaction.category === 'like' || state.optimisticUserReaction === 'like') {
        heartReactedClass = 'active'
      }
      if (reaction.category === 'unicorn' || state.optimisticUserReaction === 'unicorn') {
        unicornReactedClass = 'active'
      }
      if (reaction.category === 'readinglist' || state.optimisticUserReaction === 'readinglist') {
        bookmarkReactedClass = 'active'
      }
    });
    let coverImage = '';
    if (article.cover_image) {
      coverImage = <header><div class="image image-final" style={{backgroundImage:`url(${article.cover_image}`}}></div></header>
    }
    return (
            <div className='activechatchannel__activeArticle'>
              <div className="container">
                {coverImage}
                <div className="title">
                  <h1>{article.title}</h1>
                  <h3>
                    <a href={'/'+article.user.username} className="author" data-content={'/users/'+article.user.id}>
                      <img className="profile-pic" src={article.user.profile_image_90} alt={article.user.username}/>
                      <span>{article.user.name}</span>
                    </a>
                  </h3>
                </div>
                <div className="body">
                <div dangerouslySetInnerHTML={{__html: article.body_html}} ></div>
                </div>
              </div>
            <div className="activechatchannel__activeArticleActions">
              <button className={'heart-reaction-button ' + heartReactedClass}
                onClick={this.handleReactionClick} data-category='like' >
                <img src={heartImage} />
              </button>
              <button className={'unicorn-reaction-button ' + unicornReactedClass}
                onClick={this.handleReactionClick} data-category='unicorn'>
                <img src={unicornImage} data-category='unicorn' />
              </button>
              <button className={'readinglist-reaction-button ' + bookmarkReactedClass}
                onClick={this.handleReactionClick} data-category='readinglist'>
                <img src={bookmarkImage} data-category='readinglist' />
              </button>
            </div>
          </div>)
  }
}

