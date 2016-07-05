<?xml version="1.0" encoding="utf8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="de">
<head>
<title>Lab::Measurement - Measurement control with Perl</title>
<meta property="og:title" content="Lab::Measurement - Measurement control with Perl" />
<meta property="og:type" content="product" />
<meta property="og:url" content="http://www.labmeasurement.de/" />
<meta property="og:image" content="http://www.labmeasurement.de/screen.png" />
<meta property="og:site_name" content="Lab::Measurement" />
<meta property="fb:admins" content="1016535977" />
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
        <li><a href="https://github.com/lab-measurement/lab-measurement">Github</a></li>
        <li><a href="/gitweb/?p=labmeasurement;a=summary">Gitweb browser</a></li>
    </ul>
    <br>
    <iframe
      src="//www.facebook.com/plugins/like.php?href=http%3A%2F%2Fwww.labmeasurement.de%2F&amp;send=false&amp;layout=button_count&amp;width=100&amp;show_faces=false&amp;action=like&amp;colorscheme=light&amp;font=arial&amp;height=21"
      scrolling="no" frameborder="0" style="border:none; overflow:hidden; width:100px; height:21px;" allowTransparency="true"></iframe>
</div>

<p>Lab::Measurement allows to perform test and measurement tasks with Perl 5
scripts. It provides an interface to several instrumentation control backends,
as e.g. <a href="http://linux-gpib.sourceforge.net/">Linux-GPIB</a> or National Instruments' <a
href="http://sine.ni.com/psp/app/doc/p/id/psp-411">NI-VISA library</a>.
Dedicated instrument driver classes relieve the user from taking care
of internal details and make data aquisition as easy as
<pre class="titleclaim">$voltage = $multimeter-&gt;get_voltage();</pre>
</p>

<p>The Lab::Measurement software stack consists of several parts that are built
on top of each other. This modularization allows support for a wide range of hardware
on different operating systems. As hardware drivers vary in API details, each 
supported one is encapsulated into Perl modules of types <i>Lab::Bus</i> and 
<i>Lab::Connection</i>. Normally you won't have to care about this; at most, 
your Instrument object (see below) gets different initialization parameters.</p>

<p>A typical measurement script is based on the high-level interface provided by the modules 
<i>Lab::Instrument</i> and <i>Lab::Measurement</i>. The former silently handles all the 
protocol overhead. You can write commands to an instrument and read the result. Drivers 
for specific devices are included, implementing their specific command syntax; more can 
easily be added to provide high-level functions. The latter includes tools to automatically 
generate measurement loops, for metadata handling (what was that amplifier setting in the 
measurement again?!), data plotting, and similar.</p>

<p>
While <i>Lab::Measurement</i> has built-in support for devices connected, e.g., via
ethernet, serial port, or the Linux USB Test&amp;Measurement kernel driver, you 
may want to additionally install driver backends such as
<a href="http://search.cpan.org/dist/Lab-VISA/"><i>Lab::VISA</i></a> or
<a href="http://linux-gpib.sourceforge.net/" target="_blank"><i>LinuxGPIB</i></a>.
</p>

<h2>Contact</h2>
<ul>
  <li> Join the <a href="http://webchat.freenode.net/?channels=labmeasurement">
  #labmeasurement</a> channel on Freenode IRC </li>
  <li> Join our <a href="https://www-mailman.uni-regensburg.de/mailman/listinfo/lab-measurement-users"> mailing list</a></li>
</ul>

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
        $title = $item['title'];
        $published = preg_replace('/T.*$/','',$item['published']);
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
from CPAN</a>. The <a href="https://github.com/lab-measurement/lab-measurement">source code archive can 
be found at Github</a>, where you can also obtain the newest pre-release code and 
browse the version history. If you would like to contribute, just send us your patches, 
merge requests, ... :) For browsing the code we also have a direct 
<a href="/gitweb/?p=labmeasurement;a=summary">gitweb access</a>.
</p>

<h2>Documentation</h2>
<p>Quite some <a href="docs/index.html">documentation of Lab::Measurement</a>
(<a href="docs/documentation.pdf">PDF format</a>) is available. This
documentation includes a <a href="docs/Measurement-Tutorial.html">tutorial on
using Lab::Measurement</a> (outdated). Detailed <a href="docs/Measurement-Installation.html">installation
instructions</a> are provided as well. In addition, there's also a collection
of <a href="backends.html">back-end specific documentation and links</a>.
</p>

<h2>Status</h2>
<p>Lab::Measurement is a the result of a full restructuring of the code of its predecessor
Lab::VISA. Some time ago a new high-level interface, named Lab::XPRESS, was added. It provides for example
automated measurement loops; check the XPRESS example scripts on the <a href="docs/index.html">documentation page</a>. 
This has now stabilized and replaced the previous Lab::Measurement high level interface fully in our applications. Since the old
high level interface is not being used anymore, starting with upcoming 3.600 release we
will remove it to keep the package size maintainable. In general, if you want to use Lab::Measurement,
it definitely helps to get in touch with us and contribute patches.<p>

<p>Lab::Measurement is currently developed and employed at the <a
href="http://www.physik.uni-regensburg.de/forschung/huettel/">carbon nanotube transport and nanomechanics 
group, Uni Regensburg</a>. Previously it has been used at, e.g., LMU München and Weizmann Institute of Science, 
and we have heard about further applications in industrial r&amp;d 
environments. Feel free to try it, to hack, and to send us your improvements and bugfixes.</p>

<h2>Authors and history</h2>
<p>The Lab::VISA system was originally developed by <a
    href="http://search.cpan.org/~schroeer/">Daniel Schr&ouml;er</a> and
continued by <a href="http://www.akhuettel.de/">Andreas K.
H&uuml;ttel</a>, Daniela Taubert, and Daniel Schr&ouml;er. Most of the documentation was
written by Daniel Schr&ouml;er. In 2011, the code was refactored mostly by Florian Olbrich
to include the Bus and Connection layers; subsequently the name of the entire package collection
was changed to Lab::Measurement. David Kalok, Hermann Kraus, and Alois Dirnaichner have contributed 
additional code. The new Lab::XPRESS layer was contributed by  Christian Butschkow, Stefan Geissler and 
Alexei Iankilevitch; current development is pushed ahead by Simon Reinhardt.
</p>

<h2>Acknowledgments</h2>
<p>The continued improvement of Lab::Measurement was supported by the
<a href="http://www.dfg.de/en/" target="_blank">Deutsche Forschungsgemeinschaft</a>
via grants Hu 1808/1 (Emmy Noether program) and collaborative research centre 
<a href="http://www-app.uni-regensburg.de/Fakultaeten/Physik/sfb689/" target="_blank">SFB 689</a>.
</p>

<p>
<img src="logo-sfb689.png" height="150" alt="SFB 689 logo"> 
<img src="logo-emmy.png" height="150" alt="Emmy Noether logo">
</p>

</body>
</html>
