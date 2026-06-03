<?php
// ATTRIBUTION: Original script by
// https://kywch.github.io/jsPsych-in-Qualtrics/save-php/ (accessed 2024-03-29)
// modified here for continuous jsonl saving and a fixed server-side save directory.

$allowed_origins = [
    'https://brainsci.uber.space',
    'https://brainsci.uberspace.de',
];

if (isset($_SERVER['HTTP_ORIGIN']) && in_array($_SERVER['HTTP_ORIGIN'], $allowed_origins, true)) {
    header('Access-Control-Allow-Origin: ' . $_SERVER['HTTP_ORIGIN']);
    header('Vary: Origin');
}

header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit('Method not allowed.');
}

if (!isset($_POST['exp_data'], $_POST['file_name'], $_POST['experiment_folder'])) {
    http_response_code(400);
    exit('Missing required fields.');
}

$exp_data = (string) $_POST['exp_data'];
$file_name = basename((string) $_POST['file_name']);
$experiment_folder = basename((string) $_POST['experiment_folder']);

if (!preg_match('/^[A-Za-z0-9._-]+$/', $file_name)) {
    http_response_code(400);
    exit('Invalid file name.');
}

if (!preg_match('/^[A-Za-z0-9._-]+$/', $experiment_folder)) {
    http_response_code(400);
    exit('Invalid experiment folder.');
}

// Store data in the specific experiment folder next to /exp_data/.
$data_dir = dirname(__DIR__) . '/' . $experiment_folder . '/data';

if (!is_dir($data_dir) && !mkdir($data_dir, 0775, true)) {
    http_response_code(500);
    exit('Failed to create data directory.');
}

$target_path = $data_dir . '/' . $file_name;
$bytes_written = file_put_contents($target_path, $exp_data, FILE_APPEND | LOCK_EX);

if ($bytes_written === false) {
    http_response_code(500);
    exit('Failed to write data.');
}

echo 'OK';
exit;
?>
