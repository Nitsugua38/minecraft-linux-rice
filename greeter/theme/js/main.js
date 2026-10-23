(function () {
  "use strict";
  var $ = function (id) { return document.getElementById(id); };
  var L = null, inited = false;
  var state = { user: null, sessionIdx: 0, prompting: false, busy: false, starting: false };
  var SCREENS = ["title", "login", "users", "realms", "options", "credits"];
  var realmTimer = 0;

  function arr(x) { try { return Array.prototype.slice.call(x || []); } catch (e) { return []; } }
  function users() { return arr(L.users); }
  function sessions() { return arr(L.sessions); }
  function nameOf(u) { return (u && (u.display_name || u.username)) || "Player"; }
  function pad(n) { return (n < 10 ? "0" : "") + n; }

  /* ---------- screens ---------- */
  function show(name) {
    SCREENS.forEach(function (s) { $(s).classList.toggle("active", s === name); });
    document.body.setAttribute("data-screen", name);
    if (name === "login") openLogin();
    if (name === "users") buildUsers();
    clearInterval(realmTimer);
    if (name === "realms") { renderRealm(); reloadInfo(); realmTimer = setInterval(reloadInfo, 5000); }
    if (name === "options") setSlider(window.mcSound ? window.mcSound.volume() : 0.5, false);
  }

  /* ---------- title ---------- */
  function sessionIndex(key) {
    var s = sessions();
    for (var i = 0; i < s.length; i++) if (s[i].key === key) return i;
    return 0;
  }
  function sessionKey() { var s = sessions(); return s[state.sessionIdx] ? s[state.sessionIdx].key : L.default_session; }
  function setUser(u) {
    state.user = u || null;
    state.sessionIdx = sessionIndex((u && u.session) || L.default_session);
    refreshTitle();
  }
  function refreshTitle() {
    $("btn-login").textContent = state.user ? "Play as " + nameOf(state.user) : "Log In";
    $("btn-switch").disabled = users().length < 2;
    $("btn-quit").disabled = (L.can_shutdown === false);
    $("foot-l").textContent = "Minecraft Desktop" + (L.hostname ? " - " + L.hostname : "");
  }
  function pickSplash() {
    var l = window.SPLASHES || ["Hello!"], t = l[Math.floor(Math.random() * l.length)];
    var el = $("splash"); el.textContent = t;
    el.style.fontSize = (t.length > 26 ? 8 : t.length > 18 ? 10 : 12) + "rem";
  }
  function applyPanorama(folder) {
    for (var i = 0; i < 6; i++) {
      var face = document.querySelector(".f" + i);
      if (face) face.style.backgroundImage = 'url("assets/' + folder + '/panorama_' + i + '.png")';
    }
  }
  function fitLogo() {
    /* the game's title/minecraft.png is 4:1 with empty space under the logo (only its top 44/64 is drawn in game) */
    var img = $("logo");
    function check() {
      if (img.naturalWidth && img.naturalWidth === 4 * img.naturalHeight) { img.classList.add("jar"); $("credits-logo").classList.add("jar"); }
    }
    if (img.complete) check(); else img.addEventListener("load", check);
  }
  function pickPanorama() {
    var maxCheck = 20, valid = [], pending = maxCheck;
    for (var i = 1; i <= maxCheck; i++) {
      (function (n) {
        var img = new Image();
        img.onload = function () { valid.push(n); done(); };
        img.onerror = function () { done(); };
        img.src = "assets/" + n + "/panorama_0.png";
      })(i);
    }
    function done() {
      pending--;
      if (pending === 0) {
        var list = valid.length ? valid : [1];
        var folder = list[Math.floor(Math.random() * list.length)];
        applyPanorama(folder);
      }
    }
  }
  function tick() { var d = new Date(); $("foot-r").textContent = pad(d.getHours()) + ":" + pad(d.getMinutes()); }

  /* ---------- user list ---------- */
  function buildUsers() {
    var list = $("user-list"); list.innerHTML = "";
    users().forEach(function (u) {
      var row = document.createElement("button");
      row.className = "user-row" + (u === state.user ? " sel" : "");
      var av = document.createElement("span"); av.className = "avatar";
      av.textContent = nameOf(u).charAt(0).toUpperCase();
      if (u.image) {
        var img = document.createElement("img"); img.src = u.image;
        img.onload = function () { av.textContent = ""; av.appendChild(img); };
      }
      var txt = document.createElement("span");
      var a = document.createElement("span"); a.className = "user-name"; a.textContent = nameOf(u);
      var b = document.createElement("span"); b.className = "user-sub"; b.textContent = u.logged_in ? "Already logged in" : u.username;
      txt.appendChild(a); txt.appendChild(b);
      row.appendChild(av); row.appendChild(txt);
      row.addEventListener("click", function () { setUser(u); show("title"); });
      list.appendChild(row);
    });
  }

  /* ---------- login ---------- */
  function setMsg(text, isError) { var m = $("login-msg"); m.textContent = text || ""; m.className = isError ? "error" : ""; }
  function setJoin(enabled, text) { var b = $("btn-join"); b.disabled = !enabled; b.textContent = text; }
  function beginAuth() {
    state.prompting = false; state.busy = false;
    try { L.cancel_authentication(); } catch (e) {}
    try { L.authenticate(state.user ? state.user.username : null); }
    catch (e) { setMsg("Could not reach the login service.", true); }
  }
  function openLogin() {
    setMsg("", false); $("pw").value = "";
    $("login-label").textContent = state.user ? "Password for " + nameOf(state.user) : "Username";
    setJoin(false, "Join Server");
    beginAuth();
    setTimeout(function () { $("pw").focus(); }, 50);
  }
  function cancelLogin() {
    try { L.cancel_authentication(); } catch (e) {}
    state.prompting = false; state.busy = false; show("title");
  }
  function submit() {
    if (!state.prompting || state.busy || state.starting) return;
    state.busy = true; state.prompting = false;
    setMsg("", false); setJoin(false, "Join Server");
    L.respond($("pw").value);
  }
  function onPrompt(text, type) {
    var isText = (type === 0 || type === "0" || type === "text");
    var pw = $("pw");
    state.prompting = true; state.busy = false;
    pw.type = isText ? "text" : "password"; pw.value = ""; pw.disabled = false;
    if (isText) $("login-label").textContent = String(text || "").replace(/[:\s]+$/, "");
    setJoin(true, "Join Server"); pw.focus();
  }
  function onMessage(text, type) {
    if (!text) return;
    setMsg(String(text), type === "error" || type === 1);
  }
  function onAuthComplete() {
    state.busy = false;
    if (L.is_authenticated) { startSession(); return; }
    $("pw").value = "";
    setMsg("Failed to connect: Invalid password", true);
    setJoin(false, "Join Server");
    setTimeout(beginAuth, 200);
  }
  function startSession() {
    state.starting = true;
    document.body.classList.add("starting");
    if (window.mcSound) window.mcSound.fadeOut(800);
    var key = sessionKey();
    setTimeout(function () {
      try { L.start_session(key); }
      catch (e) { state.starting = false; document.body.classList.remove("starting"); setMsg("Could not start session.", true); beginAuth(); }
    }, 850);
  }

  /* ---------- realms: this computer's info, from js/greeter-info.js (rewritten every 5 s by mc-greeter-info) ---------- */
  function reloadInfo() {
    var old = $("info-script"); if (old) old.remove();
    var s = document.createElement("script");
    s.id = "info-script"; s.src = "js/greeter-info.js?t=" + Date.now();
    s.onload = s.onerror = renderRealm;
    document.body.appendChild(s);
  }
  function uptime(boot) {
    var m = Math.max(0, Math.floor((Date.now() / 1000 - boot) / 60));
    return (m >= 1440 ? Math.floor(m / 1440) + "d " : "") + Math.floor(m % 1440 / 60) + "h " + pad(m % 60) + "m";
  }
  function renderRealm() {
    var i = window.MC_INFO || {}, host = i.host || (L && L.hostname) || "This computer", net = [], power = [];
    $("realm-icon").textContent = host.charAt(0).toUpperCase();
    $("realm-name").textContent = host;
    $("realm-status").textContent = i.ip ? "Online" : "Offline";
    $("realm-status").className = i.ip ? "on" : "off";
    $("realm-os").textContent = [i.os, i.kernel].filter(Boolean).join(" - ") || "Linux";
    if (i.ip) net.push("IP " + i.ip);
    if (i.net) net.push(i.net);
    if (i.battery) power.push("Battery " + i.battery.pct + "%" + (i.battery.status === "Charging" ? " (charging)" : ""));
    if (i.boot) power.push("Up " + uptime(i.boot));
    $("realm-motd").textContent = net.join(" - ") || "No network";
    $("realm-power").textContent = power.join(" - ");
  }

  /* ---------- options: music volume slider ---------- */
  var sliding = false;
  function setSlider(v, apply) {
    v = Math.max(0, Math.min(1, v));
    var pct = Math.round(v * 100);
    $("vol-handle").style.left = "calc((100% - 8rem) * " + v + ")";
    $("vol-label").textContent = "Music: " + (pct ? pct + "%" : "OFF");
    if (apply !== false && window.mcSound) window.mcSound.setVolume(v);
  }
  function sliderValue(e) {
    var r = $("vol-slider").getBoundingClientRect(), h = r.height * 8 / 20;   // handle is 8 of the 20 GUI px
    return (e.clientX - r.left - h / 2) / (r.width - h);
  }
  function current() { return window.mcSound ? window.mcSound.volume() : 0.5; }

  /* ---------- language button: cycles the keyboard layouts listed in /etc/default/keyboard (+ us) ---------- */
  /* lightdm.layout always returns the layout from startup (liblightdm never updates it after set_layout),
     so the theme keeps track of the current one itself */
  var curLayout = null;
  function showLayout() {
    var l = curLayout, el = $("layout-msg");
    $("lang-code").textContent = l ? String(l.short_description || l.name || "").split("\t")[0].toUpperCase() : "?";
    el.textContent = "Keyboard: " + (l ? (l.description || l.short_description || l.name) : "default");
    el.classList.add("shown");
    clearTimeout(showLayout.t);
    showLayout.t = setTimeout(function () { el.classList.remove("shown"); }, 2500);
  }
  function nextLayout() {
    var all = arr(L.layouts), names = ((window.MC_INFO && window.MC_INFO.layouts) || ["us"]).slice();
    var cur = curLayout && curLayout.name;
    if (cur && names.indexOf(cur) < 0) names.unshift(cur);
    var lay = null;
    for (var k = 1; k <= names.length && !lay; k++) {          // next name that LightDM knows, skipping unknown ones
      var next = names[(names.indexOf(cur) + k) % names.length];
      lay = all.filter(function (l) { return l.name === next; })[0] || null;
    }
    if (lay && lay.name !== cur) {
      try { L.layout = lay; curLayout = lay; } catch (e) {}
    }
    showLayout();
  }
  function iconFallback(id) {
    var img = $(id);
    function bad() { img.remove(); }
    if (img.complete && !img.naturalWidth) bad(); else img.addEventListener("error", bad);
  }

  /* ---------- wiring ---------- */
  function init() {
    if (inited) return; inited = true;
    L = window.lightdm;
    L.show_prompt.connect(onPrompt);
    L.show_message.connect(onMessage);
    L.authentication_complete.connect(onAuthComplete);
    if (L.autologin_timer_expired) L.autologin_timer_expired.connect(function () {});

    var us = users();
    setUser(us.filter(function (u) { return u.username === L.select_user_hint; })[0] || us[0] || null);

    $("btn-login").addEventListener("click", function () { show("login"); });
    $("btn-switch").addEventListener("click", function () { show("users"); });
    $("btn-realms").addEventListener("click", function () { show("realms"); });
    $("btn-realms-back").addEventListener("click", function () { show("title"); });
    $("btn-options").addEventListener("click", function () { show("options"); });
    $("btn-options-done").addEventListener("click", function () { show("title"); });
    $("btn-credits").addEventListener("click", function () { show("credits"); });
    $("btn-credits-done").addEventListener("click", function () { show("title"); });
    $("credits-roll").addEventListener("animationend", function () {   // credits played once: back to the title
      if (document.body.getAttribute("data-screen") === "credits") show("title");
    });
    $("btn-lang").addEventListener("click", nextLayout);
    $("btn-lang").addEventListener("mouseenter", showLayout);
    $("vol-slider").addEventListener("mousedown", function (e) { sliding = true; setSlider(sliderValue(e)); });
    document.addEventListener("mousemove", function (e) { if (sliding) setSlider(sliderValue(e)); });
    document.addEventListener("mouseup", function () { sliding = false; });
    $("vol-slider").addEventListener("keydown", function (e) {
      if (e.key === "ArrowLeft") setSlider(current() - 0.05);
      else if (e.key === "ArrowRight") setSlider(current() + 0.05);
    });
    curLayout = L.layout || null;
    showLayout(); $("layout-msg").classList.remove("shown");
    $("btn-quit").addEventListener("click", function () { L.shutdown(); });
    $("btn-join").addEventListener("click", submit);
    $("btn-cancel").addEventListener("click", cancelLogin);
    $("btn-users-cancel").addEventListener("click", function () { show("title"); });
    $("pw").addEventListener("keydown", function (e) { if (e.key === "Enter") { e.preventDefault(); submit(); } });
    document.addEventListener("keydown", function (e) {
      var s = document.body.getAttribute("data-screen");
      if (e.key === "Escape" && s === "login") cancelLogin();
      else if (e.key === "Escape" && (s === "users" || s === "realms" || s === "options" || s === "credits")) show("title");
      else if (e.key === "Enter" && s === "title") show("login");
    });
  }

  document.addEventListener("DOMContentLoaded", function () {
    pickSplash(); pickPanorama(); fitLogo(); iconFallback("lang-icon"); iconFallback("credits-icon"); tick(); setInterval(tick, 10000);
    // Fallback in case GreeterReady never fires but the lightdm object exists.
    setTimeout(function () { if (!inited && window.lightdm) init(); }, 3000);
  });
  window.addEventListener("GreeterReady", init);
})();
