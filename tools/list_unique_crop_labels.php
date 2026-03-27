<?php
$path = dirname(__DIR__) . "/ai_services/recommendations/Crop_recommendation.csv";
$f = fopen($path, "r");
if (!$f) {
    die("no csv\n");
}
$header = fgetcsv($f);
$labels = [];
while (($r = fgetcsv($f)) !== false) {
    if (isset($r[7])) {
        $labels[$r[7]] = true;
    }
}
fclose($f);
ksort($labels);
echo implode("\n", array_keys($labels));
