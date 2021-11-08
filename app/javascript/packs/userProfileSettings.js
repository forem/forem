const userSettingForm = document.getElementById('user-profile-form');
const profileFieldIds = Array.from(
  document.querySelectorAll('[id^="profile["]'),
).map((node) => node.id);

export function fieldCharacterLimits() {
  if (document.readyState === 'complete') {
    profileFieldIds.forEach((field_id) => {
      const field = document.getElementById(field_id);
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
}

fieldCharacterLimits();
