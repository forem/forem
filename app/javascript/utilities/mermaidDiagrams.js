const DIAGRAM_SELECTOR = 'pre[data-lang="mermaid"]';
const SCRIPT_META_SELECTOR = 'meta[name="mermaid-script"]';

function loadMermaidBundle() {
  const scriptPath = document
    .querySelector(SCRIPT_META_SELECTOR)
    ?.getAttribute('content');

  if (!scriptPath || document.querySelector(`script[src="${scriptPath}"]`)) {
    return;
  }

  const script = document.createElement('script');
  script.src = scriptPath;
  script.defer = true;
  document.head.appendChild(script);
}

// Fetches the Mermaid bundle only once a diagram is actually present.
export function initializeMermaidDiagrams(root = document) {
  if (typeof root?.querySelector !== 'function') {
    return;
  }

  if (!root.querySelector(DIAGRAM_SELECTOR)) {
    return;
  }

  if (typeof window.renderMermaidDiagrams === 'function') {
    window.renderMermaidDiagrams(root);
    return;
  }

  loadMermaidBundle();
}
