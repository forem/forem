import { scrub, scrubText } from '../sensitiveDataScrubber';

describe('sensitiveDataScrubber', () => {
  describe('scrub', () => {
    function makeData(text) {
      return {
        messages: [
          { role: 'user', content: [{ type: 'text', text }] },
        ],
        metadata: {},
      };
    }

    it('redacts GitHub tokens', () => {
      const result = scrub(makeData('My token is ghp_abcdefghijklmnopqrstuvwxyz1234567890'));
      expect(result.scrubbed_data.messages[0].content[0].text).toContain('[REDACTED]');
      expect(result.scrubbed_data.messages[0].content[0].text).not.toContain('ghp_');
      expect(result.redactions).toHaveLength(1);
      expect(result.redactions[0].pattern_name).toBe('GitHub Token');
    });

    it('redacts AWS access keys', () => {
      const result = scrub(makeData('Key: AKIAIOSFODNN7EXAMPLE'));
      expect(result.scrubbed_data.messages[0].content[0].text).toContain('[REDACTED]');
      expect(result.redactions.some(r => r.pattern_name === 'AWS Access Key')).toBe(true);
    });

    it('redacts Anthropic API keys', () => {
      const result = scrub(makeData('sk-ant-' + 'a'.repeat(45)));
      expect(result.scrubbed_data.messages[0].content[0].text).toContain('[REDACTED]');
      expect(result.redactions.some(r => r.pattern_name === 'Anthropic API Key')).toBe(true);
    });

    it('redacts Stripe keys', () => {
      const result = scrub(makeData('sk_live_' + 'a'.repeat(25)));
      expect(result.scrubbed_data.messages[0].content[0].text).toContain('[REDACTED]');
    });

    it('redacts private key headers', () => {
      const result = scrub(makeData('-----BEGIN RSA PRIVATE KEY-----'));
      expect(result.scrubbed_data.messages[0].content[0].text).toContain('[REDACTED]');
    });

    it('redacts JWT tokens', () => {
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U';
      const result = scrub(makeData('Bearer ' + jwt));
      expect(result.scrubbed_data.messages[0].content[0].text).toContain('[REDACTED]');
    });

    it('redacts home directories', () => {
      const result = scrub(makeData('Path: /home/username/project'));
      expect(result.scrubbed_data.messages[0].content[0].text).toContain('[REDACTED]');
    });

    it('skips noisy patterns in tool output blocks', () => {
      const data = {
        messages: [
          {
            role: 'assistant',
            content: [{
              type: 'tool_call',
              name: 'Bash',
              input: 'ls',
              output: 'Working in /home/user/project on 192.168.1.1',
            }],
          },
        ],
        metadata: {},
      };
      const result = scrub(data);
      // Home directory and IPv4 should NOT be redacted in tool output
      expect(result.scrubbed_data.messages[0].content[0].output).toContain('/home/user/project');
      expect(result.scrubbed_data.messages[0].content[0].output).toContain('192.168.1.1');
    });

    it('does not modify the original data', () => {
      const original = makeData('ghp_abcdefghijklmnopqrstuvwxyz1234567890');
      const originalText = original.messages[0].content[0].text;
      scrub(original);
      expect(original.messages[0].content[0].text).toBe(originalText);
    });

    it('returns empty redactions when no secrets found', () => {
      const result = scrub(makeData('Just normal text'));
      expect(result.redactions).toHaveLength(0);
    });

    it('scrubs tool_call input field', () => {
      const data = {
        messages: [{
          role: 'assistant',
          content: [{
            type: 'tool_call',
            name: 'Bash',
            input: 'export API_KEY=ghp_abcdefghijklmnopqrstuvwxyz1234567890',
          }],
        }],
        metadata: {},
      };
      const result = scrub(data);
      expect(result.scrubbed_data.messages[0].content[0].input).toContain('[REDACTED]');
    });
  });

  describe('scrubText', () => {
    it('redacts secrets from plain text', () => {
      const text = 'Token: ghp_abcdefghijklmnopqrstuvwxyz1234567890';
      const result = scrubText(text);
      expect(result).toContain('[REDACTED]');
      expect(result).not.toContain('ghp_');
    });

    it('leaves clean text unchanged', () => {
      const text = 'Hello world';
      expect(scrubText(text)).toBe('Hello world');
    });
  });
});
