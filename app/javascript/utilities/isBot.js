// Client-side bot user-agent filter, shared by the page-view and billboard
// tracking gates. Must be kept in sync with the server-side list in
// app/workers/articles/update_page_views_worker.rb.
const BOT_USER_AGENT =
  /bot|crawl|spider|google|baidu|bing|msn|duckduckbot|teoma|slurp|yandex|chatgpt|anthropic|cohere-ai|facebookexternalhit/i;

export function isBotUserAgent(userAgent) {
  return BOT_USER_AGENT.test(userAgent || '');
}
