import { Controller } from 'stimulus';

export default class DataUpdateScriptController extends Controller {
  forceRun() {
    event.preventDefault()
    const id = event.target.dataset.value;

    let formData = new FormData();
    formData.append('id', id);

    let statusColumn = document.getElementById(`data_update_script_${id}_status`);
    let runAtColumn  = document.getElementById(`data_update_script_${id}_run_at`);
    let button       = document.getElementById(`data_update_script_${id}_button`);

    statusColumn.innerHTML = "loading..";
    runAtColumn.innerHTML  = "loading..";
    button.innerHTML       = "loading..";

    fetch(`/admin/data_update_scripts/${id}/force_run`, {
      method: 'POST',
      headers: {
       'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
      },
      body: formData,
      credentials: 'same-origin'
    }).then(response => response.json()
      .then(json => {
        let updatedScript      = json.response;

        statusColumn.innerHTML = `${updatedScript.status}`;
        if(updatedScript.error) {
          statusColumn.innerHTML += `<div class='fs-xs'> ${updatedScript.error}</div>`
        }
        runAtColumn.innerHTML = updatedScript.run_at;
        button.innerHTML      = `<button onclick=forceRun(${updatedScript.id}); return false; type='button' classname='crayons-btn crayons-btn--secondary'>Re run</button>`
      })
    )
  }
}
