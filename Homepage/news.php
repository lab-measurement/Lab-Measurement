<?xml version="1.0" encoding="utf8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de">
<head>
<title>Lab::Measurement - measurement control in Perl: News</title>
<link rel="stylesheet" type="text/css" href="doku.css" />
</head>
<body>
<div id="header"><img id="logo" src="header.png" alt="Lab::Measurement"/></div>
<div id="toc">
    <h1>Links</h1>
    <?php include 'deflinks.html'; ?>
    <h2>Download Lab::Measurement</h2>
    <ul>
        <li><a href="http://search.cpan.org/dist/Lab-Measurement/">CPAN releases</a></li>
        <li><a href="https://www.gitorious.org/lab-measurement/">Gitorious</a></li>
        <li><a href="http://www.labmeasurement.de/gitweb/?p=labmeasurement;a=summary">Gitweb browser</a></li>
    </ul>
</div>

<?php 

define('MAGPIE_CACHE_DIR', '/tmp/labmeasurement_magpie_cache');

require_once 'magpierss/rss_fetch.inc';

$url = 'http://dilfridge.blogspot.com/feeds/posts/default/-/lab-measurement';
$rss = fetch_rss($url);
$counter = 1;

foreach ($rss->items as $item ) {
    if ($counter<15) {
        $title = $item[title];
        $url   = $item[link];
        $published = preg_replace('/T.*$/','',$item[published]);
        echo "<a name='pos$counter'><h2>$title &nbsp; <font size='-1'>(posted $published)</font></h2></a>\n";
        echo "<p>$item[atom_content]</p>\n\n";
        $counter++;
    };
}

?>

</body>
</html>
