<?php

function description() {
    out('-----------------------------------');
    out('Wordpress media library backup tool');
    out('-----------------------------------');
}

function download($file_name, $dest_basedir) {
    $xml = file_get_contents($file_name);
    preg_match_all('/<wp:attachment_url>(?:<!\[CDATA\[)*(.*?)(?:\]\]>)*<\/wp:attachment_url>/', $xml, $urls);
    out(date('Y-m-d H:i:s') . ' - Download started');

    foreach($urls[1] as $u) {
        out('CHCK', 'cyan', false);
        $u = str_replace(['%3A', '%2F'], [':', '/'], rawurlencode($u));
        echo " > $u";

        $dest_dir = $dest_basedir . str_replace(basename($u), '', parse_url($u)['path']);
        if (!is_dir($dest_dir)) mkdir($dest_dir, 0777, true);
        $dest_file = $dest_dir . DIRECTORY_SEPARATOR . basename($u);

        $remote_mod = strtotime(get_headers($u, 1)['Last-Modified'] ?? '2099-12-31');
        $local_mod = is_file($dest_file) ? filemtime($dest_file) : 0;

        if ($remote_mod > $local_mod) {
            out('DOWN', 'green');
            $s = fopen($u, 'r');
            $d = fopen($dest_dir . DIRECTORY_SEPARATOR . basename($u), 'w+');
            stream_copy_to_stream($s, $d);
        }
        else {
            out('SKIP', 'yellow');
        }
    }
    out(date('Y-m-d H:i:s') . ' - Download finished');
}

function out($msg, $color = null, $eol = true) {
    $colorCodes = ['cyan' => 36, 'red' => 31, 'green' => 32, 'yellow' => 33];
    echo $color ? ("\r" . "\x1b[" . $colorCodes[$color] . 'm' . $msg . "\x1b[0m") : $msg;
    if ($eol) echo PHP_EOL;
}

function usage($argv) {
    out('Usage', 'green', true);
    out('php backup.php <source-file>.xml <destination>', 'green', true);
    if (empty($argv[1])) {
        out('Please provide source file name, e.g. export.xml', 'red', true);
    }
    if (empty($argv[2])) {
        out('Please provide destination directory name, e.g. export', 'red', true);
    }
}

description();
(empty($argv[1]) || empty($argv[2])) ? usage($argv) : download($argv[1], $argv[2]);
