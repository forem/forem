import { detectTool, detectAndParse } from '../autoDetect';

describe('autoDetect', () => {
  describe('detectTool', () => {
    it('detects Claude Code from sessionId', () => {
      const content = JSON.stringify({ sessionId: 's1', type: 'user', message: { role: 'user', content: 'hi' } });
      expect(detectTool(content)).toBe('claude_code');
    });

    it('detects Claude Code from parentUuid', () => {
      const content = JSON.stringify({ parentUuid: 'abc', type: 'user', message: { role: 'user', content: 'hi' } });
      expect(detectTool(content)).toBe('claude_code');
    });

    it('detects GitHub Copilot from session.start', () => {
      const content = JSON.stringify({ type: 'session.start', data: { sessionId: 's1' } });
      expect(detectTool(content)).toBe('github_copilot');
    });

    it('detects Codex from session_meta', () => {
      const content = JSON.stringify({ type: 'session_meta', payload: { model_provider: 'openai' } });
      expect(detectTool(content)).toBe('codex');
    });

    it('detects Codex from dotted type patterns', () => {
      const content = JSON.stringify({ type: 'event_msg.start', payload: {} });
      expect(detectTool(content)).toBe('codex');
    });

    it('detects Pi from session+version', () => {
      const content = JSON.stringify({ type: 'session', version: 1, id: 'abc' });
      expect(detectTool(content)).toBe('pi');
    });

    it('detects Pi from parentId', () => {
      const content = JSON.stringify({ parentId: 'root', type: 'message' });
      expect(detectTool(content)).toBe('pi');
    });

    it('detects Gemini CLI from session_metadata type', () => {
      const content = JSON.stringify({ type: 'session_metadata', data: {} });
      expect(detectTool(content)).toBe('gemini_cli');
    });

    it('detects Gemini CLI from single JSON object without parentId', () => {
      // Must not have sessionId/parentId etc. on first line to reach full-JSON parse
      const content = JSON.stringify({ messages: [{ role: 'user', content: 'hi' }] });
      expect(detectTool(content)).toBe('gemini_cli');
    });

    it('detects claude_code when sessionId present (even with messages)', () => {
      // sessionId on first line triggers JSONL detection branch
      const content = JSON.stringify({ sessionId: 's1', messages: [{ role: 'user', content: 'hi' }] });
      expect(detectTool(content)).toBe('claude_code');
    });

    it('defaults to gemini_cli for unknown single-line JSON objects', () => {
      // Single-line valid JSON without JSONL keys falls through to full-JSON parse
      const content = JSON.stringify({ something: 'random' });
      expect(detectTool(content)).toBe('gemini_cli');
    });
  });

  describe('detectAndParse', () => {
    it('detects and parses Claude Code JSONL', () => {
      const content = [
        JSON.stringify({ type: 'user', message: { role: 'user', content: 'Hello' }, sessionId: 's1', timestamp: '2025-01-01T00:00:00Z' }),
        JSON.stringify({ type: 'assistant', message: { role: 'assistant', content: [{ type: 'text', text: 'Hi' }] }, sessionId: 's1', timestamp: '2025-01-01T00:00:01Z' }),
      ].join('\n');

      const { toolName, result } = detectAndParse(content);
      expect(toolName).toBe('claude_code');
      expect(result.messages).toHaveLength(2);
    });
  });
});
