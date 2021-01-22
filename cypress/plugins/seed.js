/* eslint-env node */

const { spawn } = require('child_process');

// Cypress tasks have to return a value to be considered successful. undefined does not work, so null is returned instead.
// to deem the task successful.

async function runBundleExec(command) {
  return new Promise((resolve, reject) => {
    const child = spawn('bundle', ['exec', command], {
      env: { ...process.env, RAILS_ENV: 'test' },
    });
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

/**
 * Seeds the database with the given data from the seed file.
 *
 * @param {string} seedName A seed data filename.
 *
 * @returns {Promise<boolean>} Returns null if successful, otherwise it throws.
 */
async function seedData(seedName) {
  const success = await runBundleExec(`rake db:seed:e2e[${seedName}]`);

  if (!success) {
    throw new Error(
      `The database did not seed successfully for the seed ${seedName}`,
    );
  }

  // Nothing to do, we're all good.
  // Cypress tasks require a return value, so returning null.
  return null;
}

/**
 * Resets the data to a clean slate in the database.
 *
 * @returns {Promise<boolean>} Returns null if successful, otherwise it throws.
 */
async function resetData() {
  const clearSearchIndices = runBundleExec('rake search:destroy');
  const truncateDB = runBundleExec('rails db:truncate_all');

  const [
    clearedSearchIndicesResponse = false,
    clearedDB = false,
  ] = await Promise.all([clearSearchIndices, truncateDB]);

  if (!clearedSearchIndicesResponse) {
    throw new Error('The search indices were not removed successfully.');
  }

  if (!clearedDB) {
    throw new Error('The database did not truncate successfully');
  }

  // Nothing to do, we're all good.
  // Cypress tasks require a return value, so returning null.
  return null;
}

module.exports = { resetData, seedData };
