import { h, render } from 'preact';
import SidebarWidget from '../sidebar-widget/SidebarWidget';

HTMLDocument.prototype.ready = new Promise(resolve => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());

  return null;
});

if (document.getElementById('widget-00001') === null) {
  render(<SidebarWidget />, document.getElementById('sidebarWidget__pack'));
}
