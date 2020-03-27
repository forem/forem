global.document.head.innerHTML =
  "<meta name='algolia-public-id' content='abc123' />" +
  "<meta name='algolia-public-key' content='abc123' />" +
  "<meta name='environment' content='test' />";

const mockIndex = {
  search: (query, _options) =>
    new Promise((resolve, _reject) => {
      process.nextTick(() => {
        const searchResults = {
          gi: {
            hits: [
              {
                name: 'git',
                bg_color_hex: '#888751',
                text_color_hex: '#56c938',
                hotness_score: 0,
                supported: true,
                objectID: '4',
                _highlightResult: {
                  name: {
                    value: '<em>gi</em>t',
                    matchLevel: 'full',
                    fullyHighlighted: false,
                    matchedWords: ['gi'],
                  },
                  bg_color_hex: {
                    value: '#888751',
                    matchLevel: 'none',
                    matchedWords: [],
                  },
                  text_color_hex: {
                    value: '#56c938',
                    matchLevel: 'none',
                    matchedWords: [],
                  },
                },
              },
            ],
            nbHits: 1,
            page: 0,
            nbPages: 1,
            hitsPerPage: 10,
            processingTimeMS: 1,
            exhaustiveNbHits: true,
            query: 'gi',
            params:
              'query=gi&hitsPerPage=10&filters=supported%3Atrue&restrictIndices=searchables_development%2CTag_development%2Cordered_articles_development%2Cordered_articles_by_published_at_development%2Cordered_articles_by_positive_reactions_count_development',
          },
        };

        const results = searchResults[query] || { hits: [] };

        resolve(results);
      });
    }),
};
const client = {
  initIndex: _index => mockIndex,
};

export default jest.fn().mockImplementation((_id, _key) => client);
