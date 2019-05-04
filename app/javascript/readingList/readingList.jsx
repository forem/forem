import { h, Component } from 'preact';

export class ReadingList extends Component {
  state = {
    readingListItems: [],
    query: '',
    index: '',
    availableTags: ['beginners', 'go'],
    selectedTags: [],
  };

  componentDidMount() {
    const algoliaId = document.querySelector("meta[name='algolia-public-id']")
    .content;
    const algoliaKey = document.getElementById('reading-list').dataset.algolia
    const env = document.querySelector("meta[name='environment']").content;
    const client = algoliasearch(algoliaId, algoliaKey);
    const index = client.initIndex(`SecuredReactions_${env}`);
    const t = this;
    index.search('', {}).then(content => {
      t.setState({readingListItems: content.hits, index});
    });
  
  }

  handleTyping = (e) => {
    const query = e.target.value;
    const { selectedTags } = this.state;
    this.listSearch(query, selectedTags);
  }

  selectTag = (e, tag) => {
    e.preventDefault();
    const { query, selectedTags, availableTags } = this.state;
    const newTags = selectedTags;
    if (newTags.indexOf(tag) === -1) {
      newTags.push(tag)
    }
    const newAvailableTags = availableTags.filter(t => newTags.indexOf(t) === -1)
    this.setState({selectedTags: newTags, availableTags: newAvailableTags})
    this.listSearch(query, newTags);
  }

  removeTag = (e, tag) => {
    e.preventDefault();
    const { query, selectedTags, availableTags } = this.state;
    const newTags = availableTags;
    if (newTags.indexOf(tag) === -1) {
      newTags.push(tag)
    }
    const newSelectedTags = selectedTags.filter(t => newTags.indexOf(t) === -1)
    this.setState({availableTags: newTags, selectedTags: newSelectedTags})
    this.listSearch(query, newSelectedTags);
  }

  listSearch(query, tags) {
    const t = this;
    const filters = {};
    if (tags.length > 0) {
      filters.tagFilters = tags;
    }
    t.state.index.search(query, filters).then(content => {
      t.setState({readingListItems: content.hits, query });
    });
  }

  render() {
    const { readingListItems, availableTags, selectedTags } = this.state;
    const allItems = readingListItems.map(item => (
      <a className='readinglist-item' href={item.searchable_reactable_path}>
        <div class='readinglist-item-title'>{item.searchable_reactable_title}</div>
      </a>
    ));
    const allTags = availableTags.map(tag => (
      <a className='readinglist-tag' href={`/t/${tag}`} data-no-instant onClick={e => this.selectTag(e, tag)}>#{tag}</a>
    ))
    const selectedtTagPills = selectedTags.map(tag => (
      <a className='readinglist-tag readinglist-tag--selected' href={`/t/${tag}`} data-no-instant onClick={e => this.removeTag(e, tag)}>#{tag}<button>×</button></a>
    ))
    return (
      <div>
        <div className='widget readinglist-filters'>
          <input onKeyUp={this.handleTyping} />
          {selectedtTagPills}
          {allTags}
        </div>
        <div className='readinglist-results'>
          <div>
            {allItems}
          </div>
        </div>
      </div>
    )
  }
}
