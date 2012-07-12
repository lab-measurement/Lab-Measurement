<?xml version="1.0" encoding="utf8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de">
<head>
<title>Lab::Measurement - measurement control in Perl</title>
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

<p>Lab::Measurement allows to perform test and measurement tasks with Perl
scripts. It provides an interface to several instrumentation control backends,
as e.g. <a href="http://linux-gpib.sourceforge.net/">Linux-GPIB</a> or National Instruments' <a
href="http://sine.ni.com/psp/app/doc/p/id/psp-411">NI-VISA library</a>.
Dedicated instrument driver classes relieve the user from taking care
for internal details and make data aquisition as easy as
<pre class="titleclaim">$voltage = $multimeter-&gt;get_voltage();</pre>
</p>

<p>The Lab::Measurement software stack comprises several parts that are built
on top of each other. This modularization allows support for a wide range of hardware
on different operating systems. As hardware drivers vary in API details, each 
supported one is encapsulated into perl modules of types <i>Lab::Bus</i> and 
<i>Lab::Connection</i>. Normally you won't have to care about this; at most, 
your Instrument object (see below) gets different initialization parameters.</p>

<p>A typical measurement script is based on the high-level interface provided by the modules 
<i>Lab::Instrument</i> and <i>Lab::Measurement</i>. The former silently handles all the 
protocol overhead. You can write commands to an instrument and read the result. Drivers 
for specific devices are included, implementing their specific command syntax; more can 
easily be added to provide high-level functions. The latter includes tools for metadata 
handling (what was that amplifier setting in the measurement again?!), data plotting, and 
similar.</p>

<p>These classes together are distributed as the Lab::Measurement system.
Designed to make data aquisition fun!</p>

<h2>News</h2>

<p>
<ul>
<?php 

define('MAGPIE_CACHE_DIR', '/tmp/labmeasurement_magpie_cache');

require_once 'magpierss/rss_fetch.inc';

$url = 'http://dilfridge.blogspot.com/feeds/posts/default/-/lab-measurement';
$rss = fetch_rss($url);
$counter = 1;

foreach ($rss->items as $item ) {
    if ($counter<5) {
        $title = $item[title];
        $published = preg_replace('/T.*$/','',$item[published]);
        echo "<li><a href='news.php#pos$counter'>";
        if ($counter == 1) { echo "<b>"; };
        echo "$published: $title";
        if ($counter == 1) { echo "</b>"; };
        echo "</a></li>\n";
        $counter++;
    };
}

?>
</ul>
</p>

<h2>How to obtain</h2>
<p>
Lab::Measurement is free software and can be <a href="http://search.cpan.org/dist/Lab-Measurement/">downloaded 
from CPAN</a>. The <a href="https://www.gitorious.org/lab-measurement/">source code archive is 
hosted at Gitorious</a>, where you can also obtain the newest pre-release code and 
browse the version history. If you would like to contribute, just send us your patches, 
merge requests, ... :) For browsing the code we also have a direct 
<a href="/gitweb/?p=labmeasurement/.git">gitweb access</a>.
</p>

<h2>Documentation</h2>
<p>Quite some <a href="docs/index.html">documentation of Lab::Measurement</a>
(<a href="docs/documentation.pdf">PDF format</a>) is available. This
documentation includes a <a href="docs/Tutorial.html">tutorial on
using Lab::Measurement</a> (outdated). Detailed <a href="docs/installation.html">installation
instructions</a> are provided as well. In addition, there's also a collection
of <a href="backends.html">back-end specific documentation and links</a>.
</p>
<p>There is a <a
    href="https://www-mailman.uni-regensburg.de/mailman/listinfo/lab-visa-users">mailing
list (lab-visa-users)</a> set up for Lab::VISA and Lab::Measurement. This mailing list is the
right place to give feedback and ask for help.</p>

<h2>Status</h2>
<p>Lab::Measurement is a the result of a full restructuring of the code of its predecessor
Lab::VISA. By now it has reached a sufficient stability, and we recommend everyone to upgrade.
Some high-level drivers from Lab::VISA have not been ported yet, but that will be addressed 
soon...<p>

<p>Lab::Measurement and its predecessor Lab::VISA are currently developed and employed at <a
href="http://www.nano.physik.uni-muenchen.de/">nanophysics group, LMU M&uuml;nchen</a> and <a
href="http://www.physik.uni-regensburg.de/forschung/strunk/">mesoscopic physics group, Uni 
Regensburg</a>. Users have reported further applications in academic and industrial r&amp;d 
environments. Feel free to try it, to hack, and to send us your improvements and bugfixes.</p>

<h2>Authors and history</h2>
<p>The Lab::VISA system was originally developed by <a
    href="http://search.cpan.org/~schroeer/">Daniel Schr&ouml;er</a> and
continued by <a href="http://www.akhuettel.de/">Andreas K.
H&uuml;ttel</a>, Daniela Taubert, and Daniel Schr&ouml;er. Most of the documentation was
written by Daniel Schr&ouml;er. In 2011, the code was refactored mostly by Florian Olbrich
to include the Bus and Connection layers; subsequently the name of the entire package collection
was changed to Lab::Measurement. Current lead developer is Alois Dirnaichner.
</p>

</body>
</html>
