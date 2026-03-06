import { parse } from '../geminiCli';

describe('geminiCli parser', () => {
  it('parses user and assistant messages from JSON array', () => {
    const input = JSON.stringify([
      { type: 'user', content: 'Hello' },
      { type: 'model', content: 'Hi there' },
    ]);
    const result = parse(input);
    expect(result.messages).toHaveLength(2);
    expect(result.messages[0].role).toBe('user');
    expect(result.messages[0].content[0].text).toBe('Hello');
    expect(result.messages[1].role).toBe('assistant');
    expect(result.messages[1].content[0].text).toBe('Hi there');
  });

  it('normalizes role types (gemini, human)', () => {
    const input = JSON.stringify([
      { type: 'human', content: 'Hello' },
      { type: 'gemini', content: 'Hi' },
    ]);
    const result = parse(input);
    expect(result.messages[0].role).toBe('user');
    expect(result.messages[1].role).toBe('assistant');
  });

  it('parses messages from a wrapper object', () => {
    const input = JSON.stringify({
      messages: [
        { type: 'user', content: 'Hello' },
        { role: 'assistant', content: 'Hi' },
      ],
    });
    const result = parse(input);
    expect(result.messages).toHaveLength(2);
  });

  it('handles array content with text parts', () => {
    const input = JSON.stringify([
      { type: 'user', content: [{ text: 'Part 1' }, { text: 'Part 2' }] },
    ]);
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content).toHaveLength(2);
    expect(result.messages[0].content[0].text).toBe('Part 1');
    expect(result.messages[0].content[1].text).toBe('Part 2');
  });

  it('extracts thoughts from assistant messages', () => {
    const input = JSON.stringify([
      {
        type: 'model',
        content: 'Response text',
        thoughts: [{ subject: 'Planning' }, { subject: 'Analyzing' }],
      },
    ]);
    const result = parse(input);
    // Thoughts + content = 2 messages (thoughts flush as text, then content)
    expect(result.messages.length).toBeGreaterThanOrEqual(1);
    const allText = result.messages.map(m => m.content.map(c => c.text).join(' ')).join(' ');
    expect(allText).toContain('Planning');
    expect(allText).toContain('Response text');
  });

  it('parses tool calls from toolCalls array', () => {
    const input = JSON.stringify([
      {
        type: 'model',
        toolCalls: [
          { name: 'read_file', displayName: 'ReadFile', args: { path: '/foo.js' } },
        ],
      },
    ]);
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].type).toBe('tool_call');
    expect(result.messages[0].content[0].name).toBe('ReadFile');
  });

  it('parses inline functionCall in content array', () => {
    const input = JSON.stringify([
      {
        type: 'model',
        content: [
          { functionCall: { name: 'shell', args: { command: 'ls' } } },
        ],
      },
    ]);
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].type).toBe('tool_call');
    expect(result.messages[0].content[0].name).toBe('shell');
  });

  it('skips entries with unknown role types', () => {
    const input = JSON.stringify([
      { type: 'system', content: 'System prompt' },
      { type: 'user', content: 'Hello' },
    ]);
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].role).toBe('user');
  });

  it('extracts metadata', () => {
    const input = JSON.stringify({
      sessionId: 'gemini-123',
      startTime: '2025-06-01T10:00:00Z',
      messages: [
        { type: 'user', content: 'Hello', model: 'gemini-2.5-pro' },
      ],
    });
    const result = parse(input);
    expect(result.metadata.tool_name).toBe('gemini_cli');
    expect(result.metadata.session_id).toBe('gemini-123');
    expect(result.metadata.start_time).toBe('2025-06-01T10:00:00Z');
  });

  it('handles empty content gracefully', () => {
    const result = parse('');
    expect(result.messages).toHaveLength(0);
    expect(result.metadata.tool_name).toBe('gemini_cli');
  });

  it('falls back to JSONL parsing if JSON.parse fails', () => {
    const input = [
      JSON.stringify({ type: 'user', content: 'Line 1' }),
      JSON.stringify({ type: 'model', content: 'Line 2' }),
    ].join('\n');
    const result = parse(input);
    expect(result.messages).toHaveLength(2);
  });
});
