(function () {
  if (typeof window.sswsApi !== "function") {
    window.sswsApi = function (path) {
      path = String(path || "").replace(/^\//, "");
      return window.SSWS_BASE ? window.SSWS_BASE + "/" + path : path;
    };
  }
  var SVG_NS = "http://www.w3.org/2000/svg";
  var GRAD_FILLS = ["url(#gradA)", "url(#gradB)", "url(#gradC)"];
  var STROKES = ["#15803d", "#0369a1", "#4338ca"];

  var MIN_W = 48;
  var MIN_H = 48;
  var MR = 11;
  var TAP_PX = 6;

  var BASE_TEMPLATE = {
    display_name: "",
    subtitle: "",
    svg_x: 8,
    svg_y: 8,
    svg_w: 180,
    svg_h: 120,
    humidity_water_below_pct: 30,
    temp_normal_max_c: 28,
    temp_warning_max_c: 35,
    smoke_alert_pct: 70,
  };

  var activeZone = null;
  var zoneOrder = [];
  var zoneRules = {};
  var sensors = [];

  var drag = null;
  var pending = null;

  var placeholder = document.getElementById("ssws-zone-placeholder");
  var editor = document.getElementById("ssws-zone-editor");
  var titleEl = document.getElementById("ssws-zone-title");
  var liveEl = document.getElementById("ssws-zone-live");
  var headEl = document.getElementById("ssws-zone-head");
  var msgEl = document.getElementById("ssws-zone-msg");

  var nameIn = document.getElementById("zone-display-name");
  var humIn = document.getElementById("zone-humidity");
  var t1In = document.getElementById("zone-t1");
  var t2In = document.getElementById("zone-t2");
  var smIn = document.getElementById("zone-smoke");
  var humVal = document.getElementById("zone-humidity-val");
  var t1Val = document.getElementById("zone-t1-val");
  var t2Val = document.getElementById("zone-t2-val");
  var smVal = document.getElementById("zone-smoke-val");
  var saveBtn = document.getElementById("ssws-zone-save");
  var addBtn = document.getElementById("ssws-zone-add");
  var removeBtn = document.getElementById("ssws-zone-remove");
  var fieldSvg = document.getElementById("ssws-field-svg");

  function defaultMarkerXY(x, y, w, h) {
    return {
      mx: x + w / 2,
      my: y + Math.min(h * 0.28, 48),
    };
  }

  function normalizeRect(x, y, w, h) {
    w = Math.max(MIN_W, Math.min(392, w));
    h = Math.max(MIN_H, Math.min(272, h));
    x = Math.max(0, Math.min(400 - w, x));
    y = Math.max(0, Math.min(280 - h, y));
    return { x: x, y: y, w: w, h: h };
  }

  function clampRule(o) {
    var hum = parseFloat(o.humidity_water_below_pct);
    var t1 = parseFloat(o.temp_normal_max_c);
    var t2 = parseFloat(o.temp_warning_max_c);
    var sm = parseFloat(o.smoke_alert_pct);
    if (isNaN(hum)) hum = 30;
    if (isNaN(t1)) t1 = 28;
    if (isNaN(t2)) t2 = 35;
    if (isNaN(sm)) sm = 70;

    var x = parseFloat(o.svg_x);
    var y = parseFloat(o.svg_y);
    var w = parseFloat(o.svg_w);
    var h = parseFloat(o.svg_h);
    if (isNaN(x)) x = 8;
    if (isNaN(y)) y = 8;
    if (isNaN(w)) w = 180;
    if (isNaN(h)) h = 120;
    var nr = normalizeRect(x, y, w, h);
    x = nr.x;
    y = nr.y;
    w = nr.w;
    h = nr.h;

    var dm = defaultMarkerXY(x, y, w, h);
    var mx = o.marker_x != null && !isNaN(parseFloat(o.marker_x)) ? parseFloat(o.marker_x) : dm.mx;
    var my = o.marker_y != null && !isNaN(parseFloat(o.marker_y)) ? parseFloat(o.marker_y) : dm.my;
    mx = Math.max(x + MR, Math.min(x + w - MR, mx));
    my = Math.max(y + MR, Math.min(y + h - MR, my));

    return {
      humidity_water_below_pct: hum,
      temp_normal_max_c: t1,
      temp_warning_max_c: t2,
      smoke_alert_pct: sm,
      display_name: o.display_name != null ? String(o.display_name) : "",
      subtitle: o.subtitle != null ? String(o.subtitle) : "",
      svg_x: x,
      svg_y: y,
      svg_w: w,
      svg_h: h,
      marker_x: mx,
      marker_y: my,
    };
  }

  function mergeRule(k) {
    var o = {};
    Object.keys(BASE_TEMPLATE).forEach(function (key) {
      o[key] = BASE_TEMPLATE[key];
    });
    var z = zoneRules[k];
    if (z && typeof z === "object") {
      Object.keys(z).forEach(function (key) {
        if (!Object.prototype.hasOwnProperty.call(z, key)) return;
        var val = z[key];
        if (val === null || val === undefined) return;
        o[key] = val;
      });
    }
    return clampRule(o);
  }

  function zoneIndex(k) {
    var i = zoneOrder.indexOf(k);
    return i >= 0 ? i : 0;
  }

  function commitZoneRule(k, patch) {
    var cur = mergeRule(k);
    var next = {};
    Object.keys(cur).forEach(function (key) {
      next[key] = cur[key];
    });
    if (patch) {
      Object.keys(patch).forEach(function (key) {
        next[key] = patch[key];
      });
    }
    zoneRules[k] = clampRule(next);
  }

  function el(name, attrs) {
    var n = document.createElementNS(SVG_NS, name);
    if (attrs) {
      Object.keys(attrs).forEach(function (k) {
        n.setAttribute(k, attrs[k]);
      });
    }
    return n;
  }

  function applyResizeCorner(corner, rect0, dx, dy) {
    var x = rect0.x;
    var y = rect0.y;
    var w = rect0.w;
    var h = rect0.h;
    if (corner === "se") {
      w = rect0.w + dx;
      h = rect0.h + dy;
    } else if (corner === "nw") {
      x = rect0.x + dx;
      y = rect0.y + dy;
      w = rect0.w - dx;
      h = rect0.h - dy;
    } else if (corner === "ne") {
      y = rect0.y + dy;
      w = rect0.w + dx;
      h = rect0.h - dy;
    } else if (corner === "sw") {
      x = rect0.x + dx;
      w = rect0.w - dx;
      h = rect0.h + dy;
    }
    return normalizeRect(x, y, w, h);
  }

  function renderMap() {
    var layer = document.getElementById("ssws-zones-layer");
    if (!layer) return;
    while (layer.firstChild) {
      layer.removeChild(layer.firstChild);
    }

    zoneOrder.forEach(function (k, idx) {
      var r = mergeRule(k);
      var x = r.svg_x;
      var y = r.svg_y;
      var w = r.svg_w;
      var h = r.svg_h;
      var title = String(r.display_name || "Zone");
      var sub = String(r.subtitle || "").trim();
      var mcx = r.marker_x;
      var mcy = r.marker_y;
      var fill = GRAD_FILLS[idx % GRAD_FILLS.length];
      var stroke = STROKES[idx % STROKES.length];

      var rect = el("rect", {
        x: x,
        y: y,
        width: w,
        height: h,
        rx: "12",
        fill: fill,
        stroke: stroke,
        "stroke-width": "2.5",
        class: "ssws-zone-hit ss-map-zone",
        "data-zone": k,
        tabindex: "0",
      });
      layer.appendChild(rect);

      var cx = x + w / 2;
      var cyTitle = y + h / 2 - (h < 70 ? 4 : 8);
      var cySub = y + h / 2 + (h < 70 ? 10 : 14);
      var fsTitle = h < 56 ? "11" : "15";
      var fsSub = h < 56 ? "8" : "10";

      var t1 = el("text", {
        "pointer-events": "none",
        x: cx,
        y: cyTitle,
        "text-anchor": "middle",
        "font-size": fsTitle,
        "font-weight": "800",
        fill: "#fff",
      });
      t1.textContent = title;
      layer.appendChild(t1);

      if (sub) {
        var t2 = el("text", {
          "pointer-events": "none",
          x: cx,
          y: cySub,
          "text-anchor": "middle",
          "font-size": fsSub,
          "font-weight": "600",
          fill: "rgba(255,255,255,.9)",
        });
        t2.textContent = sub;
        layer.appendChild(t2);
      }

      var s = sensorForZone(k);
      var sid = s && s.id != null ? String(s.id) : "";

      var circle = el("circle", {
        class: "ssws-map-marker ss-map-marker",
        cx: mcx,
        cy: mcy,
        r: "11",
        fill: "#fef08a",
        stroke: "#ca8a04",
        "stroke-width": "2",
        "data-zone": k,
        "data-sensor-id": sid,
        "data-label": "Soil sensor · " + title,
        tabindex: "0",
        role: "button",
      });
      layer.appendChild(circle);

      if (activeZone === k) {
        var corners = ["nw", "ne", "sw", "se"];
        var hs = 9;
        var off = hs / 2;
        corners.forEach(function (corner) {
          var hx = corner.indexOf("e") >= 0 ? x + w - off : x - off;
          var hy = corner.indexOf("s") >= 0 ? y + h - off : y - off;
          var cursors = { nw: "nwse-resize", ne: "nesw-resize", sw: "nesw-resize", se: "nwse-resize" };
          var hnd = el("rect", {
            class: "ss-map-resize-handle",
            x: hx - off,
            y: hy - off,
            width: hs,
            height: hs,
            rx: "2",
            "data-zone": k,
            "data-corner": corner,
          });
          hnd.style.cursor = cursors[corner] || "nwse-resize";
          layer.appendChild(hnd);
        });
      }
    });
  }

  function sensorForZone(z) {
    for (var i = 0; i < sensors.length; i++) {
      if (sensors[i].zone_key === z) return sensors[i];
    }
    return null;
  }

  function formatLive(s) {
    if (!s) return "No live data yet.";
    var npk =
      s.npk_n != null && s.npk_p != null && s.npk_k != null
        ? " · NPK " +
          Math.round(s.npk_n) +
          "/" +
          Math.round(s.npk_p) +
          "/" +
          Math.round(s.npk_k)
        : "";
    return (
      "Live · " +
      (s.humidity != null ? Math.round(s.humidity) + "% humidity" : "—") +
      " · " +
      (s.temperature != null ? s.temperature + "°C" : "—") +
      npk +
      " · smoke " +
      (s.smoke != null ? Math.round(s.smoke) + "%" : "—") +
      " · status: " +
      (s.status || "—")
    );
  }

  function syncOutputs() {
    if (humVal && humIn) humVal.textContent = humIn.value;
    if (t1Val && t1In) t1Val.textContent = t1In.value;
    if (t2Val && t2In) t2Val.textContent = t2In.value;
    if (smVal && smIn) smVal.textContent = smIn.value;
  }

  function applyRulesToInputs(z) {
    var r = mergeRule(z);
    if (humIn) humIn.value = String(Math.round(r.humidity_water_below_pct));
    if (t1In) t1In.value = String(r.temp_normal_max_c);
    if (t2In) t2In.value = String(r.temp_warning_max_c);
    if (smIn) smIn.value = String(Math.round(r.smoke_alert_pct));
    if (nameIn) nameIn.value = r.display_name || "";
    syncOutputs();
  }

  function previewLayoutFromForm() {
    if (!activeZone) return;
    var k = activeZone;
    commitZoneRule(k, {
      humidity_water_below_pct: parseFloat(humIn.value),
      temp_normal_max_c: parseFloat(t1In.value),
      temp_warning_max_c: parseFloat(t2In.value),
      smoke_alert_pct: parseFloat(smIn.value),
      display_name: nameIn ? nameIn.value : "",
    });
    renderMap();
  }

  function openZone(z) {
    if (zoneOrder.indexOf(z) < 0) return;
    activeZone = z;
    if (placeholder) placeholder.hidden = true;
    if (editor) editor.hidden = false;
    var r = mergeRule(z);
    var zi = zoneIndex(z);
    if (titleEl) {
      titleEl.textContent = (r.display_name || "Zone") + " · " + z;
    }
    if (headEl) {
      headEl.classList.remove("ss-map-zone-head--a", "ss-map-zone-head--b", "ss-map-zone-head--c");
      var mod = zi % 3;
      headEl.classList.add(mod === 0 ? "ss-map-zone-head--a" : mod === 1 ? "ss-map-zone-head--b" : "ss-map-zone-head--c");
    }
    applyRulesToInputs(z);
    var s = sensorForZone(z);
    if (liveEl) liveEl.textContent = formatLive(s);
    if (msgEl) msgEl.textContent = "";
    renderMap();
  }

  function closePanel() {
    activeZone = null;
    if (placeholder) placeholder.hidden = false;
    if (editor) editor.hidden = true;
    renderMap();
  }

  function refreshEmptyState() {
    if (zoneOrder.length === 0) {
      closePanel();
      if (placeholder) {
        placeholder.hidden = false;
        placeholder.textContent = "No zones yet. Click “Add zone” to create one, then drag to place it on the map.";
      }
      if (editor) editor.hidden = true;
    }
  }

  function clientToSvgPt(svg, clientX, clientY) {
    var pt = svg.createSVGPoint();
    pt.x = clientX;
    pt.y = clientY;
    var ctm = svg.getScreenCTM();
    if (!ctm) return null;
    return pt.matrixTransform(ctm.inverse());
  }

  function dist2(ax, ay, bx, by) {
    var dx = ax - bx;
    var dy = ay - by;
    return dx * dx + dy * dy;
  }

  function loadZoneRules() {
    return fetch(window.sswsApi("api/zone_rules.php"), { credentials: "same-origin" })
      .then(function (r) {
        return r.json();
      })
      .then(function (data) {
        if (data.zones) {
          zoneRules = data.zones;
        }
        zoneOrder = Array.isArray(data.zone_order) ? data.zone_order : Object.keys(zoneRules || {});
        refreshEmptyState();
        renderMap();
        if (activeZone && zoneOrder.indexOf(activeZone) >= 0) {
          applyRulesToInputs(activeZone);
          var s = sensorForZone(activeZone);
          if (liveEl) liveEl.textContent = formatLive(s);
        } else if (activeZone && zoneOrder.indexOf(activeZone) < 0) {
          closePanel();
        }
      })
      .catch(function () {});
  }

  function loadSensorsOnly() {
    return fetch(window.sswsApi("api/get_sensors.php"), { credentials: "same-origin" })
      .then(function (r) {
        return r.json();
      })
      .then(function (sens) {
        if (Array.isArray(sens)) {
          sensors = sens;
        }
        renderMap();
        if (activeZone) {
          var s = sensorForZone(activeZone);
          if (liveEl) liveEl.textContent = formatLive(s);
        }
      })
      .catch(function () {});
  }

  function clearPointerState() {
    drag = null;
    pending = null;
  }

  if (fieldSvg) {
    fieldSvg.addEventListener("pointerdown", function (e) {
      var t = e.target;
      if (!t || !t.closest) return;

      var handle = t.closest(".ss-map-resize-handle");
      var marker = t.closest(".ssws-map-marker, .ss-map-marker");
      var zoneRect = t.closest(".ssws-zone-hit");

      if (handle) {
        e.preventDefault();
        var zone = handle.getAttribute("data-zone");
        var corner = handle.getAttribute("data-corner");
        var svgPt = clientToSvgPt(fieldSvg, e.clientX, e.clientY);
        if (!svgPt || !zone || !corner) return;
        var r = mergeRule(zone);
        drag = {
          kind: "resize",
          corner: corner,
          zone: zone,
          startSvg: { x: svgPt.x, y: svgPt.y },
          rect0: { x: r.svg_x, y: r.svg_y, w: r.svg_w, h: r.svg_h },
        };
        activeZone = zone;
        openZone(zone);
        try {
          fieldSvg.setPointerCapture(e.pointerId);
        } catch (err) {}
        return;
      }

      if (marker) {
        e.preventDefault();
        var z = marker.getAttribute("data-zone");
        var svgPt2 = clientToSvgPt(fieldSvg, e.clientX, e.clientY);
        if (!svgPt2 || !z) return;
        var rm = mergeRule(z);
        drag = {
          kind: "marker",
          zone: z,
          startSvg: { x: svgPt2.x, y: svgPt2.y },
          marker0: { x: rm.marker_x, y: rm.marker_y },
          rect: { x: rm.svg_x, y: rm.svg_y, w: rm.svg_w, h: rm.svg_h },
        };
        activeZone = z;
        openZone(z);
        try {
          fieldSvg.setPointerCapture(e.pointerId);
        } catch (err) {}
        return;
      }

      if (zoneRect) {
        e.preventDefault();
        var zz = zoneRect.getAttribute("data-zone");
        var svgPt3 = clientToSvgPt(fieldSvg, e.clientX, e.clientY);
        if (!svgPt3 || !zz) return;
        var rz = mergeRule(zz);
        pending = {
          kind: "zone",
          zone: zz,
          clientX: e.clientX,
          clientY: e.clientY,
          startSvg: { x: svgPt3.x, y: svgPt3.y },
          rect0: { x: rz.svg_x, y: rz.svg_y, w: rz.svg_w, h: rz.svg_h },
          marker0: { x: rz.marker_x, y: rz.marker_y },
          pointerId: e.pointerId,
        };
        try {
          fieldSvg.setPointerCapture(e.pointerId);
        } catch (err) {}
      }
    });
  }

  document.addEventListener(
    "pointermove",
    function (e) {
      if (drag) {
        if (drag.kind === "resize") {
          var svgPt = clientToSvgPt(fieldSvg, e.clientX, e.clientY);
          if (!svgPt) return;
          var dx = svgPt.x - drag.startSvg.x;
          var dy = svgPt.y - drag.startSvg.y;
          var nr = applyResizeCorner(drag.corner, drag.rect0, dx, dy);
          var cur = mergeRule(drag.zone);
          commitZoneRule(drag.zone, {
            svg_x: nr.x,
            svg_y: nr.y,
            svg_w: nr.w,
            svg_h: nr.h,
            marker_x: cur.marker_x,
            marker_y: cur.marker_y,
          });
          renderMap();
          return;
        }
        if (drag.kind === "marker") {
          var svgPm = clientToSvgPt(fieldSvg, e.clientX, e.clientY);
          if (!svgPm) return;
          var dxm = svgPm.x - drag.startSvg.x;
          var dym = svgPm.y - drag.startSvg.y;
          var rx = drag.rect.x;
          var ry = drag.rect.y;
          var rw = drag.rect.w;
          var rh = drag.rect.h;
          var mx = drag.marker0.x + dxm;
          var my = drag.marker0.y + dym;
          mx = Math.max(rx + MR, Math.min(rx + rw - MR, mx));
          my = Math.max(ry + MR, Math.min(ry + rh - MR, my));
          commitZoneRule(drag.zone, { marker_x: mx, marker_y: my });
          renderMap();
          return;
        }
      }

      if (pending && pending.kind === "zone" && !drag) {
        if (dist2(e.clientX, e.clientY, pending.clientX, pending.clientY) > TAP_PX * TAP_PX) {
          drag = {
            kind: "move",
            zone: pending.zone,
            startSvg: pending.startSvg,
            rect0: pending.rect0,
            marker0: pending.marker0,
          };
          activeZone = pending.zone;
          openZone(pending.zone);
          pending = null;
        }
      }

      if (drag && drag.kind === "move") {
        var svgPm2 = clientToSvgPt(fieldSvg, e.clientX, e.clientY);
        if (!svgPm2) return;
        var dx2 = svgPm2.x - drag.startSvg.x;
        var dy2 = svgPm2.y - drag.startSvg.y;
        var x = drag.rect0.x + dx2;
        var y = drag.rect0.y + dy2;
        var w = drag.rect0.w;
        var h = drag.rect0.h;
        x = Math.max(0, Math.min(400 - w, x));
        y = Math.max(0, Math.min(280 - h, y));
        var mdx = x - drag.rect0.x;
        var mdy = y - drag.rect0.y;
        commitZoneRule(drag.zone, {
          svg_x: x,
          svg_y: y,
          marker_x: drag.marker0.x + mdx,
          marker_y: drag.marker0.y + mdy,
        });
        renderMap();
      }
    },
    { passive: false }
  );

  document.addEventListener("pointerup", function (e) {
    if (pending && pending.kind === "zone" && pending.pointerId === e.pointerId && !drag) {
      if (dist2(e.clientX, e.clientY, pending.clientX, pending.clientY) <= TAP_PX * TAP_PX) {
        openZone(pending.zone);
      }
      pending = null;
      try {
        if (fieldSvg) fieldSvg.releasePointerCapture(e.pointerId);
      } catch (err) {}
      return;
    }

    if (drag) {
      try {
        if (fieldSvg) fieldSvg.releasePointerCapture(e.pointerId);
      } catch (err) {}
      drag = null;
      pending = null;
    }
  });

  document.addEventListener("pointercancel", function (e) {
    clearPointerState();
    try {
      if (fieldSvg) fieldSvg.releasePointerCapture(e.pointerId);
    } catch (err) {}
  });

  [humIn, t1In, t2In, smIn].forEach(function (inp) {
    if (inp) inp.addEventListener("input", syncOutputs);
  });

  if (nameIn) {
    nameIn.addEventListener("input", previewLayoutFromForm);
    nameIn.addEventListener("change", previewLayoutFromForm);
  }

  [humIn, t1In, t2In, smIn].forEach(function (inp) {
    if (inp) {
      inp.addEventListener("input", previewLayoutFromForm);
      inp.addEventListener("change", previewLayoutFromForm);
    }
  });

  function postZoneApi(body) {
    return fetch(window.sswsApi("api/zone_rules.php"), {
      method: "POST",
      credentials: "same-origin",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    }).then(function (r) {
      return r.json().then(function (j) {
        return { ok: r.ok, j: j };
      });
    });
  }

  function buildSaveBodyForZone(k) {
    var r = mergeRule(k);
    return {
      action: "save",
      zone: k,
      display_name: r.display_name,
      subtitle: r.subtitle || "",
      svg_x: r.svg_x,
      svg_y: r.svg_y,
      svg_w: r.svg_w,
      svg_h: r.svg_h,
      marker_x: r.marker_x,
      marker_y: r.marker_y,
      humidity_water_below_pct: r.humidity_water_below_pct,
      temp_normal_max_c: r.temp_normal_max_c,
      temp_warning_max_c: r.temp_warning_max_c,
      smoke_alert_pct: r.smoke_alert_pct,
    };
  }

  if (saveBtn) {
    saveBtn.addEventListener("click", function () {
      if (!humIn || !t1In || !t2In || !smIn) return;
      if (zoneOrder.length === 0) {
        if (msgEl) msgEl.textContent = "No zones to save.";
        return;
      }
      if (activeZone) {
        previewLayoutFromForm();
      }
      var keys = zoneOrder.slice();
      var idx = 0;
      var total = keys.length;

      function saveNext() {
        if (idx >= keys.length) {
          return;
        }
        var k = keys[idx];
        if (msgEl) {
          msgEl.textContent = total > 1 ? "Saving… (" + (idx + 1) + "/" + total + ")" : "Saving…";
        }
        postZoneApi(buildSaveBodyForZone(k))
          .then(function (x) {
            if (!x.ok || !x.j.zones) {
              if (msgEl) {
                var err = (x.j && x.j.error) || "Save failed.";
                if (x.j && x.j.detail) {
                  err += " — " + x.j.detail;
                }
                err += " (zone " + k + ")";
                msgEl.textContent = err;
              }
              loadZoneRules().then(function () {
                return loadSensorsOnly();
              });
              return;
            }
            idx++;
            if (idx >= keys.length) {
              zoneRules = x.j.zones;
              zoneOrder = Array.isArray(x.j.zone_order) ? x.j.zone_order : Object.keys(zoneRules);
              if (msgEl) msgEl.textContent = "Saved.";
              renderMap();
              if (activeZone && zoneOrder.indexOf(activeZone) >= 0) {
                applyRulesToInputs(activeZone);
              }
              return loadSensorsOnly();
            }
            saveNext();
          })
          .catch(function () {
            if (msgEl) msgEl.textContent = "Network error (zone " + k + ").";
            loadZoneRules().then(function () {
              return loadSensorsOnly();
            });
          });
      }

      saveNext();
    });
  }

  if (addBtn) {
    addBtn.addEventListener("click", function () {
      if (msgEl) msgEl.textContent = "Adding…";
      postZoneApi({ action: "create" })
        .then(function (x) {
          if (x.ok && x.j.zones) {
            zoneRules = x.j.zones;
            zoneOrder = Array.isArray(x.j.zone_order) ? x.j.zone_order : Object.keys(zoneRules);
            if (msgEl) msgEl.textContent = "";
            if (x.j.zone_key) {
              openZone(x.j.zone_key);
            }
            return loadSensorsOnly();
          }
          if (msgEl) msgEl.textContent = (x.j && x.j.error) || "Could not add zone.";
        })
        .catch(function () {
          if (msgEl) msgEl.textContent = "Network error.";
        });
    });
  }

  if (removeBtn) {
    removeBtn.addEventListener("click", function () {
      if (!activeZone) return;
      if (!window.confirm("Remove this zone from the map? Rules for it will be deleted.")) return;
      if (msgEl) msgEl.textContent = "Removing…";
      postZoneApi({ action: "delete", zone: activeZone })
        .then(function (x) {
          if (x.ok && x.j.zones) {
            zoneRules = x.j.zones;
            zoneOrder = Array.isArray(x.j.zone_order) ? x.j.zone_order : Object.keys(zoneRules);
            if (msgEl) msgEl.textContent = "";
            activeZone = null;
            refreshEmptyState();
            return loadSensorsOnly();
          }
          if (msgEl) msgEl.textContent = (x.j && x.j.error) || "Could not remove zone.";
        })
        .catch(function () {
          if (msgEl) msgEl.textContent = "Network error.";
        });
    });
  }

  loadZoneRules().then(function () {
    return loadSensorsOnly();
  });
  setInterval(loadSensorsOnly, 15000);
})();
