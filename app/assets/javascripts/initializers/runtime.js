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
        reject('Unsupported device unable to copy to clipboard');
      }
    });
  }
}
