import { parse } from '../pi';

describe('pi parser', () => {
  function makeRecord(type, extra = {}) {
    return JSON.stringify({ type, ...extra });
  }

  function makeMessage(role, content, extra = {}) {
    return JSON.stringify({
      type: 'message',
      message: { role, content },
      timestamp: '2025-01-01T00:00:00Z',
      ...extra,
    });
  }

  it('parses user messages', () => {
    const input = makeMessage('user', [{ type: 'text', text: 'Hello' }]);
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].role).toBe('user');
    expect(result.messages[0].content[0].text).toBe('Hello');
  });

  it('parses user messages with string content', () => {
    const input = makeMessage('user', 'Plain text message');
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].text).toBe('Plain text message');
  });

  it('parses assistant text messages', () => {
    const input = makeMessage('assistant', [
      { type: 'text', text: 'Here is my response' },
    ]);
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].role).toBe('assistant');
    expect(result.messages[0].content[0].text).toBe('Here is my response');
  });

  it('parses thinking blocks in assistant messages', () => {
    const input = makeMessage('assistant', [
      { type: 'thinking', thinking: 'Let me consider this carefully and think about what approach to take' },
      { type: 'text', text: 'Done thinking' },
    ]);
    const result = parse(input);
    // Thinking is prefixed with **Thinking:** and combined with text
    const allText = result.messages.map(m => m.content.map(c => c.text).join(' ')).join(' ');
    expect(allText).toContain('Thinking:');
    expect(allText).toContain('Done thinking');
  });

  it('parses tool calls in assistant messages', () => {
    const input = makeMessage('assistant', [
      { type: 'toolCall', name: 'Read', arguments: { file_path: '/foo.rb' } },
    ]);
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].type).toBe('tool_call');
    expect(result.messages[0].content[0].name).toBe('Read');
  });

  it('attaches toolResult output to previous tool call', () => {
    const input = [
      makeMessage('assistant', [
        { type: 'toolCall', name: 'Read', arguments: { file: '/foo.rb' } },
      ]),
      makeMessage('toolResult', [
        { type: 'text', text: 'file contents here' },
      ]),
    ].join('\n');
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].output).toContain('file contents here');
  });

  it('flushes text before tool call in same assistant message', () => {
    const input = makeMessage('assistant', [
      { type: 'text', text: 'Let me read that file' },
      { type: 'toolCall', name: 'Read', arguments: { file: '/a.txt' } },
    ]);
    const result = parse(input);
    expect(result.messages).toHaveLength(2);
    expect(result.messages[0].content[0].text).toBe('Let me read that file');
    expect(result.messages[1].content[0].type).toBe('tool_call');
  });

  it('tracks model changes', () => {
    const input = [
      makeRecord('model_change', { modelId: 'claude-sonnet-4-20250514' }),
      makeMessage('user', [{ type: 'text', text: 'Hello' }]),
    ].join('\n');
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].model).toBe('claude-sonnet-4-20250514');
  });

  it('extracts metadata from session record', () => {
    const input = [
      makeRecord('session', { id: 'pi-sess-1', timestamp: '2025-01-01T00:00:00Z', cwd: '/home/user/project' }),
      makeRecord('model_change', { modelId: 'claude-sonnet-4-20250514' }),
      makeMessage('user', [{ type: 'text', text: 'Hello' }]),
    ].join('\n');
    const result = parse(input);
    expect(result.metadata.tool_name).toBe('pi');
    expect(result.metadata.session_id).toBe('pi-sess-1');
    expect(result.metadata.start_time).toBe('2025-01-01T00:00:00Z');
    expect(result.metadata.model).toBe('claude-sonnet-4-20250514');
    expect(result.metadata.working_directory).toBe('/home/user/project');
  });

  it('handles empty content gracefully', () => {
    const result = parse('');
    expect(result.messages).toHaveLength(0);
    expect(result.metadata.tool_name).toBe('pi');
  });

  it('ignores unknown record types', () => {
    const input = [
      makeRecord('telemetry', { data: 'something' }),
      makeMessage('user', [{ type: 'text', text: 'Hello' }]),
    ].join('\n');
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
  });
});
