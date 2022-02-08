document
  .getElementById('settings_smtp_own_email_server')
  ?.addEventListener('change', (event) => {
    const [customSMTPSection] = document.getElementsByClassName(
      'js-custom-smtp-section',
    );

    if (event.target.checked) {
      customSMTPSection.classList.remove('hidden');
    } else {
      // when the user indicates that they do not want to use their own server
      // we clear the form values except for those fields that have a default value.
      const inputs = customSMTPSection.getElementsByTagName('input');
      const haveDefaultValues = ['authentication'];

      for (const input of inputs) {
        if (!haveDefaultValues.some((el) => input.name.includes(el))) {
          input.value = '';
        }
      }
      customSMTPSection.classList.add('hidden');
    }
  });
