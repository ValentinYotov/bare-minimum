(function () {
  if (typeof window.sswsApi !== "function") {
    window.sswsApi = function (path) {
      path = String(path || "").replace(/^\//, "");
      return window.SSWS_BASE ? window.SSWS_BASE + "/" + path : path;
    };
  }
  var POLL_MS = 5000;
  var STORAGE = "ssws_emergency_phone";
  var LEGACY = "agroguard_emergency_phone";
  var DIAL_KEY = "ssws_emergency_dialed_";

  function getPhone() {
    return (localStorage.getItem(STORAGE) || localStorage.getItem(LEGACY) || "").trim();
  }

  function dialHref(phone) {
    if (typeof window.sswsTelHref === "function") {
      return window.sswsTelHref(phone);
    }
    var d = phone.replace(/\s/g, "");
    return "tel:" + d;
  }

  function storageRemove(key) {
    try {
      sessionStorage.removeItem(key);
    } catch (e) {}
  }

  function storageGet(key) {
    try {
      return sessionStorage.getItem(key);
    } catch (e) {
      return null;
    }
  }

  function storageSet(key, val) {
    try {
      sessionStorage.setItem(key, val);
    } catch (e) {}
  }

  /**
   * Launch system dialer / tel handler (no confirmation UI).
   */
  function launchTel(href) {
    if (!href || href === "tel:") {
      return;
    }
    window.location.assign(href);
  }

  function tryDialForFire(sensorId, phone) {
    var href = dialHref(phone);
    if (!href || href === "tel:") {
      return;
    }
    var key = DIAL_KEY + sensorId;
    if (storageGet(key) === "1") {
      return;
    }
    storageSet(key, "1");
    launchTel(href);
  }

  var lastFireIds = new Set();

  function poll() {
    fetch(window.sswsApi("api/get_sensors.php"), { credentials: "same-origin" })
      .then(function (r) {
        if (!r.ok) return null;
        return r.json();
      })
      .then(function (sensors) {
        if (!Array.isArray(sensors)) return;

        sensors.forEach(function (s) {
          if (s.status !== "fire") {
            storageRemove(DIAL_KEY + s.id);
          }
        });

        var phone = getPhone();
        var current = new Set();

        sensors.forEach(function (s) {
          if (s.status === "fire") {
            current.add(s.id);
            if (phone && !lastFireIds.has(s.id)) {
              tryDialForFire(s.id, phone);
            }
          }
        });

        lastFireIds = current;
      })
      .catch(function () {});
  }

  setInterval(poll, POLL_MS);
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", poll);
  } else {
    poll();
  }
})();
