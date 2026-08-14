export function handleFetchAPIErrors(response) {
  // pass along a correct response
  if (response.ok) {
    return response;
  }

  // API errors contain the error message in {"error": "error message"}
  // but they could be unhandled non-JSON errors (e.g. 5xx HTML). Chain on
  // the json() promise so any parse/throw rejects the returned promise —
  // a surrounding sync try/catch cannot catch async throws.
  return response.json().then(
    (data) => {
      throw new Error(data.error || response.statusText);
    },
    () => {
      throw new Error(response.statusText);
    },
  );
}
