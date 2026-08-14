import {
  buildResult, buildMessage, textBlock, toolCallBlock,
  truncateOutput, truncateStr,
} from './base.js';

export function parse(rawContent) {
  const data = JSON.parse(rawContent);
  const messages = [];

  for (const message of data.messages || []) {
    const role = normalizeRole(message.info?.role);
    if (!role) continue;

    const contentBlocks = extractContentBlocks(message.parts || []);
    if (contentBlocks.length === 0) continue;

    messages.push(buildMessage({
      role,
      contentBlocks,
      timestamp: timestampFromTime(message.info?.time),
      model: modelName(message.info?.model || message.info),
    }));
  }

  return buildResult(messages, extractMetadata(data, messages));
}

function normalizeRole(role) {
  if (role === 'user') return 'user';
  if (role === 'assistant') return 'assistant';
  return null;
}

function extractContentBlocks(parts) {
  const blocks = [];

  for (const part of parts) {
    switch (part.type) {
      case 'text':
      case 'reasoning':
        if (part.text) blocks.push(textBlock(part.text));
        break;
      case 'tool':
        blocks.push(toolCallBlock({
          name: part.tool || 'tool_call',
          input: formatToolInput(part.state?.input),
          output: formatToolOutput(part.state?.output),
          toolCallId: part.callID,
        }));
        break;
      case 'file':
        blocks.push(textBlock(`[File attachment: ${part.filename || part.mime || 'file'}]`));
        break;
    }
  }

  return blocks;
}

function formatToolInput(input) {
  if (input == null) return undefined;
  if (typeof input === 'string') return truncateStr(input, 200);
  return truncateStr(JSON.stringify(input), 200);
}

function formatToolOutput(output) {
  if (output == null) return undefined;
  if (typeof output === 'string') return truncateOutput(output);
  return truncateOutput(JSON.stringify(output));
}

function timestampFromTime(time) {
  if (!time?.created) return undefined;
  return new Date(time.created).toISOString();
}

function modelName(model) {
  if (!model) return undefined;
  return [model.providerID, model.modelID].filter(Boolean).join('/');
}

function extractMetadata(data, messages) {
  const meta = {
    tool_name: 'opencode',
    total_messages: messages.length,
  };

  if (data.info?.id) meta.session_id = data.info.id;
  if (data.info?.title) meta.title = data.info.title;
  if (data.info?.directory) meta.working_directory = data.info.directory;
  if (data.info?.time?.created) meta.start_time = new Date(data.info.time.created).toISOString();
  if (data.info?.time?.updated) meta.end_time = new Date(data.info.time.updated).toISOString();

  const model = data.messages
    ?.map(m => m.info?.model || m.info)
    .find(m => m?.providerID || m?.modelID);
  if (model) meta.model = modelName(model);

  return meta;
}
