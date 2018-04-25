import { h, render } from 'preact';
import SidebarWidget from '../sidebar-widget/SidebarWidget';

HTMLDocument.prototype.ready = new Promise(resolve => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
});

render(<SidebarWidget />, document.getElementById('sidebarWidget__pack'));
