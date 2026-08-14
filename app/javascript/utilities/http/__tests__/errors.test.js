import { handleFetchAPIErrors } from '../errors';

describe('handleFetchAPIErrors', () => {
  const buildResponse = ({ ok, status = 200, statusText = '', jsonValue, jsonError }) => ({
    ok,
    status,
    statusText,
    json: () => (jsonError ? Promise.reject(jsonError) : Promise.resolve(jsonValue)),
  });

  it('returns the response unchanged when ok', () => {
    const response = buildResponse({ ok: true, status: 200, statusText: 'OK' });

    expect(handleFetchAPIErrors(response)).toBe(response);
  });

  it('rejects with the API-provided error message when body is JSON with an error field', async () => {
    const response = buildResponse({
      ok: false,
      status: 422,
      statusText: 'Unprocessable Entity',
      jsonValue: { error: 'Invalid parameters' },
    });

    await expect(handleFetchAPIErrors(response)).rejects.toThrow('Invalid parameters');
  });

  it('falls back to statusText when JSON body has no error field', async () => {
    const response = buildResponse({
      ok: false,
      status: 500,
      statusText: 'Internal Server Error',
      jsonValue: {},
    });

    await expect(handleFetchAPIErrors(response)).rejects.toThrow('Internal Server Error');
  });

  it('falls back to statusText when the response body is not valid JSON', async () => {
    const response = buildResponse({
      ok: false,
      status: 502,
      statusText: 'Bad Gateway',
      jsonError: new SyntaxError('Unexpected token < in JSON'),
    });

    await expect(handleFetchAPIErrors(response)).rejects.toThrow('Bad Gateway');
  });

  it('returns a rejected promise rather than throwing synchronously', () => {
    const response = buildResponse({
      ok: false,
      status: 500,
      statusText: 'Internal Server Error',
      jsonValue: { error: 'boom' },
    });

    // Must not throw synchronously — callers chain .then/.catch on the result.
    const result = handleFetchAPIErrors(response);
    expect(result).toBeInstanceOf(Promise);
    return expect(result).rejects.toThrow('boom');
  });
});
