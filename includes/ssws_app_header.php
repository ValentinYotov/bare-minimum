<?php
$ssws_page_title = $ssws_page_title ?? "SSWS";
?>
<header class="ssws-topbar">
    <button type="button" class="ssws-topbar__menu" id="ssws-menu-btn" aria-label="Open menu" aria-expanded="false">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
    </button>
    <div class="ssws-topbar__spacer"></div>
    <div class="ssws-topbar__status">
        <span class="ssws-pill ssws-pill--online"><span class="ssws-dot"></span> System Online</span>
        <button type="button" class="ssws-icon-btn" aria-label="Notifications">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
            <span class="ssws-icon-btn__badge"></span>
        </button>
    </div>
</header>
