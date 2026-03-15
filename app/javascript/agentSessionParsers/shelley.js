import {
  parseJsonlLines, buildResult, buildMessage, textBlock, toolCallBlock,
  truncateOutput, truncateStr,
} from './base.js';

/**
 * Parser for Shelley coding agent conversation exports.
 *
 * Shelley stores conversations in a SQLite database. The export format is JSONL
 * with a header line of type "shelley_session" followed by message lines.
 *
 * Each message line has:
 *   - type: "message"
 *   - role: "user" | "assistant" | "system"
 *   - sequence_id: integer
 *   - timestamp: ISO 8601
 *   - content: array of content blocks with:
 *       Type 2 = text, Type 3 = thinking, Type 5 = tool_use, Type 6 = tool_result
 */

export function parse(rawContent) {
  const records = parseJsonlLines(rawContent);
  const header = records.find(r => r.type === 'shelley_session');
  const messageRecords = records.filter(r => r.type === 'message');

  // Build a map from tool_use ID -> tool result for pairing
  const toolResultsMap = buildToolResultsMap(messageRecords);

  const messages = [];
  for (const record of messageRecords) {
    if (record.role === 'system') continue;

    const blocks = record.content;
    if (!Array.isArray(blocks) || blocks.length === 0) continue;

    const role = record.role === 'assistant' ? 'assistant' : 'user';
    const timestamp = record.timestamp;
    const model = record.model;

    if (role === 'user') {
      const contentBlocks = parseUserContent(blocks);
      if (contentBlocks.length === 0) continue;
      messages.push(buildMessage({ role: 'user', contentBlocks, timestamp, model }));
    } else {
      const contentBlocks = parseAssistantContent(blocks, toolResultsMap);
      if (contentBlocks.length === 0) continue;
      messages.push(buildMessage({ role: 'assistant', contentBlocks, timestamp, model }));
    }
  }

  const metadata = extractMetadata(header, records, messages);
  return buildResult(messages, metadata);
}

function buildToolResultsMap(records) {
  const map = {};
  for (const record of records) {
    if (record.role !== 'user') continue;
    const content = record.content;
    if (!Array.isArray(content)) continue;
    for (const block of content) {
      // Type 6 = tool_result in Shelley format
      if (block.Type !== 6) continue;
      const toolUseId = block.ToolUseID;
      if (!toolUseId) continue;
      const resultText = extractToolResultText(block);
      map[toolUseId] = {
        text: resultText,
        error: block.ToolError || false,
        startTime: block.ToolUseStartTime,
        endTime: block.ToolUseEndTime,
      };
    }
  }
  return map;
}

function extractToolResultText(block) {
  const results = block.ToolResult;
  if (!Array.isArray(results)) return '';
  return results
    .filter(r => r.Type === 2 && r.Text)  // Type 2 = text
    .map(r => r.Text)
    .join('\n');
}

function parseUserContent(blocks) {
  const contentBlocks = [];
  for (const block of blocks) {
    if (block.Type === 2 && block.Text) {
      contentBlocks.push(textBlock(block.Text));
    }
    // Skip Type 6 (tool_result) blocks — they're merged into assistant tool_call outputs
  }
  return contentBlocks;
}

function parseAssistantContent(blocks, toolResultsMap) {
  const contentBlocks = [];
  for (const block of blocks) {
    if (block.Type === 2 && block.Text) {
      // Type 2 = text
      contentBlocks.push(textBlock(block.Text));
    } else if (block.Type === 5) {
      // Type 5 = tool_use
      const toolName = block.ToolName || 'unknown';
      const inputSummary = summarizeToolInput(toolName, block.ToolInput);
      const result = toolResultsMap[block.ID];
      const output = result ? truncateOutput(result.text) : undefined;
      contentBlocks.push(toolCallBlock({
        name: toolName,
        input: inputSummary,
        output,
        toolCallId: block.ID,
      }));
    }
    // Skip Type 3 (thinking) blocks
  }
  return contentBlocks;
}

function summarizeToolInput(name, input) {
  if (!input || typeof input !== 'object') return undefined;

  switch (name) {
    case 'bash':
      return input.command;
    case 'patch':
      return input.path;
    case 'keyword_search':
      return input.query ? truncateStr(input.query, 100) : undefined;
    case 'change_dir':
      return input.path;
    case 'browser':
      return input.url || input.action;
    case 'browser_emulate':
    case 'browser_network':
    case 'browser_accessibility':
    case 'browser_profile':
      return input.action;
    case 'output_iframe':
      return input.path || input.title;
    case 'subagent':
      return input.slug ? `${input.slug}: ${truncateStr(input.prompt, 80)}` : truncateStr(input.prompt, 100);
    case 'llm_one_shot':
      return input.prompt_file;
    case 'read_image':
      return input.path;
    default:
      return truncateStr(JSON.stringify(input), 200);
  }
}

function extractMetadata(header, records, messages) {
  const meta = {
    tool_name: 'shelley',
    total_messages: messages.length,
  };

  if (header) {
    if (header.conversation_id) meta.session_id = header.conversation_id;
    if (header.slug) meta.slug = header.slug;
    if (header.model) meta.model = header.model;
    if (header.cwd) meta.working_directory = header.cwd;
    if (header.created_at) meta.start_time = header.created_at;
    if (header.updated_at) meta.end_time = header.updated_at;
  }

  // Fall back to timestamps from first/last messages
  const msgRecords = records.filter(r => r.type === 'message' && r.role !== 'system');
  if (!meta.start_time && msgRecords.length > 0 && msgRecords[0].timestamp) {
    meta.start_time = msgRecords[0].timestamp;
  }
  if (!meta.end_time && msgRecords.length > 0) {
    const last = msgRecords[msgRecords.length - 1];
    if (last.timestamp) meta.end_time = last.timestamp;
  }

  return meta;
}
