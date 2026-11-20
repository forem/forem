import * as preact from 'preact';
import * as hooks from 'preact/hooks';
import * as compat from 'preact/compat';

if (typeof window !== 'undefined' && !window.__foremPreact) {
  window.__foremPreact = {
    preact,
    hooks,
    compat,
  };
}

export const sharedPreactRuntime =
  typeof window !== 'undefined' && window.__foremPreact
    ? window.__foremPreact
    : { preact, hooks, compat };
