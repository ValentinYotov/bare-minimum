/**
 * Build a tel: URL (digits + optional leading +). Shared by Settings “Test call” and fire overlay.
 */
window.sswsTelHref = function (phone) {
  if (!phone) {
    return "";
  }
  var t = String(phone).trim();
  var leadingPlus = t.charAt(0) === "+";
  var digits = t.replace(/\D/g, "");
  if (!digits) {
    return "";
  }
  return "tel:" + (leadingPlus ? "+" : "") + digits;
};

(function () {
  const menuBtn = document.getElementById("ssws-menu-btn");
  const sidebar = document.getElementById("ssws-sidebar");
  const layout = document.getElementById("ssws-layout");

  function closeMenu() {
    if (!sidebar || !layout) return;
    sidebar.classList.remove("is-open");
    layout.classList.remove("ssws-layout--dim");
    if (menuBtn) menuBtn.setAttribute("aria-expanded", "false");
  }

  function openMenu() {
    if (!sidebar || !layout) return;
    sidebar.classList.add("is-open");
    layout.classList.add("ssws-layout--dim");
    if (menuBtn) menuBtn.setAttribute("aria-expanded", "true");
  }

  if (menuBtn && sidebar && layout) {
    menuBtn.addEventListener("click", function () {
      if (sidebar.classList.contains("is-open")) {
        closeMenu();
      } else {
        openMenu();
      }
    });

    layout.addEventListener("click", function (e) {
      if (e.target === layout && sidebar.classList.contains("is-open")) {
        closeMenu();
      }
    });
  }

  document.querySelectorAll(".ssws-sidebar__link").forEach(function (link) {
    link.addEventListener("click", function () {
      if (window.matchMedia("(max-width: 900px)").matches) {
        closeMenu();
      }
    });
  });

  const fab = document.getElementById("ssws-fab-help");
  if (fab) {
    fab.addEventListener("click", function () {
      alert("SSWS help — contact your team for support.");
    });
  }
})();
