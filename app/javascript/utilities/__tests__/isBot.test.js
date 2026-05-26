import { isBotUserAgent } from '@utilities/isBot';

describe('isBotUserAgent', () => {
  describe('crawlers whose UA contains "bot"', () => {
    it.each([
      ['GPTBot', 'Mozilla/5.0 (compatible; GPTBot/1.2)'],
      ['Googlebot', 'Mozilla/5.0 (compatible; Googlebot/2.1)'],
      ['bingbot', 'Mozilla/5.0 (compatible; bingbot/2.0)'],
    ])('flags %s', (_label, ua) => {
      expect(isBotUserAgent(ua)).toBe(true);
    });
  });

  describe('crawlers whose UA lacks "bot" (the regression cases)', () => {
    it.each([
      ['ChatGPT-User', 'Mozilla/5.0 ChatGPT-User/1.0'],
      ['anthropic-ai', 'anthropic-ai/1.0'],
      ['cohere-ai', 'cohere-ai'],
      ['facebookexternalhit', 'facebookexternalhit/1.1'],
      ['Bytespider', 'Mozilla/5.0 (compatible; Bytespider; spider-feedback@bytedance.com)'],
    ])('flags %s', (_label, ua) => {
      expect(ua.toLowerCase()).not.toContain('bot');
      expect(isBotUserAgent(ua)).toBe(true);
    });
  });

  describe('real human browsers are never flagged', () => {
    it.each([
      [
        'Chrome on macOS',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
      ],
      [
        'Safari on iOS',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1',
      ],
      [
        'Firefox on Windows',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:125.0) Gecko/20100101 Firefox/125.0',
      ],
    ])('does not flag %s', (_label, ua) => {
      expect(isBotUserAgent(ua)).toBe(false);
    });
  });

  describe('edge cases', () => {
    it('returns false for an empty string', () => {
      expect(isBotUserAgent('')).toBe(false);
    });

    it('returns false for null or undefined', () => {
      expect(isBotUserAgent(null)).toBe(false);
      expect(isBotUserAgent(undefined)).toBe(false);
    });
  });
});
