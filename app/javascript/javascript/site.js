window.addEventListener('load', function () {
  getCameraApproval();
  // navigator.mediaDevices.getUserMedia({video: true})
  cameraSettings();
})

function getCameraApproval() {
  let cameraId = document.getElementById("getCameraUser");
  if (cameraId) {
    navigator.mediaDevices.getUserMedia({video: true})
  }
}

function cameraSettings() {
  let cameraSelectionField = document.getElementById("camera");

  if (cameraSelectionField) {
    navigator.mediaDevices.getUserMedia({video: true})
    function selectCamera(cameras) {
      for (let i = 0; i < cameras.length; i++) {
        let list = document.createElement("OPTION");
        console.log(cameras[i], cameras)
        list.innerHTML = cameras[i].label || "Kamera " + (i + 1)
        list.setAttribute('value',cameras[i].deviceId); // set data-key
        cameraSelectionField.appendChild(list);
      }
    }

    const getCameras = () => new Promise((resolve, reject) => {
      navigator.mediaDevices.enumerateDevices()
      .then(function(devices) {
        const videoDevices = devices.filter(device => device.kind == "videoinput");
        resolve(videoDevices)
      })
      .catch(function(err) {
        console.log(err.name + ": " + err.message);
      });
    })

    getCameras()
    .then((res) => { selectCamera(res) })
  }
}
