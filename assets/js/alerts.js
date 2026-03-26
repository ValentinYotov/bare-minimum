(function () {
  const feed = document.getElementById("ssws-alert-feed");
  const statActive = document.getElementById("ssws-stat-active");
  const statResolved = document.getElementById("ssws-stat-resolved");

  function countVisible() {
    if (!feed) return 0;
    return feed.querySelectorAll(".ssws-alert-item:not([hidden])").length;
  }

  function updateActiveCount() {
    if (statActive) statActive.textContent = String(countVisible());
  }

  document.querySelectorAll(".js-alert-resolve").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var card = btn.closest(".ssws-alert-item");
      if (!card) return;
      card.setAttribute("hidden", "hidden");
      if (statResolved) {
        var n = parseInt(statResolved.textContent, 10) || 0;
        statResolved.textContent = String(n + 1);
      }
      updateActiveCount();
    });
  });

  document.querySelectorAll(".js-alert-view").forEach(function (btn) {
    btn.addEventListener("click", function () {
      var card = btn.closest(".ssws-alert-item");
      if (!card) return;
      var id = card.getAttribute("data-alert-id") || "";
      var title = card.querySelector("h3");
      var titleText = title ? title.textContent : "Alert";
      alert(titleText + "\n\nFull detail view can open a dedicated page or modal when your API is connected.\nID: " + id);
    });
  });

  updateActiveCount();
})();
