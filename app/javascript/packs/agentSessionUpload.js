/**
 * Client-side session parsing for the agent session upload page.
 * Reads the file locally, parses it, scrubs secrets, then hands off to the curator.
 */
import { parseSessionFile, detectTool } from '../agentSessionParsers/index.js';

(function() {
  if (typeof window === 'undefined') return;

  window.AgentSessionUpload = {
    parseSessionFile: parseSessionFile,
    detectTool: detectTool,
  };
})();
