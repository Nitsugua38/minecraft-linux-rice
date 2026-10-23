/* sound.js: background music for the login screen.*/
(function () {
  "use strict";
  var tracks = (window.MC_SOUND && window.MC_SOUND.tracks) || [];
  var VOL = 0.5, FADE_IN_MS = 2500, last = -1, music = null, fader = 0, waiting = false;
  var KEY = "mc-music-volume";                               // set by the Options slider, kept between boots
  try { var saved = parseFloat(localStorage.getItem(KEY)); if (saved >= 0 && saved <= 1) VOL = saved; } catch (e) {}

  function pick() {
    if (!tracks.length) return null;
    var i;
    do { i = Math.floor(Math.random() * tracks.length); } while (tracks.length > 1 && i === last);
    last = i;
    return tracks[i];
  }

  function fadeTo(vol, ms) {
    clearInterval(fader);
    if (!music) return;
    var from = music.volume, t0 = Date.now();
    fader = setInterval(function () {
      var k = Math.min(1, (Date.now() - t0) / ms);
      music.volume = Math.max(0, Math.min(1, from + (vol - from) * k));
      if (k >= 1) clearInterval(fader);
    }, 50);
  }

  function playNext() {
    var name = pick();
    if (!name) return;
    music = new Audio("assets/music/" + encodeURIComponent(name));
    music.volume = 0;
    music.addEventListener("ended", playNext);
    music.addEventListener("error", function () { setTimeout(playNext, 1000); });
    var p = music.play();
    if (p && p.then) {
      p.then(function () { fadeTo(VOL, FADE_IN_MS); }).catch(function () {
        if (waiting) return;                                  // autoplay blocked: start on the first key or click
        waiting = true;
        var go = function () {
          document.removeEventListener("mousedown", go, true);
          document.removeEventListener("keydown", go, true);
          waiting = false;
          if (music) music.play().then(function () { fadeTo(VOL, FADE_IN_MS); }).catch(function () {});
        };
        document.addEventListener("mousedown", go, true);
        document.addEventListener("keydown", go, true);
      });
    }
  }

  window.mcSound = {
    fadeOut: function (ms) { fadeTo(0, ms || 400); },
    volume: function () { return VOL; },
    setVolume: function (v) {
      VOL = Math.max(0, Math.min(1, v));
      clearInterval(fader);
      if (music) music.volume = VOL;
      try { localStorage.setItem(KEY, String(VOL)); } catch (e) {}
    }
  };
  if (tracks.length) playNext();
})();
