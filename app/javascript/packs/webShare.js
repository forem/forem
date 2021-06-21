import 'web-share-wrapper';
// class WebShareWrapper extends HTMLElement {
//   constructor() {
//     super();
//
//     this.webShare = 'share' in navigator;
//     if (this.webShare) {
//       const templateId = this.getTemplateId();
//       if (templateId !== null) {
//         const template = document.getElementById(templateId);
//         if (!template) {
//           return;
//         }
//         this.removeChildren();
//         const clone = document.importNode(template.content, true);
//         this.appendChild(clone);
//       } else {
//         this.text = document.createTextNode(
//           this.getAttribute('text') || 'Share'
//         );
//         this.button = document.createElement('button');
//         this.button.appendChild(this.text);
//         this.removeChildren();
//         this.appendChild(this.button);
//       }
//       this.share = this.share.bind(this);
//     }
//   }
//
//   share(event) {
//     event.preventDefault();
//     const shareOptions = {
//       title: this.getTitle(),
//       text: this.getText(),
//       url: this.getUrl()
//     };
//     navigator
//       .share(shareOptions)
//       .then(() => this.successfulShare(shareOptions))
//       .catch(error => this.abortedShare(error, shareOptions));
//   }
//
//   connectedCallback() {
//     if (this.webShare) {
//       this.addEventListener('click', this.share);
//     }
//   }
//
//   disconnectedCallback() {
//     if (this.webShare) {
//       this.removeEventListener('click', this.share);
//     }
//   }
//
//   successfulShare(options) {
//     const event = new CustomEvent('share-success', options);
//     this.dispatchEvent(event, {
//       detail: options
//     });
//   }
//
//   abortedShare(error, options) {
//     options['error'] = error;
//     const event = new CustomEvent('share-failure', {
//       detail: options
//     });
//     this.dispatchEvent(event);
//   }
//
//   getTitle() {
//     return this.getAttribute('sharetitle');
//   }
//
//   getText() {
//     return (
//       this.getAttribute('sharetext') ||
//       document.querySelector('title').textContent
//     );
//   }
//
//   getUrl() {
//     if (this.getAttribute('shareurl')) {
//       return this.getAttribute('shareurl');
//     }
//     const canonicalElement = document.querySelector('link[rel=canonical]');
//     if (canonicalElement !== null) {
//       return canonicalElement.getAttribute('href');
//     }
//     return window.location.href;
//   }
//
//   getTemplateId() {
//     return this.getAttribute('template');
//   }
//
//   removeChildren() {
//     while (this.firstChild) {
//       this.removeChild(this.firstChild);
//     }
//   }
// }
//
// if ('customElements' in window) {
//   try {
//     customElements.define('web-share-wrapper', WebShareWrapper);
//   } catch (e) {
//     Function.prototype();
//   }
// }
//
// export default WebShareWrapper;
