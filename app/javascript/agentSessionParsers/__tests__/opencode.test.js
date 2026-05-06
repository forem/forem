import { parse } from '../opencode';

describe('opencode parser', () => {
  it('parses OpenCode CLI JSON exports', () => {
    const input = JSON.stringify({
      info: {
        id: 'ses_123',
        title: 'OpenCode session',
        directory: '/workspace/project',
        time: { created: 1778005777747, updated: 1778005780228 },
      },
      messages: [
        {
          info: {
            role: 'user',
            time: { created: 1778005777747 },
            model: { providerID: 'google', modelID: 'gemini-3-flash-preview' },
          },
          parts: [{ type: 'text', text: 'Hello OpenCode' }],
        },
        {
          info: { role: 'assistant', time: { created: 1778005780228 } },
          parts: [
            { type: 'reasoning', text: 'Thinking through the task' },
            { type: 'tool', tool: 'bash', callID: 'call_1', state: { input: { command: 'ls' }, output: 'file.txt' } },
            { type: 'text', text: 'Done' },
          ],
        },
      ],
    });

    const result = parse(input);

    expect(result.messages).toHaveLength(2);
    expect(result.messages[0].role).toBe('user');
    expect(result.messages[0].content[0].text).toBe('Hello OpenCode');
    expect(result.messages[1].role).toBe('assistant');
    expect(result.messages[1].content[1].type).toBe('tool_call');
    expect(result.messages[1].content[1].name).toBe('bash');
    expect(result.metadata.tool_name).toBe('opencode');
    expect(result.metadata.session_id).toBe('ses_123');
    expect(result.metadata.model).toBe('google/gemini-3-flash-preview');
  });

  it('extracts model metadata from assistant message info fields', () => {
    const result = parse(JSON.stringify({
      info: { id: 'ses_123' },
      messages: [
        {
          info: {
            role: 'assistant',
            providerID: 'anthropic',
            modelID: 'claude-sonnet-4-5',
          },
          parts: [{ type: 'text', text: 'hello' }],
        },
      ],
    }));

    expect(result.messages[0].model).toBe('anthropic/claude-sonnet-4-5');
    expect(result.metadata.model).toBe('anthropic/claude-sonnet-4-5');
  });

  it('handles empty message exports', () => {
    const result = parse(JSON.stringify({
      info: { id: 'ses_123' },
      messages: [],
    }));

    expect(result.messages).toHaveLength(0);
    expect(result.metadata.tool_name).toBe('opencode');
    expect(result.metadata.total_messages).toBe(0);
  });

  it('skips messages with unknown roles', () => {
    const result = parse(JSON.stringify({
      info: { id: 'ses_123' },
      messages: [
        { info: { role: 'system' }, parts: [{ type: 'text', text: 'ignored' }] },
        { info: { role: 'user' }, parts: [{ type: 'text', text: 'kept' }] },
      ],
    }));

    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].text).toBe('kept');
  });

  it('skips messages without content blocks', () => {
    const result = parse(JSON.stringify({
      info: { id: 'ses_123' },
      messages: [
        { info: { role: 'user' }, parts: [] },
        { info: { role: 'assistant' }, parts: [{ type: 'text', text: 'response' }] },
      ],
    }));

    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].role).toBe('assistant');
  });

  it('handles tool parts without state', () => {
    const result = parse(JSON.stringify({
      info: { id: 'ses_123' },
      messages: [
        { info: { role: 'assistant' }, parts: [{ type: 'tool', tool: 'bash', callID: 'call_1' }] },
      ],
    }));

    const block = result.messages[0].content[0];
    expect(block.type).toBe('tool_call');
    expect(block.name).toBe('bash');
    expect(block.input).toBeUndefined();
    expect(block.output).toBeUndefined();
  });

  it('renders file attachment parts as text blocks', () => {
    const result = parse(JSON.stringify({
      info: { id: 'ses_123' },
      messages: [
        { info: { role: 'user' }, parts: [{ type: 'file', filename: 'notes.md' }] },
      ],
    }));

    expect(result.messages[0].content[0].text).toBe('[File attachment: notes.md]');
  });

  it('omits missing optional metadata fields', () => {
    const result = parse(JSON.stringify({
      info: { id: 'ses_123' },
      messages: [
        { info: { role: 'user' }, parts: [{ type: 'text', text: 'hello' }] },
      ],
    }));

    expect(result.metadata.session_id).toBe('ses_123');
    expect(result.metadata).not.toHaveProperty('title');
    expect(result.metadata).not.toHaveProperty('working_directory');
    expect(result.metadata).not.toHaveProperty('model');
    expect(result.metadata).not.toHaveProperty('start_time');
    expect(result.metadata).not.toHaveProperty('end_time');
  });

  it('throws on malformed JSON input', () => {
    expect(() => parse('{not json')).toThrow(SyntaxError);
  });

});
