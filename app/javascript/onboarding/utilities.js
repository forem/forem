export const jsonToForm = data => {
  const form = new FormData();
  data.forEach(item => form.append(item.key, item.value));
  return form;
};

export const getContentOfToken = token =>
  document.querySelector(`meta[name='${token}']`).content;
