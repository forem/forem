import {
  parseJsonlLines, buildResult, buildMessage, textBlock, toolCallBlock,
  truncateOutput, truncateStr,
} from './base.js';

const CONVERSATION_TYPES = new Set(['user', 'assistant']);

export function parse(rawContent) {
  const records = parseJsonlLines(rawContent);
  const conversationRecords = records.filter(r => CONVERSATION_TYPES.has(r.type));

  const messages = [];
  const toolResultsMap = buildToolResultsMap(conversationRecords);

  for (const record of conversationRecords) {
    const msg = record.message;
    if (!msg) continue;

    const role = msg.role;
    const timestamp = record.timestamp;
    const model = msg.model;
    const rawContentBlocks = msg.content;

    if (role === 'user') {
      const contentBlocks = parseUserContent(rawContentBlocks);
      if (contentBlocks.length === 0) continue;
      messages.push(buildMessage({ role: 'user', contentBlocks, timestamp, model }));
    } else if (role === 'assistant') {
      const contentBlocks = parseAssistantContent(rawContentBlocks, toolResultsMap);
      if (contentBlocks.length === 0) continue;
      messages.push(buildMessage({ role: 'assistant', contentBlocks, timestamp, model }));
    }
  }

  const metadata = extractMetadata(records, messages);
  return buildResult(messages, metadata);
}

function buildToolResultsMap(records) {
  const map = {};
  for (const record of records) {
    if (record.message?.role !== 'user') continue;
    const content = record.message?.content;
    if (!Array.isArray(content)) continue;
    for (const block of content) {
      if (block.type !== 'tool_result') continue;
      const toolUseId = block.tool_use_id;
      const resultContent = extractToolResultContent(block);
      map[toolUseId] = resultContent;
    }
  }
  return map;
}

function extractToolResultContent(block) {
  const content = block.content;
  if (typeof content === 'string') return truncateOutput(content);
  if (Array.isArray(content)) {
    const text = content
      .filter(c => c.type === 'text' && c.text)
      .map(c => c.text)
      .join('\n');
    return truncateOutput(text);
  }
  return '';
}

function parseUserContent(rawContent) {
  if (typeof rawContent === 'string') return [textBlock(rawContent)];
  if (!Array.isArray(rawContent)) return [];

  const blocks = [];
  for (const block of rawContent) {
    if (block.type === 'text') {
      blocks.push(textBlock(block.text));
    }
    // Skip tool_result blocks — they're merged into assistant messages
  }
  return blocks;
}

function parseAssistantContent(rawContent, toolResultsMap) {
  if (!Array.isArray(rawContent)) return [];

  const blocks = [];
  for (const block of rawContent) {
    if (block.type === 'text') {
      blocks.push(textBlock(block.text));
    } else if (block.type === 'tool_use') {
      const result = toolResultsMap[block.id];
      const inputSummary = summarizeToolInput(block.name, block.input);
      blocks.push(toolCallBlock({ name: block.name, input: inputSummary, output: result }));
    }
    // Skip "thinking" blocks by default
  }
  return blocks;
}

function summarizeToolInput(name, input) {
  if (!input || typeof input !== 'object') return undefined;

  switch (name) {
    case 'Read':
    case 'Write':
    case 'Edit':
      return input.file_path;
    case 'Bash':
      return input.command;
    case 'Glob':
      return input.pattern;
    case 'Grep':
      return `${input.pattern || ''} ${input.path || ''}`.trim();
    case 'Task':
      return input.description || truncateStr(input.prompt, 100);
    default:
      return truncateStr(JSON.stringify(input), 200);
  }
}

function extractMetadata(records, messages) {
  const conversationTypes = new Set(['user', 'assistant']);
  const firstRecord = records.find(r => conversationTypes.has(r.type));
  const lastRecord = [...records].reverse().find(r => conversationTypes.has(r.type));

  const meta = {
    tool_name: 'claude_code',
    total_messages: messages.length,
  };
  if (firstRecord?.sessionId) meta.session_id = firstRecord.sessionId;
  if (firstRecord?.timestamp) meta.start_time = firstRecord.timestamp;
  if (lastRecord?.timestamp) meta.end_time = lastRecord.timestamp;
  if (firstRecord?.cwd) meta.working_directory = firstRecord.cwd;
  if (firstRecord?.gitBranch) meta.git_branch = firstRecord.gitBranch;

  const modelRecord = records.find(r => r.message?.model);
  if (modelRecord) meta.model = modelRecord.message.model;

  return meta;
}
