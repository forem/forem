function isClipboardSupported() {
    return (
      typeof navigator.clipboard !== 'undefined' && navigator.clipboard !== null
    );
  }

  function isNativeAndroidDevice() {
    return (
      navigator.userAgent === 'DEV-Native-android' &&
      typeof AndroidBridge !== 'undefined' &&
      AndroidBridge !== null
    );
  }

function execCopyText() {
    document.execCommand('copy');
}

function copyText(event) {
    const inputValue = event.target.parentNode.nextElementSibling.getElementsByTagName('code')[0].innerText;
    if (isNativeAndroidDevice()) {
        AndroidBridge.copyToClipboard(inputValue);
    } else if (isClipboardSupported()) {
        navigator.clipboard
        .writeText(inputValue)
        .catch(() => {
            execCopyText();
        });
    } else {
        execCopyText();
    }
}

const clipboardCopyElements = document.getElementsByClassName('copy-code-icon');
for (let element of clipboardCopyElements) {
    element.addEventListener('click', copyText);
}
