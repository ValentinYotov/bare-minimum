(function () {
  if (typeof window.sswsApi !== "function") {
    window.sswsApi = function (path) {
      path = String(path || "").replace(/^\//, "");
      return window.SSWS_BASE ? window.SSWS_BASE + "/" + path : path;
    };
  }
  var wateringBtn = document.getElementById("ssws-btn-start-watering");
  var badge = document.getElementById("ssws-watering-badge");
  var key = "ssws_watering_active";

  function syncWateringUI() {
    var on = sessionStorage.getItem(key) === "1";
    if (badge) {
      badge.textContent = on ? "Active" : "Inactive";
      badge.className = "ssws-badge-inactive";
      badge.style.background = on ? "#dcfce7" : "";
      badge.style.color = on ? "#166534" : "";
    }
    if (wateringBtn) {
      wateringBtn.textContent = on ? "Stop watering" : "Start watering";
    }
  }

  if (wateringBtn) {
    wateringBtn.addEventListener("click", function () {
      var on = sessionStorage.getItem(key) === "1";
      sessionStorage.setItem(key, on ? "0" : "1");
      syncWateringUI();
    });
    syncWateringUI();
  }

  var qSchedule = document.getElementById("ssws-qa-schedule");
  if (qSchedule) {
    qSchedule.addEventListener("click", function () {
      window.location.href = "map.php";
    });
  }

  var qHistory = document.getElementById("ssws-qa-history");
  if (qHistory) {
    qHistory.addEventListener("click", function () {
      window.location.href = "event-log.php";
    });
  }

  var qCal = document.getElementById("ssws-qa-calibrate");
  if (qCal) {
    qCal.addEventListener("click", function () {
      alert("Sensor calibration: follow your hardware manual. This action can call your device API when integrated.");
    });
  }

  var qReport = document.getElementById("ssws-qa-download");
  if (qReport) {
    qReport.addEventListener("click", function () {
      fetch(window.sswsApi("api/get_logs.php"), { credentials: "same-origin" })
        .then(function (r) {
          return r.json();
        })
        .then(function (logs) {
          if (!Array.isArray(logs) || !logs.length) {
            alert("No log rows to export yet.");
            return;
          }
          var header = ["sensor_id", "action", "location", "trigger_reason", "timestamp"];
          var lines = [header.join(",")];
          logs.forEach(function (log) {
            var row = header.map(function (k) {
              var val = log[k] != null ? String(log[k]) : "";
              return '"' + val.replace(/"/g, '""') + '"';
            });
            lines.push(row.join(","));
          });
          var blob = new Blob([lines.join("\r\n")], { type: "text/csv;charset=utf-8" });
          var url = URL.createObjectURL(blob);
          var a = document.createElement("a");
          a.href = url;
          a.download = "ssws-events-" + new Date().toISOString().slice(0, 10) + ".csv";
          a.click();
          URL.revokeObjectURL(url);
        })
        .catch(function () {
          alert("Could not load logs. Are you logged in?");
        });
    });
  }
})();
