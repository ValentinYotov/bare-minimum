<?php
$nav = [
    ["dashboard.php", "Dashboard", "dashboard", '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>'],
    ["chat.php", "AI Chat", "chat", '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>'],
    ["recommendations.php", "Recommendations", "recommendations", '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 18h6M10 22h4M12 2v1M12 7v1M4.22 10.22l.7.7M7 12H6M18 12h-1M19.78 10.22l-.7.7M6.34 17.66l.7-.7M17.66 17.66l-.7-.7M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8z"/></svg>'],
    ["map.php", "Map View", "map", '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="1 6 1 22 8 18 16 22 23 18 23 2 16 6 8 2 1 6"/><line x1="8" y1="2" x2="8" y2="18"/><line x1="16" y1="6" x2="16" y2="22"/></svg>'],
    ["alerts.php", "Alerts", "alerts", '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>'],
    ["settings.php", "Settings", "settings", '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42"/></svg>'],
];
?>
<aside class="ssws-sidebar" id="ssws-sidebar" aria-label="Main navigation">
    <div class="ssws-sidebar__brand">
        <span class="ssws-sidebar__logo" aria-hidden="true">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none"><path d="M12 22c4-4 8-8 8-12a8 8 0 1 0-16 0c0 4 4 8 8 12z" fill="currentColor" opacity=".2"/><path d="M12 2v8M8 10c0-2 1.5-4 4-4s4 2 4 4" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
        </span>
        <span class="ssws-sidebar__name">AgroGuard</span>
    </div>
    <nav class="ssws-sidebar__nav">
        <?php foreach ($nav as $item) :
            [$href, $label, $key, $icon] = $item;
            $isActive = ($ssws_active === $key);
            ?>
            <a class="ssws-sidebar__link<?php echo $isActive ? " is-active" : ""; ?>" href="<?php echo htmlspecialchars($href, ENT_QUOTES, "UTF-8"); ?>" <?php if ($isActive) echo 'aria-current="page"'; ?>>
                <span class="ssws-sidebar__icon"><?php echo $icon; ?></span>
                <?php echo htmlspecialchars($label, ENT_QUOTES, "UTF-8"); ?>
            </a>
        <?php endforeach; ?>
    </nav>
    <div class="ssws-sidebar__footer">
        <a class="ssws-sidebar__logout" href="logout.php">Log out</a>
    </div>
</aside>
