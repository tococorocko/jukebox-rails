let checkCurrentlyPlayingInterval = (t) =>
  window.setInterval(function () {
    checkCurrentlyPlayingSongAndQueue();
  }, t);
let currentSongCover = document.getElementById("album-art");
const instructionLines = document.querySelector(".instruction-lines").children;

checkCurrentlyPlayingInterval(10000); // 50000

function checkCurrentlyPlayingSongAndQueue() {
  let jukeBoxId = document.getElementById("container").getAttribute("data-jukebox-id");
  fetch(`/playing-song/${jukeBoxId}`)
    .then((response) => response.json())
    .then((data) => {
      updateCurrentlyPlayingSongInHTML(data.currently_playing);
      updateQueueInHTML(data.queue);
    })
    .catch((error) => {
      console.error("Error:", error);
    });
}

function updateCurrentlyPlayingSongInHTML(song) {
  let currentSong = document.getElementById("current-song");
  currentSong.innerHTML = `${song.name}`;
  let cover = song.cover_uri;
  currentSongCover.style.background = `#f37e1f url(${cover}) center / cover no-repeat`;
}

function updateQueueInHTML(queue) {
  let songQueueDiv = document.getElementById("song-queue");
  let jukeBoxId = document.getElementById("container").getAttribute("data-jukebox-id");
  songQueueDiv.innerHTML = "";
  queue.forEach((song) => {
    let queueingSong = document.createElement("p");
    queueingSong.innerHTML = `${song.name}`;
    songQueueDiv.appendChild(queueingSong);
  });
}

(function higlightInstructionLines(index = 0) {
  if (index < instructionLines.length) {
    setTimeout(function () {
      instructionLines[index].style.color = "#FBF4E4";
      index++;
      higlightInstructionLines(index);
    }, 1000);
  } else {
    setTimeout(function () {
      index = 0;
      for (let item of instructionLines) {
        item.style.color = "#8e888c";
      }
      higlightInstructionLines(index);
    }, 1000);
  }
})();
