import { ensurePreactRuntime } from '../ensurePreactRuntime';
import { sharedPreactRuntime } from '../preactRuntime';

describe('ensurePreactRuntime & sharedPreactRuntime', () => {
  beforeEach(() => {
    document.head.innerHTML = '';
    document.body.innerHTML = '';
    delete window.__foremPreact;
    delete window.__foremPreactLoadingPromise;
  });

  afterEach(() => {
    window.__foremPreact = sharedPreactRuntime;
    delete window.__foremPreactLoadingPromise;
  });

  it('exposes preact, hooks, and compat on sharedPreactRuntime', () => {
    expect(sharedPreactRuntime.preact).toBeDefined();
    expect(typeof sharedPreactRuntime.preact.h).toBe('function');
    expect(typeof sharedPreactRuntime.preact.render).toBe('function');
    expect(typeof sharedPreactRuntime.hooks.useState).toBe('function');
    expect(typeof sharedPreactRuntime.compat.forwardRef).toBe('function');
  });

  it('executes runPack synchronously when window.__foremPreact is already present', () => {
    window.__foremPreact = sharedPreactRuntime;
    const order = [];

    const result = ensurePreactRuntime(() => {
      order.push('pack-ran');
      return 'sync-result';
    });
    order.push('after-call');

    expect(result).toBe('sync-result');
    expect(order).toEqual(['pack-ran', 'after-call']);
    expect(
      document.querySelector('script[data-preact-runtime-script="true"]'),
    ).toBeNull();
  });

  it('loads preactRuntime.js from #page-content[data-preact-runtime-src] on backward cache mismatch and runs queued packs in order', async () => {
    document.body.innerHTML =
      '<div id="page-content" data-preact-runtime-src="/assets/preactRuntime-abc123.js"></div>';

    const executionOrder = [];
    const firstPackPromise = ensurePreactRuntime(() => {
      executionOrder.push('first-pack');
    });
    const secondPackPromise = ensurePreactRuntime(() => {
      executionOrder.push('second-pack');
    });

    const scripts = document.querySelectorAll(
      'script[data-preact-runtime-script="true"]',
    );
    expect(scripts).toHaveLength(1);
    expect(scripts[0].getAttribute('src')).toBe(
      '/assets/preactRuntime-abc123.js',
    );
    expect(executionOrder).toEqual([]);

    window.__foremPreact = sharedPreactRuntime;
    scripts[0].dispatchEvent(new Event('load'));

    await Promise.all([firstPackPromise, secondPackPromise]);
    expect(executionOrder).toEqual(['first-pack', 'second-pack']);
  });

  it('falls back to meta[name="preact-runtime-script"] and then /assets/preactRuntime.js', () => {
    document.head.innerHTML =
      '<meta name="preact-runtime-script" content="/assets/preactRuntime-meta999.js">';

    ensurePreactRuntime(() => {});

    const script = document.querySelector(
      'script[data-preact-runtime-script="true"]',
    );
    expect(script).not.toBeNull();
    expect(script.getAttribute('src')).toBe(
      '/assets/preactRuntime-meta999.js',
    );
  });

  it('removes a failed script element and resets __foremPreactLoadingPromise so subsequent navigations can retry', async () => {
    document.body.innerHTML =
      '<div id="page-content" data-preact-runtime-src="/assets/preactRuntime-abc123.js"></div>';

    const firstAttempt = ensurePreactRuntime(() => 'never');
    const firstScript = document.querySelector(
      'script[data-preact-runtime-script="true"]',
    );
    firstScript.dispatchEvent(new Event('error'));

    await expect(firstAttempt).rejects.toThrow(
      'Failed to load /assets/preactRuntime-abc123.js',
    );
    expect(
      document.querySelector('script[data-preact-runtime-script="true"]'),
    ).toBeNull();
    expect(window.__foremPreactLoadingPromise).toBeNull();

    const retryOrder = [];
    const secondAttempt = ensurePreactRuntime(() => {
      retryOrder.push('retried');
    });
    const retryScript = document.querySelector(
      'script[data-preact-runtime-script="true"]',
    );
    expect(retryScript).not.toBeNull();

    window.__foremPreact = sharedPreactRuntime;
    retryScript.dispatchEvent(new Event('load'));

    await secondAttempt;
    expect(retryOrder).toEqual(['retried']);
  });

  it('renders a Preact component with hooks and compat using window.__foremPreact across both steady-state and backward-cache-mismatch loads', async () => {
    const mountRoot = document.createElement('div');
    document.body.innerHTML =
      '<div id="page-content" data-preact-runtime-src="/assets/preactRuntime-abc123.js"></div>';
    document.body.appendChild(mountRoot);

    const runSecondaryPreactPack = () => {
      const { h, render } = window.__foremPreact.preact;
      const { useState } = window.__foremPreact.hooks;
      const { forwardRef } = window.__foremPreact.compat;

      const Badge = forwardRef(({ label }, ref) => {
        const [count] = useState(42);
        return h('span', { ref, className: 'shared-preact-badge' }, `${label}:${count}`);
      });

      render(h(Badge, { label: 'ready' }), mountRoot);
    };

    const mismatchPromise = ensurePreactRuntime(runSecondaryPreactPack);
    expect(mountRoot.innerHTML).toBe('');

    const runtimeScript = document.querySelector(
      'script[data-preact-runtime-script="true"]',
    );
    window.__foremPreact = sharedPreactRuntime;
    runtimeScript.dispatchEvent(new Event('load'));

    await mismatchPromise;
    expect(mountRoot.querySelector('.shared-preact-badge')?.textContent).toBe(
      'ready:42',
    );
  });
});
