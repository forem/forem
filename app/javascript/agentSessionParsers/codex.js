import {
  parseJsonlLines, buildResult, buildMessage, textBlock, toolCallBlock,
  truncateOutput, truncateStr, attachOutputToToolCall,
} from './base.js';

const TEXT_CONTENT_TYPES = new Set(['output_text', 'input_text', 'text']);

export function parse(rawContent) {
  const records = parseJsonlLines(rawContent);
  const messages = [];
  let currentAssistantBlocks = [];

  const sessionModel = extractSessionModel(records);

  for (const record of records) {
    switch (record.type) {
      case 'event_msg':
        handleEventMsg(record, messages, currentAssistantBlocks, sessionModel);
        currentAssistantBlocks = [];
        break;
      case 'response_item':
        currentAssistantBlocks = handleResponseItem(record, messages, currentAssistantBlocks, sessionModel);
        break;
      case 'item.completed':
        currentAssistantBlocks = handleItemCompleted(record, messages, currentAssistantBlocks, sessionModel);
        break;
      case 'turn.completed':
      case 'turn_context':
        flushAssistantBlocks(messages, currentAssistantBlocks, sessionModel);
        currentAssistantBlocks = [];
        break;
    }
  }

  flushAssistantBlocks(messages, currentAssistantBlocks, sessionModel);

  const metadata = extractMetadata(records, messages);
  return buildResult(messages, metadata);
}

function handleEventMsg(record, messages, currentBlocks, sessionModel) {
  const payload = record.payload || {};
  if (payload.type !== 'user_message') return;

  flushAssistantBlocks(messages, currentBlocks, sessionModel);
  const text = payload.message || payload.text || payload.content?.[0]?.text || '';
  if (!text) return;

  messages.push(buildMessage({ role: 'user', contentBlocks: [textBlock(text)], model: sessionModel }));
}

function handleResponseItem(record, messages, currentBlocks, sessionModel) {
  const payload = record.payload || {};
  const role = payload.role;
  const itemType = payload.type;

  switch (itemType) {
    case 'message': {
      if (role === 'assistant') {
        const text = extractResponseItemText(payload);
        if (text) {
          currentBlocks = flushToolCallBlocks(messages, currentBlocks, sessionModel);
          currentBlocks.push(textBlock(text));
        }
      }
      break;
    }
    case 'function_call':
    case 'custom_tool_call': {
      flushAssistantBlocks(messages, currentBlocks, sessionModel);
      currentBlocks = [];
      const name = payload.name || payload.call_id || 'tool_call';
      const input = payload.arguments || payload.input;
      const inputStr = typeof input === 'string' ? truncateStr(input, 200) : truncateStr(JSON.stringify(input), 200);
      currentBlocks.push(toolCallBlock({ name, input: inputStr }));
      flushAssistantBlocks(messages, currentBlocks, sessionModel);
      currentBlocks = [];
      break;
    }
    case 'function_call_output':
    case 'custom_tool_call_output': {
      const output = extractOutputContent(payload);
      const formatted = truncateOutput(output);
      attachOutputToToolCall(messages, formatted);
      break;
    }
    case 'reasoning': {
      const summary = payload.summary?.[0]?.text;
      if (summary) {
        currentBlocks = flushToolCallBlocks(messages, currentBlocks, sessionModel);
        currentBlocks.push(textBlock(summary));
      }
      break;
    }
  }

  return currentBlocks;
}

