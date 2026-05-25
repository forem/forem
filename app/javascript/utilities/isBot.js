// Single source of truth for crawler UA detection, shared by the page-view and
// billboard tracking gates; mirror of the server list in update_page_views_worker.rb.
const BOT_USER_AGENT =
  /bot|crawl|spider|google|baidu|bing|msn|duckduckbot|teoma|slurp|yandex|chatgpt|anthropic|cohere-ai|facebookexternalhit/i;

export function isBotUserAgent(userAgent) {
  return BOT_USER_AGENT.test(userAgent || '');
}
