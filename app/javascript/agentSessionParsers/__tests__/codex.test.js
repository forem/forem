import { parse } from '../codex';

describe('codex parser', () => {
  function makeRecord(type, payload = {}, extra = {}) {
    return JSON.stringify({ type, payload, ...extra });
  }

  it('parses user messages from event_msg', () => {
    const input = makeRecord('event_msg', {
      type: 'user_message',
      message: 'Hello world',
    });
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].role).toBe('user');
    expect(result.messages[0].content[0].text).toBe('Hello world');
  });

  it('parses assistant text from response_item message', () => {
    const input = makeRecord('response_item', {
      role: 'assistant',
      type: 'message',
      content: [{ type: 'output_text', text: 'Hi there' }],
    });
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].role).toBe('assistant');
    expect(result.messages[0].content[0].text).toBe('Hi there');
  });

  it('parses function_call from response_item', () => {
    const input = makeRecord('response_item', {
      type: 'function_call',
      name: 'shell',
      arguments: 'ls -la',
    });
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].type).toBe('tool_call');
    expect(result.messages[0].content[0].name).toBe('shell');
  });

  it('attaches function_call_output to previous tool call', () => {
    const input = [
      makeRecord('response_item', {
        type: 'function_call',
        name: 'shell',
        arguments: 'ls',
      }),
      makeRecord('response_item', {
        type: 'function_call_output',
        output: 'file1.txt\nfile2.txt',
      }),
    ].join('\n');
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].output).toContain('file1.txt');
  });

  it('parses item.completed with command type', () => {
    const input = JSON.stringify({
      type: 'item.completed',
      item: {
        type: 'command',
        name: 'apply_diff',
        command: 'apply_diff',
        arguments: '{"file": "test.js"}',
        output: 'Applied successfully',
      },
    });
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].type).toBe('tool_call');
    expect(result.messages[0].content[0].name).toBe('apply_diff');
    expect(result.messages[0].content[0].output).toContain('Applied successfully');
  });

  it('parses item.completed with message type', () => {
    const input = JSON.stringify({
      type: 'item.completed',
      item: {
        type: 'message',
        content: [{ type: 'text', text: 'Done!' }],
      },
    });
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].text).toBe('Done!');
  });

  it('flushes assistant blocks on turn.completed', () => {
    const input = [
      makeRecord('response_item', {
        role: 'assistant',
        type: 'message',
        content: [{ type: 'text', text: 'Part 1' }],
      }),
      makeRecord('turn.completed', {}),
      makeRecord('response_item', {
        role: 'assistant',
        type: 'message',
        content: [{ type: 'text', text: 'Part 2' }],
      }),
    ].join('\n');
    const result = parse(input);
    expect(result.messages).toHaveLength(2);
  });

  it('extracts metadata from session_meta', () => {
    const input = [
      JSON.stringify({
        type: 'session_meta',
        payload: {
          id: 'sess-123',
          model_provider: 'o4-mini',
          cli_version: '1.0.0',
          timestamp: '2025-01-01T00:00:00Z',
        },
      }),
      makeRecord('event_msg', { type: 'user_message', message: 'Hello' }),
    ].join('\n');
    const result = parse(input);
    expect(result.metadata.tool_name).toBe('codex');
    expect(result.metadata.session_id).toBe('sess-123');
    expect(result.metadata.model).toBe('o4-mini');
    expect(result.metadata.start_time).toBe('2025-01-01T00:00:00Z');
  });

  it('handles empty content gracefully', () => {
    const result = parse('');
    expect(result.messages).toHaveLength(0);
    expect(result.metadata.tool_name).toBe('codex');
  });

  it('parses reasoning blocks from response_item', () => {
    const input = makeRecord('response_item', {
      type: 'reasoning',
      summary: [{ text: 'Thinking about the problem' }],
    });
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].text).toBe('Thinking about the problem');
  });

  it('handles file_change items', () => {
    const input = JSON.stringify({
      type: 'item.completed',
      item: {
        type: 'file_change',
        file_path: '/src/app.js',
        diff: '+ new line',
      },
    });
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].type).toBe('tool_call');
    expect(result.messages[0].content[0].name).toBe('FileChange');
    expect(result.messages[0].content[0].input).toBe('/src/app.js');
  });
});
