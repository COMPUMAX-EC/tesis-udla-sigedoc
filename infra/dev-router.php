<?php
// Router para `php -S`: un solo puerto sirve la app Flutter web y la API Laravel.
// Equivale, en desarrollo, al Nginx de docs/arquitectura.md (/api/* → Laravel, resto → build de Flutter).
$raiz = dirname(__DIR__);
$ruta = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?: '/';

if (str_starts_with($ruta, '/api/') || $ruta === '/up') {
    $publico = "$raiz/backend/public";
    chdir($publico);
    $_SERVER['SCRIPT_FILENAME'] = "$publico/index.php";
    $_SERVER['SCRIPT_NAME'] = '/index.php';
    $_SERVER['PHP_SELF'] = '/index.php';
    require "$publico/index.php";
    return true;
}

$web = "$raiz/frontend/build/web";
if ($ruta !== '/' && is_file($web.$ruta)) {
    return false; // archivo estático del build
}
header('Content-Type: text/html; charset=utf-8');
readfile("$web/index.html");
return true;
