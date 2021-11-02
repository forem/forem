const user_profile_field_ids = [
  'user[name]',
  'user[email]',
  'user[username]',
  'profile[website_url]',
  'profile[location]',
  'profile[summary]',
];

export function fieldCharacterLimits() {
  window.addEventListener('load', () => {
    user_profile_field_ids.forEach((field_id) => {
      const field = document.getElementById(field_id);
      const fieldValueLength = field.value.length;
      const fieldCharacterSpan = document.getElementById(
        field.dataset.characterSpanId,
      );
      fieldCharacterSpan.innerHTML = fieldValueLength;

      document.getElementById(field_id).addEventListener('keyup', (event) => {
        fieldCharacterSpan.innerHTML = event.target.value.length;
      });
    });
  });
}

fieldCharacterLimits();
