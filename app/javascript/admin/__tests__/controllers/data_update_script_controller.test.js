import { Application } from '@hotwired/stimulus';
import fetch from 'jest-fetch-mock';
import DataUpdateScriptController from '../../controllers/data_update_script_controller';

global.fetch = fetch;
jest.useFakeTimers();

describe('DataUpdateScriptController', () => {
  beforeAll(() => {
    document.head.innerHTML =
      '<meta name="csrf-token" content="some-csrf-token" />';
  });

  beforeEach(() => {
    document.body.innerHTML = `
    <div data-controller="data-update-script" data-data-update-script-url-value="admin/advanced/data_update_scripts">
      <div class="alert alert-danger hidden data-update-script__alert">
        <div id="data-update-script__error"></div>
      </div>
      <table>
        <tbody>
          <tr class="alert-danger" id="data_update_script_1_row">
            <td id="data_update_script_1">1</td>
            <td class="data_update_script__filename" data-filename="Some filename" id="data_update_script_1_filename">
              Some filename
              <button id="data_update_script_1_button" data-action="click->data-update-script#forceRun" data-value="1" data-force-run-path="/admin/advanced/data_update_scripts/1/force_run" type="button">
                Re-run
              </button>
            </td>
            <td id="data_update_script_1_created_at">2021-01-30 12:44:01 UTC</td>
            <td id="data_update_script_1_run_at" class="whitespace-nowrap">2021-01-30 13:44:01 UTC</td>
            <td id="data_update_script_1_status">
              Failed
            </td>
          </tr>
        </tbody>
      </table>
    </div>`;

    const application = Application.start();
    application.register('data-update-script', DataUpdateScriptController);
  });

  describe('#forceRun', () => {
    it('shows a loading state when the Re-run button is clicked', () => {
      const button = document.getElementById('data_update_script_1_button');
      button.click();

      expect(
        document.getElementById('data_update_script_1_run_at').innerHTML,
      ).toMatch(/loading/);
      expect(
        document.getElementById('data_update_script_1_status').innerHTML,
      ).toEqual('');
    });

    it('shows something went wrong if the first request fails', async () => {
      fetch.mockResponseOnce('', {
        status: 422,
        headers: { 'content-type': 'application/json' },
      });

      const button = document.getElementById('data_update_script_1_button');
      button.click();

      const flushPromises = () => new Promise(setImmediate);
      await flushPromises();

      const banner = document.getElementById('data-update-script__error');
      expect(banner.innerHTML).toMatch(/Some filename - Something went wrong./);
    });

    it('updates the status column with new values and formatting', async () => {
      expect(
        document.getElementById('data_update_script_1_row').classList,
      ).toContain('alert-danger');
      fetch.mockResponse();

      const date = new Date();
      const response = {
        response: {
          id: 1,
          status: 'succeeded',
          run_at: date,
        },
      };
      fetch.mockResponse(JSON.stringify(response));

      const button = document.getElementById('data_update_script_1_button');
      button.click();

      const flushPromises = () => new Promise(setImmediate);
      await Promise.resolve().then(() => jest.advanceTimersByTime(1000));
      await flushPromises();

      expect(
        document.getElementById('data_update_script_1_status').innerHTML,
      ).toMatch(/succeeded/);
      expect(
        document.getElementById('data_update_script_1_row').classList,
      ).not.toContain('alert-danger');
    });
  });
});
