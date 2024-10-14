const userSettingForm = document.getElementById('user-profile-form');
const profileFields = document.querySelectorAll('[id^="profile["]');

export function fieldCharacterLimits() {
  profileFields.forEach((node) => {
    const field = document.getElementById(node.id);
    const fieldValueLength = [...field.value].length; // 😀 counts as 1
    const fieldCharacterSpan = document.getElementById(
      field.dataset.characterSpanId,
    );
    // TODO: [yheuhtozr] make the entire fraction into one i18n string
    fieldCharacterSpan.innerHTML = fieldValueLength;
  });

  userSettingForm.addEventListener('keyup', (event) => {
    if (!event.target.dataset.characterSpanId) {
      return;
    }

    document.getElementById(event.target.dataset.characterSpanId).innerHTML = [
      ...event.target.value,
    ].length;
  });

  const imageInput = userSettingForm.querySelector('[id="user[profile_image]"');

  const previewPhoto = () => {
    const file = imageInput.files;

    if (!file) return;

    const fileReader = new FileReader();

    const preview = userSettingForm.querySelector(
      '#user-profile-image-preview',
    );

    fileReader.onload = function (event) {
      preview.setAttribute('src', event.target.result);
    };
    fileReader.readAsDataURL(file[0]);
  };

  imageInput.addEventListener('change', previewPhoto);
}

fieldCharacterLimits();
