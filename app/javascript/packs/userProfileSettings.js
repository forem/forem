const userSettingForm = document.getElementById('user-profile-form');
const profileFields = document.querySelectorAll('[id^="profile["]');

export function fieldCharacterLimits() {
  profileFields.forEach((node) => {
    const field = document.getElementById(node.id);
    const fieldValueLength = field.value.length;
    const fieldCharacterSpan = document.getElementById(
      field.dataset.characterSpanId,
    );
    fieldCharacterSpan.innerHTML = fieldValueLength;
  });

  userSettingForm.addEventListener('keyup', (event) => {
    if (!event.target.dataset.characterSpanId) {
      return;
    }

    document.getElementById(event.target.dataset.characterSpanId).innerHTML =
      event.target.value.length;
  });
}

fieldCharacterLimits();
