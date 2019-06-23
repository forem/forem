export default function setupAlgoliaIndex({ containerId, indexName }) {
  const id = document.querySelector("meta[name='algolia-public-id']").content;
  const key = document.getElementById(containerId).dataset.algoliaKey;
  const env = document.querySelector("meta[name='environment']").content;
  const client = algoliasearch(id, key);
  return client.initIndex(`${indexName}_${env}`);
}
