import postscribe from 'postscribe';

if (typeof window !== 'undefined') {
  window.Forem = window.Forem || {};
  window.Forem.postscribe = postscribe;
}
