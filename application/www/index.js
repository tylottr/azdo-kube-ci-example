/**
 * Creates and maintains endpoints - not the most stable or DRY
 * but it's enough to get the Status icons working with the 
 * current html.
 */
let endpoints = [];

const refreshEndpointsTable = () => {
  // Refresh the Endpoints list based on what's in the page
  const endpointTable = document.getElementById("endpoints");
  const endpointTableRows = endpointTable.getElementsByTagName("tr");

  endpoints = [];
  for (i = 0; i < endpointTableRows.length; i++) {
    const endpointName = endpointTableRows[i].id;

    if (endpointName.length > 0) {
      endpoints.push(endpointName);
    };
  }
}

const refreshEndpoint = e => {
  // Collect details
  const endpoint = document.getElementById(e);
  const status = endpoint.getElementsByTagName("span")[0];
  const url = endpoint.getElementsByTagName("a")[0];

  // Make a request
  fetch(`${url}health`).then(r => {
    if (r.status === 200) {
      status.classList.value = "health-dot health-dot-healthy"
    } else {
      status.classList.value = "health-dot health-dot-unhealthy"
    }
  });
}

const appendOnclickEvent = e => {
  const endpoint = document.getElementById(e);
  const button = endpoint.getElementsByTagName("button")[0];
  button.onclick = event => refreshEndpoint(event.target.value);
}

/**
 * Run scripts on window load
 */
window.onload = () => {
  // Populate endpoint list and update each endpoint in the list
  refreshEndpointsTable();
  endpoints.forEach(e => {
    refreshEndpoint(e);
    appendOnclickEvent(e);
  });
}