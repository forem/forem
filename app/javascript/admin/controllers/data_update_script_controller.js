import { Controller } from 'stimulus';

export default class DataUpdateScriptController extends Controller {

  forceRun() {
    event.preventDefault()

    const id         = event.target.dataset.value;
    let statusColumn = document.getElementById(`data_update_script_${id}_status`);
    let runAtColumn  = document.getElementById(`data_update_script_${id}_run_at`);
    let button       = document.getElementById(`data_update_script_${id}_button`);

    this.showLoadingIndicators(statusColumn, runAtColumn, button);
    this.kickoffSidekiqWorker(id);
    this.pollForResponse(id, statusColumn, runAtColumn, button);
  }

  showLoadingIndicators(statusColumn, runAtColumn, button) {
    statusColumn.innerHTML = "loading..";
    runAtColumn.innerHTML  = "loading..";
    button.innerHTML       = "loading..";
  }

  kickoffSidekiqWorker(id) {
    const formData = new FormData();
    formData.append('id', id);

    fetch(`/admin/data_update_scripts/${id}/force_run`, {
      method: 'POST',
      headers: {
       'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
      },
      body: formData,
      credentials: 'same-origin'
    })
    // .then(response => response.json()
    //   .then(json => {
    //     // handle the sidekiq worker post response
    //   })
    // )

  }

  pollForResponse(id, statusColumn, runAtColumn, button) {
    let counter = 0;
    let pollForStatus = setInterval(() => {
      counter++;
      this.checkForUpdatedDataScript(id).then((updatedDataScript) => {
        if (updatedDataScript) {
          statusColumn.innerHTML = `${updatedDataScript.status}`;
          if(updatedDataScript.error) {
            statusColumn.innerHTML += `<div class='fs-xs'> ${updatedDataScript.error}</div>`
          }
          runAtColumn.innerHTML = updatedDataScript.run_at;

          if(updatedDataScript.status !== "succeeded") {
            button.innerHTML      = `<button onclick=forceRun(${updatedDataScript.id}); return false; type='button' classname='crayons-btn crayons-btn--secondary'>Re run</button>`;
          }

          clearInterval(pollForStatus);
        }
      });
      if ( counter > 15 ) {
        clearInterval(pollForStatus);
      }
    }, 1000)
  }

  checkForUpdatedDataScript(id) {
    return fetch(`/admin/data_update_scripts/${id}`, {
      method: 'GET',
      headers: {
       'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
      },
      credentials: 'same-origin'
    }).then(response => response.json() //do some error handling
      .then(json => {
        let script = json.response;
        if(script.status === "enqueued" || script.status === "working") {
          return false;
        } else {
          return script;
        }
      })
    )
  }
}
