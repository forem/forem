import { h } from 'preact';
import SidebarWidget from '../sidebar-widget/SidebarWidget';
import { render } from '@utilities/preact/render';

HTMLDocument.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  return document.addEventListener('DOMContentLoaded', () => resolve());
});

if (document.getElementById('widget-00001') === null) {
  render(<SidebarWidget />, document.getElementById('sidebarWidget__pack'));
}
