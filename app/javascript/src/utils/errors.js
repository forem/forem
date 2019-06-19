// eslint-disable-next-line consistent-return
export default function handleFetchAPIErrors(response) {
  // pass along a correct response
  if (response.ok) {
    return response;
  }

  // API errors contain the error message in {"error": "error message"}
  // but they could be unhandled 500 errors
  try {
    response.json().then(data => {
      throw new Error(data.error);
    });
  } catch (e) {
    if (e instanceof SyntaxError) {
      throw new Error(response.statusText);
    } else {
      throw e;
    }
  }
}
