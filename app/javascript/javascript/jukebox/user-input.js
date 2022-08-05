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
  case 223: // $
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
      startCamera(songId);
      updateQueue();
    })
    .catch(error => {
      console.error('Error:', error);
    });
}

function startCamera(songId) {
  showVideo();
  setTimeout(function(){
    displayOverlay("inline-block");
    paintToCanvas();
  }, 4000);
  setTimeout(function(){
    displayCountdown("inline-block");
    startCountdown();
  }, 6000);
  setTimeout(function(){
    takePhoto(songId);
  }, 13400)
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

function paintToCanvas() {
  let canvas = document.getElementById("photo");
  let ctx = canvas.getContext("2d");
  let video = document.getElementById("photo-player");
  let width = video.videoWidth;
  let height = video.videoHeight;
  canvas.width = width;
  canvas.height = height;
  setInterval(()=> {
    ctx.drawImage(video, 0, 0, width, height)
  }, 16)
}

function displayOverlay(style) {
  let photoOverlay = document.getElementById("photo-overlay");
  let video = document.getElementById("photo-player");
  let canvas = document.getElementById("photo");

  photoOverlay.style.display = style;
  video.style.display = style;
  canvas.style.display = style;
  photoOverlay.style.background = 'black';
}

function takePhoto(songId) {
  let jukeBoxId = document.getElementById("container").getAttribute('data-jukebox-id');
  let canvas = document.getElementById("photo");
  let image = canvas.toDataURL("image/png");
  // console.log(image)
  let base64Data = image.replace(/^data:image\/png;base64,/, "");
  // console.log(base64Data)
  let today = new Date();
  let time = today.getHours() + "-" + today.getMinutes() + "-" + today.getSeconds();
  let token = document.querySelector('meta[name="csrf-token"]').content
  fetch(`/take-photo/${jukeBoxId}`, {
      method: 'POST',
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        song_id: songId,
        image: base64Data
      })
  })
  .catch(error => {
    console.error('Error:', error);
  });
}

function displayCountdown(style) {
  let countdown = document.querySelector(".countdown-container");
  countdown.style.display = style;
}

let countdownTimer;
function startCountdown() {
  countdownTimer = setInterval(function () {
    secondPlay()},
  1000);
}

function secondPlay() {
  let countdownContainer = document.querySelector(".countdown-container");
  let allLi = document.querySelectorAll(`ul.secondPlay li`)
  let aa = document.querySelector(`ul.secondPlay li.active`);

  countdownContainer.classList.remove("play");
  removeClassBefore(allLi)
  if (aa == null) {
    removeClassBefore(allLi)
    aa = document.querySelector("ul.secondPlay li")
    aa.classList.add("before")
    aa.classList.remove("active")
    aa.nextElementSibling.classList.add("active")
    countdownContainer.classList.add("play")
  } else if (!aa.nextElementSibling) {
    flash()
    removeClassBefore(allLi)
    aa.classList.add("before")
    aa.classList.remove("active")
    aa = document.querySelector("ul.secondPlay li");
    clearInterval(countdownTimer);
    displayCountdown("none");
  } else {
    removeClassBefore(allLi)
    aa.classList.add("before")
    aa.classList.remove("active")
    aa.nextElementSibling.classList.add("active")
    countdownContainer.classList.add("play")
  }
}

function flash() {
  let photoOverlay = document.getElementById("photo-overlay");
  photoOverlay.style.background = 'white';
}

function removeSelection() {
  let selection = document.querySelectorAll(".selected");
  selection.forEach(selected => selected.classList.remove('selected'));
}

function removeClassBefore(element) {
  element.forEach(function(el) {
    el.classList.remove("before");
  });
}