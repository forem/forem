/* eslint-env node */

const { spawn } = require('child_process');
const fetch = require('node-fetch');

async function runBundleExec(command) {
  return new Promise((resolve, reject) => {
    // Clear the DB for the next test run.
    const child = spawn('bundle', ['exec', command]);
    const errorChunks = [];

    child.stderr.on('data', (chunk) => errorChunks.push(Buffer.from(chunk)));

    child.on('error', (error) => {
      reject(error);
    });

    child.on('exit', (status, _code) => {
      if (status !== 0) {
        const errorMessage = Buffer.concat(errorChunks).toString('UTF-8');

        reject(
          new Error(
            `There was an error running "bundle exec ${command}". The status was ${status} with the following error:\n${errorMessage}`,
          ),
        );
      }

      resolve(status === 0);
    });
  });
}

async function seedData(seedName) {
  const success = await runBundleExec(`rake db:seed:${seedName}`);

  if (!success) {
    throw new Error(
      `The database did not seed successfully for the seed ${seedName}`,
    );
  }

  // Nothing to do, we're all good.
  // Cypress tasks require a return value, so returning null.
  return null;
}

function createResetDataTask(config) {
  return async function resetData() {
    const clearSearchIndices = fetch(`${config.env.ELASTICSEARCH_URL}/*`, {
      method: 'DELETE',
    });

    const truncateDB = runBundleExec('rails db:truncate_all');

    const [clearSearchIndicesResponse, clearedDB = false] = await Promise.all([
      clearSearchIndices,
      truncateDB.catch((error) => {
        throw new Error(error);
      }),
    ]);
    const {
      acknowledged = false,
      error,
    } = await clearSearchIndicesResponse.json();

    if (!acknowledged || error) {
      throw new Error(
        `There was an error clearing indices in Elastic Search:\n${
          error ? JSON.stringify(error, null, '\t') : ''
        }`,
      );
    }

    if (!clearedDB) {
      throw new Error(`The database did not truncate successfully`);
    }

    // Nothing to do, we're all good.
    // Cypress tasks require a return value, so returning null.
    return null;
  };
}

module.exports = { createResetDataTask, seedData };
