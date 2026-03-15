import { parse } from '../shelley';

describe('shelley parser', () => {
  const HEADER = JSON.stringify({
    type: 'shelley_session',
    version: 1,
    conversation_id: 'c6LDV63',
    slug: 'my-session',
    model: 'claude-sonnet-4.5',
    cwd: '/home/user/project',
    created_at: '2025-01-01T00:00:00Z',
    updated_at: '2025-01-01T01:00:00Z',
  });

  function makeMessage(role, content, extra = {}) {
    return JSON.stringify({
      type: 'message',
      role,
      sequence_id: extra.sequence_id || 1,
      timestamp: extra.timestamp || '2025-01-01T00:00:00Z',
      model: extra.model,
      content,
    });
  }

  it('parses user text messages', () => {
    const input = [
      HEADER,
      makeMessage('user', [{ Type: 2, Text: 'Hello world' }]),
      makeMessage('assistant', [{ Type: 2, Text: 'Hi there' }]),
    ].join('\n');

    const result = parse(input);
    expect(result.messages).toHaveLength(2);
    expect(result.messages[0].role).toBe('user');
    expect(result.messages[0].content[0].text).toBe('Hello world');
    expect(result.messages[0].index).toBe(0);
    expect(result.messages[1].role).toBe('assistant');
    expect(result.messages[1].content[0].text).toBe('Hi there');
    expect(result.messages[1].index).toBe(1);
  });

  it('skips system messages', () => {
    const input = [
      HEADER,
      makeMessage('system', [{ Type: 2, Text: 'System prompt' }]),
      makeMessage('user', [{ Type: 2, Text: 'Hello' }]),
    ].join('\n');

    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].role).toBe('user');
  });

  it('pairs tool_use with tool_result via ID', () => {
    const input = [
      HEADER,
      makeMessage('assistant', [
        { Type: 5, ID: 'tool1', ToolName: 'bash', ToolInput: { command: 'ls -la' } },
      ]),
      makeMessage('user', [
        {
          Type: 6,
          ToolUseID: 'tool1',
          ToolError: false,
          ToolUseStartTime: '2025-01-01T00:00:01Z',
          ToolUseEndTime: '2025-01-01T00:00:02Z',
          ToolResult: [{ Type: 2, Text: 'file1.txt\nfile2.txt' }],
        },
      ]),
    ].join('\n');

    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    const toolBlock = result.messages[0].content[0];
    expect(toolBlock.type).toBe('tool_call');
    expect(toolBlock.name).toBe('bash');
    expect(toolBlock.input).toBe('ls -la');
    expect(toolBlock.output).toBe('file1.txt\nfile2.txt');
  });

  it('summarizes tool input for known Shelley tools', () => {
    const tools = [
      { name: 'bash', input: { command: 'git status' }, expected: 'git status' },
      { name: 'patch', input: { path: '/foo/bar.js' }, expected: '/foo/bar.js' },
      { name: 'change_dir', input: { path: '/home/user' }, expected: '/home/user' },
      { name: 'keyword_search', input: { query: 'find parsers' }, expected: 'find parsers' },
      { name: 'browser', input: { action: 'navigate', url: 'https://example.com' }, expected: 'https://example.com' },
      { name: 'subagent', input: { slug: 'helper', prompt: 'Do something' }, expected: 'helper: Do something' },
      { name: 'read_image', input: { path: '/tmp/screenshot.png' }, expected: '/tmp/screenshot.png' },
    ];

    for (const { name, input, expected } of tools) {
      const line = [
        HEADER,
        makeMessage('assistant', [
          { Type: 5, ID: 'x', ToolName: name, ToolInput: input },
        ]),
      ].join('\n');
      const result = parse(line);
      expect(result.messages[0].content[0].input).toBe(expected);
    }
  });

  it('extracts metadata from header', () => {
    const input = [
      HEADER,
      makeMessage('user', [{ Type: 2, Text: 'Hello' }]),
    ].join('\n');

    const result = parse(input);
    expect(result.metadata.tool_name).toBe('shelley');
    expect(result.metadata.session_id).toBe('c6LDV63');
    expect(result.metadata.slug).toBe('my-session');
    expect(result.metadata.model).toBe('claude-sonnet-4.5');
    expect(result.metadata.working_directory).toBe('/home/user/project');
    expect(result.metadata.start_time).toBe('2025-01-01T00:00:00Z');
    expect(result.metadata.end_time).toBe('2025-01-01T01:00:00Z');
    expect(result.metadata.total_messages).toBe(1);
  });

  it('handles thinking blocks by skipping them', () => {
    const input = [
      HEADER,
      makeMessage('assistant', [
        { Type: 3, Thinking: 'Let me think about this...' },
        { Type: 2, Text: 'Here is my answer' },
      ]),
    ].join('\n');

    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content).toHaveLength(1);
    expect(result.messages[0].content[0].text).toBe('Here is my answer');
  });

  it('handles assistant messages with text and tool_use', () => {
    const input = [
      HEADER,
      makeMessage('assistant', [
        { Type: 2, Text: 'Let me check that file.' },
        { Type: 5, ID: 't1', ToolName: 'bash', ToolInput: { command: 'cat foo.txt' } },
      ]),
    ].join('\n');

    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content).toHaveLength(2);
    expect(result.messages[0].content[0].type).toBe('text');
    expect(result.messages[0].content[1].type).toBe('tool_call');
  });

  it('skips tool_result blocks in user messages (only text is kept)', () => {
    const input = [
      HEADER,
      makeMessage('user', [
        { Type: 6, ToolUseID: 'id1', ToolResult: [{ Type: 2, Text: 'result' }] },
      ]),
    ].join('\n');

    const result = parse(input);
    expect(result.messages).toHaveLength(0);
  });

  it('handles empty content gracefully', () => {
    const result = parse('');
    expect(result.messages).toHaveLength(0);
  });

  it('handles messages without header', () => {
    const input = [
      makeMessage('user', [{ Type: 2, Text: 'Hello' }], { timestamp: '2025-01-01T00:00:00Z' }),
      makeMessage('assistant', [{ Type: 2, Text: 'Hi' }], { timestamp: '2025-01-01T00:01:00Z' }),
    ].join('\n');

    const result = parse(input);
    expect(result.messages).toHaveLength(2);
    expect(result.metadata.tool_name).toBe('shelley');
    expect(result.metadata.start_time).toBe('2025-01-01T00:00:00Z');
    expect(result.metadata.end_time).toBe('2025-01-01T00:01:00Z');
  });

  it('handles tool errors', () => {
    const input = [
      HEADER,
      makeMessage('assistant', [
        { Type: 5, ID: 'err1', ToolName: 'bash', ToolInput: { command: 'bad-cmd' } },
      ]),
      makeMessage('user', [
        {
          Type: 6,
          ToolUseID: 'err1',
          ToolError: true,
          ToolResult: [{ Type: 2, Text: 'command not found' }],
        },
      ]),
    ].join('\n');

    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].output).toBe('command not found');
  });

  it('preserves full tool output (no truncation)', () => {
    const longOutput = 'x'.repeat(3000);
    const input = [
      HEADER,
      makeMessage('assistant', [
        { Type: 5, ID: 't1', ToolName: 'bash', ToolInput: { command: 'cat bigfile' } },
      ]),
      makeMessage('user', [
        {
          Type: 6,
          ToolUseID: 't1',
          ToolResult: [{ Type: 2, Text: longOutput }],
        },
      ]),
    ].join('\n');

    const result = parse(input);
    expect(result.messages[0].content[0].output).toBe(longOutput);
  });

  it('handles multiple tool results in one user message', () => {
    const input = [
      HEADER,
      makeMessage('assistant', [
        { Type: 5, ID: 'a', ToolName: 'bash', ToolInput: { command: 'echo a' } },
        { Type: 5, ID: 'b', ToolName: 'bash', ToolInput: { command: 'echo b' } },
      ]),
      makeMessage('user', [
        { Type: 6, ToolUseID: 'a', ToolResult: [{ Type: 2, Text: 'output-a' }] },
        { Type: 6, ToolUseID: 'b', ToolResult: [{ Type: 2, Text: 'output-b' }] },
      ]),
    ].join('\n');

    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].output).toBe('output-a');
    expect(result.messages[0].content[1].output).toBe('output-b');
  });
});
