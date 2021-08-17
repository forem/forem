/**
 * This class helps managing native feature support. Can easily be referenced
 * from anywhere in JavaScript with:
 *
 * if (Runtime.isNativeiOS('video')) { ... }
 *
 * if (Runtime.isNativeAndroid('podcastMessage')) { ... }
 */
class Runtime {
  /**
   * This function returns a string combining the current Medium and OS
   * that represents the current Context where the app is running.
   *
   * @returns {String} "Medium-OS", for example "Browser-Android"
   */
  static currentContext() {
    return `${Runtime.currentMedium()}-${Runtime.currentOS()}`;
  }

  /**
   * This function returns a string that represents the current Medium where
   * the app is currently running. The currently supported mediums are Browser,
   * ForemWebView and PWA.
   *
   * @returns {String} One of the supported Mediums or 'Unsupported'
   */
  static currentMedium() {
    const pwaButtons = document.getElementById('pwa-nav-buttons');
    if (/ForemWebView/i.test(navigator.userAgent)) {
      return 'ForemWebView';
    } else if (pwaButtons.classList.contains('pwa-nav-buttons--showing')) {
      return 'PWA';
    } else {
      return 'Browser';
    }
  }

  /**
   * This function returns a string that represents the current OS where the app
   * is currently running. The currently supported Operating Systems are
   * Windows, Linux, macOS, Android and iOS.
   *
   * @returns {String} One of the supported Operating Systems or 'Unsupported'
   */
  static currentOS() {
    const macosPlatforms = ['Macintosh', 'MacIntel', 'MacPPC', 'Mac68K'];
    const windowsPlatforms = ['Win32', 'Win64', 'Windows', 'WinCE'];
    const iosPlatforms = ['iPhone', 'iPad', 'iPod'];

    if (macosPlatforms.includes(window.navigator.platform)) {
      return 'macOS';
    } else if (iosPlatforms.includes(window.navigator.platform)) {
      return 'iOS';
    } else if (windowsPlatforms.includes(window.navigator.platform)) {
      return 'Windows';
    } else if (/Android/i.test(window.navigator.userAgent)) {
      return 'Android';
    } else if (/Linux/i.test(window.navigator.platform)) {
      return 'Linux';
    }

    return 'Unsupported';
  }

  /**
   * Checks the device for iOS (webkit) native feature support
   *
   * @function isNativeIOS
   * @param {string} namespace Specifies support for a specific feature
   *                           (i.e. video, podcast, etc)
   * @returns {boolean} true if current environment support native features
   */
  static isNativeIOS(namespace = null) {
    const nativeCheck =
      /DEV-Native-ios|ForemWebView/i.test(navigator.userAgent) &&
      window &&
      window.webkit &&
      window.webkit.messageHandlers;

    let namespaceCheck = true;
    if (nativeCheck && namespace) {
      namespaceCheck = window.webkit.messageHandlers[namespace] != undefined;
    }

    return nativeCheck && namespaceCheck;
  }

  /**
   * Checks the device for Android native feature support
   *
   * @function isNativeAndroid
   * @param {string} namespace Specifies support for a specific feature
   *                           (i.e. videoMessage, podcastMessage, etc)
   * @returns {boolean} true if current environment support native features
   */
  static isNativeAndroid(namespace = null) {
    const nativeCheck =
      /DEV-Native-android|ForemWebView/i.test(navigator.userAgent) &&
      typeof AndroidBridge !== 'undefined';

    let namespaceCheck = true;
    if (nativeCheck && namespace) {
      namespaceCheck = AndroidBridge[namespace] != undefined;
    }

    return nativeCheck && namespaceCheck;
  }

  /**
   * This function copies text to clipboard taking in consideration all
   * supported platforms.
   *
   * @param {string} text to be copied to the clipboard
   *
   * @returns {Promise} Resolves when succesful in copying to clipboard
   */
  static copyToClipboard(text) {
    return new Promise((resolve, reject) => {
      if (Runtime.isNativeAndroid('copyToClipboard')) {
        AndroidBridge.copyToClipboard(text);
        resolve();
      } else if (navigator.clipboard != null) {
        navigator.clipboard
          .writeText(text)
          .then(() => {
            resolve();
          })
          .catch((e) => {
            reject(e);
          });
      } else {
        reject('Unable to copy the text. Try reloading the page');
      }
    });
  }

  /**
   * Returns true if the supplied KeyboardEvent includes the OS-specific
   * modifier key. For example, the Cmd key on Apple platforms or the Ctrl key
   * on others.
   *
   * @param {KeyboardEvent} The event to check for the OS-specific modifier key
   *
   * @returns {Boolean} true if the event was fired with the OS-specific
   *                    modifier key, false otherwise. Also returns false if
   *                    the event is not a KeyboardEvent.
   */
  static hasOSSpecificModifier(event) {
    if (!(event instanceof KeyboardEvent)) {
      return false;
    }

    if (navigator.userAgent.indexOf('Mac OS X') >= 0) {
      return event.metaKey;
    } else {
      return event.ctrlKey;
    }
  }
}
