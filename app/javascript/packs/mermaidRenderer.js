import mermaid from 'mermaid';
import DOMPurify from 'dompurify';

const DIAGRAM_SELECTOR = 'pre[data-lang="mermaid"]:not([data-mermaid-state])';
const MAX_SOURCE_LENGTH = 20000;
const MAX_LINES = 500;
const MAX_EDGES = 500;
const RENDER_TIMEOUT_MS = 8000;
const SANITIZE_CONFIG = { USE_PROFILES: { svg: true, svgFilters: true } };

let diagramCount = 0;

mermaid.initialize({
  startOnLoad: false,
  securityLevel: 'strict',
  htmlLabels: false,
  suppressErrorRendering: true,
  maxTextSize: MAX_SOURCE_LENGTH,
  maxEdges: MAX_EDGES,
  fontFamily: 'inherit',
  theme: document.body?.classList.contains('dark-theme') ? 'dark' : 'default',
  flowchart: { htmlLabels: false },
  class: { htmlLabels: false },
});

function withinLimits(source) {
  return (
    source.length > 0 &&
    source.length <= MAX_SOURCE_LENGTH &&
    source.split('\n').length <= MAX_LINES
  );
}

function renderWithTimeout(id, source) {
  let timeoutId;
  const timeout = new Promise((_resolve, reject) => {
    timeoutId = setTimeout(
      () => reject(new Error('Mermaid render timed out')),
      RENDER_TIMEOUT_MS,
    );
  });

  return Promise.race([mermaid.render(id, source), timeout]).finally(() =>
    clearTimeout(timeoutId),
  );
}

async function renderDiagram(element) {
  const source = element.textContent.trim();

  if (!withinLimits(source)) {
    element.setAttribute('data-mermaid-state', 'skipped');
    return;
  }

  element.setAttribute('data-mermaid-state', 'rendering');
  diagramCount += 1;
  const id = `mermaid-diagram-${diagramCount}`;

  try {
    const { svg } = await renderWithTimeout(id, source);
    const figure = document.createElement('figure');
    figure.className = 'mermaid-diagram';
    figure.setAttribute('data-mermaid-state', 'rendered');
    figure.innerHTML = DOMPurify.sanitize(svg, SANITIZE_CONFIG);
    element.replaceWith(figure);
  } catch (error) {
    element.setAttribute('data-mermaid-state', 'error');
    console.error('Unable to render Mermaid diagram', error);
  } finally {
    // Mermaid leaves its off-screen render sandbox behind when a render fails.
    document.getElementById(`d${id}`)?.remove();
  }
}

export async function renderMermaidDiagrams(root = document) {
  if (typeof root?.querySelectorAll !== 'function') {
    return;
  }

  const elements = Array.from(root.querySelectorAll(DIAGRAM_SELECTOR));

  // Rendered one at a time so a page full of diagrams cannot saturate the main thread.
  for (const element of elements) {
    await renderDiagram(element);
  }
}

window.renderMermaidDiagrams = renderMermaidDiagrams;

renderMermaidDiagrams();