function handleItemCompleted(record, messages, currentBlocks, sessionModel) {
  const item = record.item || {};
  const itemType = item.type;

  switch (itemType) {
    case 'message': {
      const text = extractMessageText(item);
      if (text) {
        currentBlocks = flushToolCallBlocks(messages, currentBlocks, sessionModel);
        currentBlocks.push(textBlock(text));
      }
      break;
    }
    case 'function_call':
    case 'command': {
      currentBlocks = flushTextBlocks(messages, currentBlocks, sessionModel);
      const name = item.name || item.command || 'command';
      const input = item.arguments || item.input || item.command;
      const rawOutput = item.output || item.result;
      const outputText = unwrapJsonOutput(rawOutput);
      const inputStr = typeof input === 'string' ? input : truncateStr(JSON.stringify(input), 200);
      const outputStr = typeof outputText === 'string' ? outputText : JSON.stringify(outputText);
      currentBlocks.push(toolCallBlock({
        name,
        input: inputStr,
        output: truncateOutput(outputStr),
      }));
      flushAssistantBlocks(messages, currentBlocks, sessionModel);
      currentBlocks = [];
      break;
    }
    case 'file_change': {
      currentBlocks = flushTextBlocks(messages, currentBlocks, sessionModel);
      const path = item.file_path || item.path;
      currentBlocks.push(toolCallBlock({
        name: 'FileChange',
        input: path,
        output: truncateOutput(item.diff || item.content),
      }));
      flushAssistantBlocks(messages, currentBlocks, sessionModel);
      currentBlocks = [];
      break;
    }
  }

  return currentBlocks;
}

function extractResponseItemText(payload) {
  const content = payload.content;
  if (typeof content === 'string') return content;
  if (Array.isArray(content)) {
    return content
      .filter(c => TEXT_CONTENT_TYPES.has(c.type) && c.text)
      .map(c => c.text)
      .join('\n') || null;
  }
  return payload.text || null;
}

function extractMessageText(item) {
  const content = item.content;
  if (typeof content === 'string') return content;
  if (Array.isArray(content)) {
    return content
      .filter(c => c.type === 'text' && c.text)
      .map(c => c.text)
      .join('\n') || null;
  }
  return item.text || null;
}

function extractOutputContent(payload) {
  const raw = payload.output || payload.result;
  return unwrapJsonOutput(raw);
}

function unwrapJsonOutput(raw) {
  if (raw && typeof raw === 'object' && !Array.isArray(raw)) {
    return raw.output || raw.content || JSON.stringify(raw);
  }
  if (typeof raw === 'string') {
    if (raw.trim().startsWith('{')) {
      try {
        const parsed = JSON.parse(raw);
        if (parsed && typeof parsed === 'object') {
          return parsed.output || parsed.content || raw;
        }
      } catch {
        // Not JSON
      }
    }
    return raw;
  }
  return raw != null ? JSON.stringify(raw) : null;
}

function extractSessionModel(records) {
  const sessionMeta = records.find(r => r.type === 'session_meta');
  return sessionMeta?.payload?.model_provider || null;
}

function flushAssistantBlocks(messages, blocks, sessionModel) {
  if (blocks.length === 0) return;
  messages.push(buildMessage({ role: 'assistant', contentBlocks: [...blocks], model: sessionModel }));
  blocks.length = 0;
}

function flushToolCallBlocks(messages, blocks, sessionModel) {
  if (blocks.some(b => b.type === 'tool_call')) {
    flushAssistantBlocks(messages, blocks, sessionModel);
    return [];
  }
  return blocks;
}

function flushTextBlocks(messages, blocks, sessionModel) {
  if (blocks.some(b => b.type === 'text')) {
    flushAssistantBlocks(messages, blocks, sessionModel);
    return [];
  }
  return blocks;
}

function extractMetadata(records, messages) {
  const sessionMeta = records.find(r => r.type === 'session_meta');
  const started = records.find(r => r.type === 'thread.started');

  const metaPayload = sessionMeta?.payload || {};
  const meta = {
    tool_name: 'codex',
    total_messages: messages.length,
  };
  if (metaPayload.id || started?.thread_id) meta.session_id = metaPayload.id || started.thread_id;
  if (metaPayload.timestamp || sessionMeta?.timestamp || started?.timestamp) {
    meta.start_time = metaPayload.timestamp || sessionMeta?.timestamp || started?.timestamp;
  }
  if (metaPayload.model_provider) meta.model = metaPayload.model_provider;
  if (metaPayload.cli_version) meta.cli_version = metaPayload.cli_version;

  return meta;
}
