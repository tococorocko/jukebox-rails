import { updateQueue } from './user-input';

let checkCurrentlyPlayingInterval = (t) => window.setInterval( function(){ checkCurrentlyPlayingSong(); }, t);
let currentSongCover = document.getElementById("album-art");
const instructionLines = document.querySelector(".instruction-lines").children;

checkCurrentlyPlayingInterval(10000) // 50000

function checkCurrentlyPlayingSong() {
  let jukeBoxId = document.getElementById("container").getAttribute('data-jukebox-id');
  fetch(`/playing-song/${jukeBoxId}`)
    .then(response => response.json())
    .then(data => {
      if (data) {
        let currentSong = document.getElementById("current-song");
        currentSong.innerHTML = `${data.currently_playing_song.name}`;
        let cover = data.currently_playing_song.cover_uri
        currentSongCover.style.background = `#f37e1f url(${cover}) center / cover no-repeat`
      }
      if (data.queue_update == true) {
        console.log(true)
        updateQueue();
      }
    })
    .catch(error => {
      console.error('Error:', error);
    });
}

(function higlightInstructionLines(index = 0) {
  if(index < instructionLines.length){
    setTimeout(function(){
      instructionLines[index].style.color = "#FBF4E4"
      index++;
      higlightInstructionLines(index);
    }, 1000);
  } else {
    setTimeout(function(){
      index = 0;
      for (let item of instructionLines) {
          item.style.color = "#8e888c"
      }
      higlightInstructionLines(index);
    }, 1000);
  }
})()
