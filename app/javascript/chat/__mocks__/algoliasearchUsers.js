global.document.head.innerHTML =
  "<meta name='algolia-public-id' content='abc123' />" +
  "<meta name='algolia-public-key' content='abc123' />" +
  "<meta name='environment' content='test' />";

const mockIndex = {
  search: query =>
    new Promise(resolve => {
      process.nextTick(() => {
        const searchResults = {
          ma: {
            hits: [
              {
                name: 'mat',
                path: 'some_path',
                title: 'some_title',
                id: 'some_id',
              },
            ],
            nbHits: 1,
            page: 0,
            nbPages: 1,
            hitsPerPage: 10,
            processingTimeMS: 1,
            exhaustiveNbHits: true,
            query: 'ma',
            params:
              'query=ma&hitsPerPage=10&filters=supported%3Atrue&restrictIndices=searchables_development%2CTag_development%2Cordered_articles_development%2Cordered_articles_by_published_at_development%2Cordered_articles_by_positive_reactions_count_development%2Cordered_comments_development',
          },
        };

        const results = searchResults[query] || { hits: [] };

        resolve(results);
      });
    }),
};
const client = {
  initIndex: _index => mockIndex, // eslint-ignore-line
};

export default jest.fn().mockImplementation((_id_, _key) => client); // eslint-ignore-line
