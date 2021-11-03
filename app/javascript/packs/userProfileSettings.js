const userFieldIds = ['user[name]', 'user[email]', 'user[username]'];
const profileFieldIds = Array.from(
  document.querySelectorAll('[id^="profile["]'),
).map((node) => node.id);
const allFieldIds = [...userFieldIds, ...profileFieldIds];

export function fieldCharacterLimits() {
  window.addEventListener('load', () => {
    allFieldIds.forEach((field_id) => {
      const field = document.getElementById(field_id);
      const fieldValueLength = field.value.length;
      const fieldCharacterSpan = document.getElementById(
        field.dataset.characterSpanId,
      );
      fieldCharacterSpan.innerHTML = fieldValueLength;
    });

    document
      .getElementById('user-profile-form')
      .addEventListener('keyup', (event) => {
        if (!event.target.dataset.characterSpanId) {
          return;
        }

        document.getElementById(
          event.target.dataset.characterSpanId,
        ).innerHTML = event.target.value.length;
      });
  });
}

fieldCharacterLimits();
