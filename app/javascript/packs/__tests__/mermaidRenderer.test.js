import mermaid from 'mermaid';
import { renderMermaidDiagrams } from '../mermaidRenderer';

jest.mock('mermaid', () => ({
  __esModule: true,
  default: { initialize: jest.fn(), render: jest.fn() },
}));

const addDiagram = (source = 'flowchart TD\n A --> B') => {
  document.body.innerHTML = `<pre data-lang="mermaid"><code>${source}</code></pre>`;
};

const renderedFigure = () => document.querySelector('figure.mermaid-diagram');

describe('renderMermaidDiagrams', () => {
  afterEach(() => {
    document.body.innerHTML = '';
    jest.clearAllMocks();
  });

  it('strips script elements from the rendered diagram', async () => {
    addDiagram();
    mermaid.render.mockResolvedValue({
      svg: '<svg><script>window.pwned = true;</script><text>Start</text></svg>',
    });

    await renderMermaidDiagrams();

    expect(renderedFigure().innerHTML).not.toContain('<script');
    expect(renderedFigure().innerHTML).toContain('Start');
  });

  it('strips inline event handlers from the rendered diagram', async () => {
    addDiagram();
    mermaid.render.mockResolvedValue({
      svg: '<svg><g onload="window.pwned = true"><text>Start</text></g></svg>',
    });

    await renderMermaidDiagrams();

    expect(renderedFigure().innerHTML).not.toContain('onload');
  });

  it('strips javascript: urls from the rendered diagram', async () => {
    addDiagram();
    mermaid.render.mockResolvedValue({
      svg: '<svg><a href="javascript:window.pwned = true"><text>Start</text></a></svg>',
    });

    await renderMermaidDiagrams();

    expect(renderedFigure().innerHTML).not.toContain('javascript:');
  });

  it('preserves the svg elements a diagram is built from', async () => {
    addDiagram();
    mermaid.render.mockResolvedValue({
      svg: '<svg><g><path d="M0 0"></path><text>Start</text><marker></marker></g></svg>',
    });

    await renderMermaidDiagrams();

    const { innerHTML } = renderedFigure();
    expect(innerHTML).toContain('<path');
    expect(innerHTML).toContain('<text');
    expect(innerHTML).toContain('<marker');
  });

  it('leaves the original code block in place when rendering fails', async () => {
    addDiagram();
    mermaid.render.mockRejectedValue(new Error('bad diagram'));

    await renderMermaidDiagrams();

    expect(renderedFigure()).toBeNull();
    expect(
      document.querySelector('pre[data-mermaid-state="error"]'),
    ).not.toBeNull();
  });
});
