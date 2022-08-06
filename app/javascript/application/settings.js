window.addEventListener('load', (event) => {
  getCameraAccess()
})

function getCameraAccess () {
  let cameraSelectionField = document.getElementById("jukebox_camera_id");
  let getCameraLink = document.getElementById("camera-access");

  cameraSelectionField && getCameraLink.addEventListener('click',(e) => {
    if (cameraSelectionField && navigator.mediaDevices.getUserMedia) {
        console.log('getUserMedia supported.');
        const constraints = {video: true};

        function onSuccess (stream) {
          if (!navigator.mediaDevices || !navigator.mediaDevices.enumerateDevices) {
            console.log("enumerateDevices() not supported.");
            return false;
          }
          //List cameras.
          navigator.mediaDevices.enumerateDevices()
          .then(function (devices) {
            let videoDevices = devices.filter(device => device.kind == "videoinput");
            selectCamera(videoDevices)
          })
          .catch(function (err) {
              console.log(err.name + ": " + err.message);
          });
        }

        function selectCamera(cameras) {
          console.log("1!", cameras)
          for (let i = 0; i < cameras.length; i++) {
            let list = document.createElement("OPTION");
            console.log("2", cameras[i], cameras)
            list.innerHTML = cameras[i].label || "Kamera " + (i + 1)
            list.setAttribute('value',cameras[i].deviceId); // set data-key
            cameraSelectionField.appendChild(list);
          }
        }

        function onError (err) {
            console.log('The following error occured: ' + err);
        }

      navigator.mediaDevices.getUserMedia(constraints).then(onSuccess, onError);

    } else {
      console.log('getUserMedia not supported on your browser!');
    }
  });
}
