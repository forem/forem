import { initializeMermaidDiagrams } from '@utilities/mermaidDiagrams';

const SCRIPT_PATH = '/assets/mermaidRenderer-abc123.js';

function addScriptMeta() {
  const meta = document.createElement('meta');
  meta.name = 'mermaid-script';
  meta.content = SCRIPT_PATH;
  document.head.appendChild(meta);
}

function loadedScripts() {
  return document.head.querySelectorAll(`script[src="${SCRIPT_PATH}"]`);
}

describe('initializeMermaidDiagrams', () => {
  beforeEach(() => {
    document.head.innerHTML = '';
    document.body.innerHTML = '';
    delete window.renderMermaidDiagrams;
  });

  it('does not load the bundle when the page has no diagram', () => {
    addScriptMeta();
    document.body.innerHTML = '<pre data-lang="ruby"><code>puts 1</code></pre>';

    initializeMermaidDiagrams();

    expect(loadedScripts()).toHaveLength(0);
  });

  it('loads the bundle when a diagram is present', () => {
    addScriptMeta();
    document.body.innerHTML =
      '<pre data-lang="mermaid"><code>graph TD;</code></pre>';

    initializeMermaidDiagrams();

    const scripts = loadedScripts();
    expect(scripts).toHaveLength(1);
    expect(scripts[0].defer).toBe(true);
  });

  it('loads the bundle only once', () => {
    addScriptMeta();
    document.body.innerHTML =
      '<pre data-lang="mermaid"><code>graph TD;</code></pre>';

    initializeMermaidDiagrams();
    initializeMermaidDiagrams();

    expect(loadedScripts()).toHaveLength(1);
  });

  it('renders through the loaded bundle instead of reloading it', () => {
    addScriptMeta();
    document.body.innerHTML =
      '<pre data-lang="mermaid"><code>graph TD;</code></pre>';
    window.renderMermaidDiagrams = jest.fn();

    initializeMermaidDiagrams();

    expect(window.renderMermaidDiagrams).toHaveBeenCalledWith(document);
    expect(loadedScripts()).toHaveLength(0);
  });

  it('scopes detection to the given root', () => {
    addScriptMeta();
    document.body.innerHTML =
      '<div id="preview"></div><pre data-lang="mermaid"><code>graph TD;</code></pre>';

    initializeMermaidDiagrams(document.getElementById('preview'));

    expect(loadedScripts()).toHaveLength(0);
  });

  it('does nothing without the script meta tag', () => {
    document.body.innerHTML =
      '<pre data-lang="mermaid"><code>graph TD;</code></pre>';

    expect(() => initializeMermaidDiagrams()).not.toThrow();
    expect(loadedScripts()).toHaveLength(0);
  });

  it('does nothing when handed something that is not a DOM root', () => {
    addScriptMeta();

    expect(() => initializeMermaidDiagrams(null)).not.toThrow();
    expect(loadedScripts()).toHaveLength(0);
  });
});
