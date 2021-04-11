let userInput = {char:"", num:""};

document.addEventListener('keydown',(e) => {
  removeSelection();
  catchInput(e);
});

const catchInput = (e) => {
  e.preventDefault();
  switch (e.keyCode) {
  case 40: //down
    pageDown();
    break;
  case 38: // up
    pageUp();
    break;
  case 90: //down with z
    pageDown();
    break;
  case 89: // up with y
    pageUp();
    break;
  case 39: // right
    nextSong();
    break;
  case 13: // enter
    updateCredits("add")
    break;
  case 164: // $
    updateCredits("add");
    break;
  case 32: //space
    // playOrPauseSong();
    break;
  default:
    songSelection(e);
    break;
  }
}

function pageDown() {
  window.scrollBy({
    left: 0,
    top: window.innerHeight,
    behavior: "smooth"
  })
}

function pageUp() {
  window.scrollBy({
    left: 0,
    top: -window.innerHeight,
    behavior: "smooth"
  });
}

function nextSong() {
  let jukeBoxId = document.getElementById("container").getAttribute('data-jukebox-id');
  fetch(`/next-song/${jukeBoxId}`)
    .catch(error => {
      console.error('Error:', error);
    });
}

function updateCredits(operation) {
  let creditAmount = document.getElementById("credit-amount");
  let jukeBoxId = document.getElementById("container").getAttribute('data-jukebox-id');
  creditAmount.classList.add("success");
  fetch(`/credits/${jukeBoxId}?operation=${operation}`)
    .then(response => response.json())
    .then(data => {
      creditAmount.innerHTML = data.new_credit;
    })
    .catch(error => {
      console.error('Error:', error);
    });
  setTimeout(function(){
    creditAmount.classList.remove("success");;
  },4000);
}

export function updateQueue() {
  let songQueueDiv = document.getElementById("song-queue");
  let jukeBoxId = document.getElementById("container").getAttribute('data-jukebox-id');
  fetch(`/queue/${jukeBoxId}`)
    .then(response => response.json())
    .then(data => {
      let firstFiveQueuedSongs = data.slice(0, 5)
      songQueueDiv.innerHTML = '';
      firstFiveQueuedSongs.forEach((song) => {
        let queueingSong = document.createElement("p");
        let artist = song["song"].artist
        let name = song["song"].name
        queueingSong.innerHTML = `${name} - ${artist}`;
        songQueueDiv.appendChild(queueingSong);
      });
    })
    .catch(error => {
      console.error('Error:', error);
    });
}

function songSelection(e) {
  let creditAmount = document.getElementById("credit-amount")
  if (creditAmount.innerHTML == 0) {
    creditAmount.classList.add("error");
    setTimeout(function(){
        creditAmount.classList.remove("error");;
    },4000);
    return;
  }

  if (isFinite(e.key)) {
    userInput.num = e.keyCode;
  } else {
    userInput.char = e.keyCode;
  }
  if (userInput.char != "" && userInput.num != "") {
    let key = document.querySelector(`[data-key="${userInput.char}"][data-num="${userInput.num}"]`);
    key.parentNode.classList.add('selected');
    let songId = key.getAttribute('song-id');
    addSongtoQueue(songId);
    userInput = {char:"", num:""};
    setTimeout(function() { removeSelection() }, 4000);
  } else if (userInput.char != "") {
      let keys = document.querySelectorAll(`[data-key="${userInput.char}"]`);
      keys.forEach(key => key.parentNode.classList.add('selected'));
  } else if (userInput.num != "") {
      let keys = document.querySelectorAll(`[data-num="${userInput.num}"]`);
      keys.forEach(key => key.parentNode.classList.add('selected'));
  } else {
    console.log("Error in SelectSong");
  }
}

function addSongtoQueue(songId) {
  let jukeBoxId = document.getElementById("container").getAttribute('data-jukebox-id');
  fetch(`/add-song/${jukeBoxId}/${songId}`)
    .then(response => {
      if (response.ok) {
        return response.json();
      } else {
        throw new Error('Song not added to queue because it is playing or already scheduled to play next.');
      }
    })
    .then(data => {
      updateCredits("remove");
      takePhoto();
      updateQueue();
    })
    .catch(error => {
      console.error('Error:', error);
    });
}

function takePhoto() {
  showVideo();
  setTimeout(function(){
    displayOverlay("inline-block");
    // paintToCanvas();
  }, 4000);
  // setTimeout(function(){
  //   showCountdown();
  //   startCountdown();
  // }, 6000);
  // setTimeout(function(){
  //   takePhoto();
  // }, 13400)
  setTimeout(function(){
    displayOverlay("none");
  }, 14000)
}

function showVideo() {
  let video = document.getElementById("photo-player");
  let camera_id = document.getElementById("container").getAttribute('data-camera-id');

  navigator.mediaDevices.getUserMedia({ audio: false, video: { deviceId: { exact: camera_id } } })
  .then(localMediaStream => {
    video.srcObject = localMediaStream
    video.play();
  })
  .catch(err => {
    console.log("Camera Error:", err)
  })
}

function displayOverlay(style) {
  let photoOverlay = document.getElementById("photo-overlay");
  let video = document.getElementById("photo-player");
  let canvas = document.getElementById("photo");

  photoOverlay.style.display = style;
  video.style.display = style;
  canvas.style.display = style;
}

function removeSelection() {
  const selection = document.querySelectorAll(".selected");
  selection.forEach(selected => selected.classList.remove('selected'));
}
