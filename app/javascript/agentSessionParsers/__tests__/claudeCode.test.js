import { parse } from '../claudeCode';

describe('claudeCode parser', () => {
  function makeRecord(type, role, content, extra = {}) {
    return JSON.stringify({
      type,
      message: { role, content },
      timestamp: '2025-01-01T00:00:00Z',
      sessionId: 's1',
      ...extra,
    });
  }

  it('parses user text messages', () => {
    const input = [
      makeRecord('user', 'user', 'Hello world'),
      makeRecord('assistant', 'assistant', [{ type: 'text', text: 'Hi there' }]),
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

  it('parses user messages with array content', () => {
    const input = makeRecord('user', 'user', [{ type: 'text', text: 'Array text' }]);
    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].content[0].text).toBe('Array text');
  });

  it('skips tool_result blocks in user messages', () => {
    const input = makeRecord('user', 'user', [
      { type: 'tool_result', tool_use_id: 'id1', content: 'result text' },
    ]);
    const result = parse(input);
    expect(result.messages).toHaveLength(0);
  });

  it('pairs tool_use with tool_result via ID', () => {
    const input = [
      makeRecord('assistant', 'assistant', [
        { type: 'tool_use', id: 'tool1', name: 'Read', input: { file_path: '/foo.rb' } },
      ]),
      makeRecord('user', 'user', [
        { type: 'tool_result', tool_use_id: 'tool1', content: 'file contents here' },
      ]),
    ].join('\n');

    const result = parse(input);
    expect(result.messages).toHaveLength(1);
    const toolBlock = result.messages[0].content[0];
    expect(toolBlock.type).toBe('tool_call');
    expect(toolBlock.name).toBe('Read');
    expect(toolBlock.input).toBe('/foo.rb');
    expect(toolBlock.output).toBe('file contents here');
  });

  it('summarizes tool input for known tools', () => {
    const tools = [
      { name: 'Bash', input: { command: 'ls -la' }, expected: 'ls -la' },
      { name: 'Glob', input: { pattern: '*.rb' }, expected: '*.rb' },
      { name: 'Grep', input: { pattern: 'foo', path: '/src' }, expected: 'foo /src' },
    ];

    for (const { name, input, expected } of tools) {
      const line = makeRecord('assistant', 'assistant', [
        { type: 'tool_use', id: 'x', name, input },
      ]);
      const result = parse(line);
      expect(result.messages[0].content[0].input).toBe(expected);
    }
  });

  it('extracts metadata', () => {
    const input = [
      makeRecord('user', 'user', 'Hello', { cwd: '/home/user/project', gitBranch: 'main' }),
    ].join('\n');

    const result = parse(input);
    expect(result.metadata.tool_name).toBe('claude_code');
    expect(result.metadata.session_id).toBe('s1');
    expect(result.metadata.working_directory).toBe('/home/user/project');
    expect(result.metadata.git_branch).toBe('main');
    expect(result.metadata.total_messages).toBe(1);
  });

  it('truncates long tool output', () => {
    const longOutput = 'x'.repeat(3000);
    const input = [
      makeRecord('assistant', 'assistant', [
        { type: 'tool_use', id: 't1', name: 'Read', input: { file_path: '/f' } },
      ]),
      makeRecord('user', 'user', [
        { type: 'tool_result', tool_use_id: 't1', content: longOutput },
      ]),
    ].join('\n');

    const result = parse(input);
    const output = result.messages[0].content[0].output;
    expect(output.length).toBeLessThan(longOutput.length);
    expect(output).toContain('truncated');
  });

  it('skips non-conversation record types', () => {
    const input = [
      JSON.stringify({ type: 'system', message: { role: 'system', content: 'setup' } }),
      makeRecord('user', 'user', 'Hello'),
    ].join('\n');

    const result = parse(input);
    expect(result.messages).toHaveLength(1);
  });

  it('handles empty content gracefully', () => {
    const result = parse('');
    expect(result.messages).toHaveLength(0);
  });
});
