import { Controller } from 'stimulus';

export default class DataUpdateScriptController extends Controller {
  forceRun(event) {
    event.preventDefault();
    const id = event.target.dataset.value;
    let statusColumn = document.getElementById(
      `data_update_script_${id}_status`,
    );
    let runAtColumn = document.getElementById(
      `data_update_script_${id}_run_at`,
    );

    this.displayLoadingIndicators(statusColumn, runAtColumn);
    this.forceRunScript(id, statusColumn, runAtColumn);
  }

  displayLoadingIndicators(statusColumn, runAtColumn) {
    runAtColumn.innerHTML = 'loading..';
    statusColumn.innerHTML = '';
  }

  forceRunScript(id, statusColumn, runAtColumn) {
    fetch(`/admin/data_update_scripts/${id}/force_run`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")
          .content,
      },
      credentials: 'same-origin',
    }).then((response) => {
      if (response.ok) {
        this.pollForScriptResponse(id, statusColumn, runAtColumn);
      } else {
        const fileNameElement = document.getElementById(
          `data_update_script_${id}_filename`,
        );
        this.setErrorBanner(
          runAtColumn,
          statusColumn,
          `${fileNameElement.dataset.filename} - Something went wrong.`,
          'alert-danger',
        );
      }
    });
  }

  pollForScriptResponse(id, statusColumn, runAtColumn) {
    let counter = 0;
    let pollForStatus = setInterval(() => {
      counter++;
      this.checkForUpdatedDataScript(id, runAtColumn, statusColumn).then(
        (updatedDataScript) => {
          if (updatedDataScript) {
            if (updatedDataScript.status) {
              // when we've stopped polling because we've received a status
              // and not because we've received an error.
              runAtColumn.innerHTML = updatedDataScript.run_at;
              statusColumn.innerHTML = `${updatedDataScript.status}`;
              if (updatedDataScript.error) {
                // we need to show the html as text instead of a parsed version,
                // hence we manipulate the DOM through this longer process.
                let errorElem = document.createElement('div');
                errorElem.setAttribute('class', 'fs-xs');
                errorElem.setAttribute('id', `data_update_script_${id}_error`);
                statusColumn.appendChild(errorElem);

                let completedErrorElem = document.getElementById(
                  `data_update_script_${id}_error`,
                );
                completedErrorElem.innerText = updatedDataScript.error;
              }
              if (updatedDataScript.status === 'succeeded') {
                document
                  .getElementById(`data_update_script_${id}_row`)
                  .classList.remove('alert-danger');
                if (
                  document.getElementById(`data_update_script_${id}_button`)
                ) {
                  document
                    .getElementById(`data_update_script_${id}_button`)
                    .remove();
                }
              }
            }
            clearInterval(pollForStatus);
          }
        },
      );
      if (counter > 20) {
        clearInterval(pollForStatus);
        const fileNameElement = document.getElementById(
          `data_update_script_${id}_filename`,
        );

        this.setErrorBanner(
          runAtColumn,
          statusColumn,
          `${fileNameElement.dataset.filename} may take some time to run. Please refresh the page to check for the status.`,
          'alert-info',
        );
      }
    }, 1000);
  }

  checkForUpdatedDataScript(id, runAtColumn, statusColumn) {
    return fetch(`/admin/data_update_scripts/${id}`, {
      method: 'GET',
      headers: {
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")
          .content,
      },
      credentials: 'same-origin',
    }).then((response) => {
      if (response.ok) {
        return response.json().then((json) => {
          let script = json.response;
          if (script.status === 'succeeded' || script.status === 'failed') {
            return script;
          }
          return false;
        });
      }
      return response.json().then((response) => {
        this.setErrorBanner(
          runAtColumn,
          statusColumn,
          `Data Script ${id} - ${response.error}`,
          'alert-danger',
        );
        return true;
      });
    });
  }

  setErrorBanner(runAtColumn, statusColumn, error, bannerClass) {
    let classList = document.getElementsByClassName(
      'data-update-script__alert',
    )[0].classList;

    classList.add(bannerClass);
    classList.remove('hidden');
    document.getElementById('data-update-script__error').innerHTML = error;
    runAtColumn.innerHTML = '';
    statusColumn.innerHTML = '';
  }
}
