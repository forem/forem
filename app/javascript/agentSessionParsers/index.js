import { detectTool, detectAndParse, parserFor } from './autoDetect.js';
import { scrub, scrubText } from './sensitiveDataScrubber.js';

export { detectTool, detectAndParse, parserFor };
export { scrub, scrubText };

/**
 * Parse a session file's content client-side.
 *
 * @param {string} content - The raw file content
 * @param {string} [toolName] - Explicit tool name, or 'auto'/null for auto-detection
 * @returns {{ messages: Array, metadata: Object, toolName: string, redactions: Array }}
 */
export function parseSessionFile(content, toolName) {
  let detectedTool;
  let result;

  if (!toolName || toolName === 'auto') {
    const detected = detectAndParse(content);
    detectedTool = detected.toolName;
    result = detected.result;
  } else {
    detectedTool = toolName;
    const parser = parserFor(toolName);
    result = parser.parse(content);
  }

  // Scrub secrets
  const scrubResult = scrub(result);

  return {
    messages: scrubResult.scrubbed_data.messages,
    metadata: scrubResult.scrubbed_data.metadata,
    toolName: detectedTool,
    redactions: scrubResult.redactions,
  };
}
