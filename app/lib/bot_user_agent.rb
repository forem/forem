module BotUserAgent
  # Authoritative server-side list, kept in parity with app/javascript/utilities/isBot.js.
  REGEX = /
  \b(bot|gptbot|crawl|spider)\b|
  google|baidu|bing|msn|duckduckbot|teoma|slurp|
  yandex|chatgpt|anthropic|cohere-ai|facebookexternalhit
/ix

  def self.match?(user_agent)
    user_agent.present? && REGEX.match?(user_agent)
  end
end
