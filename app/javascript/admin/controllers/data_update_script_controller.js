import { Controller } from 'stimulus';

export default class DataUpdateScriptController extends Controller {

  forceRun() {
    event.preventDefault();
    const id         = event.target.dataset.value;
    let statusColumn = document.getElementById(`data_update_script_${id}_status`);
    let runAtColumn  = document.getElementById(`data_update_script_${id}_run_at`);

    this.displayLoadingIndicators(statusColumn, runAtColumn);
    this.forceRunScript(id, statusColumn, runAtColumn);
  }

  displayLoadingIndicators(statusColumn, runAtColumn) {
    runAtColumn.innerHTML  = "loading..";
    statusColumn.innerHTML = "";
  }

  forceRunScript(id, statusColumn, runAtColumn) {
    fetch(`/admin/data_update_scripts/${id}/force_run`, {
      method: 'POST',
      headers: {
       'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
      },
      credentials: 'same-origin'
    })
    .then(response => {
      if(response.ok) {
        this.pollForScriptResponse(id, statusColumn, runAtColumn);
      } else {
        response.json().then((response) => {
          document.getElementsByClassName("data-update-script__alert")[0].classList.remove("hidden");
          document.getElementById("data-update-script__error").innerHTML = `Data Update Script ${id} - ${response.error}`
          runAtColumn.innerHTML = "";
          statusColumn.innerHTML = "";
        });
      }
    })
  }

  pollForScriptResponse(id, statusColumn, runAtColumn) {
    let counter = 0;
    let pollForStatus = setInterval(() => {
      counter++;
      this.checkForUpdatedDataScript(id, runAtColumn, statusColumn).then((updatedDataScript) => {
        if (updatedDataScript) {
          // only if we've stopped polling because we received a status;
          // and not because there was an error.
          if(updatedDataScript.status) {
            statusColumn.innerHTML = `${updatedDataScript.status}`;
            if(updatedDataScript.error) {
              statusColumn.innerHTML += `<div class='fs-xs'> ${updatedDataScript.error}</div>`
            }
            runAtColumn.innerHTML = updatedDataScript.run_at;
            if(updatedDataScript.status === "succeeded") {
              document.getElementById(`data_update_script_${id}_button`).remove();
            }
          }
          clearInterval(pollForStatus);
        }
      });
      if ( counter > 20 ) {
        clearInterval(pollForStatus);
        document.getElementsByClassName("data-update-script__alert")[0].classList.remove("hidden");
        document.getElementById("data-update-script__error").innerHTML = `This may take some time. Please refresh the page to check for the status.`;
        runAtColumn.innerHTML = "";
        statusColumn.innerHTML = "";
      }
    }, 1000)
  }

  checkForUpdatedDataScript(id, runAtColumn, statusColumn) {
    return fetch(`/admin/data_update_scripts/${id}`, {
      method: 'GET',
      headers: {
       'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
      },
      credentials: 'same-origin'
    }).then((response) => {
      if(response.ok) {
        return response.json().then(json => {
          let script = json.response;
          if(script.status === "succeeded" || script.status === "failed") {
            return script;
          } else {
            return false;
          }
        })
      } else {
        return response.json().then((response) => {
          document.getElementsByClassName("data-update-script__alert")[0].classList.remove("hidden");
          document.getElementById("data-update-script__error").innerHTML = `Data Update Script ${id} - ${response.error}`
          runAtColumn.innerHTML = "";
          statusColumn.innerHTML = "";
          return true;
        });
      }
    })
  }
}
