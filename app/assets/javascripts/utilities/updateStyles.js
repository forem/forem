async function updateStyles(theme) {
  const css = await fetch(`https://dev.to/assets/themes/${theme}.css`);

  let string = await css.text();
  document.getElementById('body-styles').innerHTML = `<style>${string}</style>`;
}
