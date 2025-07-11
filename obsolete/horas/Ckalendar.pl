#!/usr/bin/perl
use utf8;

# Name : Laszlo Kiss
# Date : 01-20-08
# Divine Office Kalendarium
package horas;

#1;
#use warnings;
#use strict "refs";
#use strict "subs";
#use warnings FATAL=>qw(all);

use POSIX;
use FindBin qw($Bin);
use CGI;
use CGI::Cookie;
use CGI::Carp qw(fatalsToBrowser);
use File::Basename;
use Time::Local;

#use DateTime;
use locale;
use lib "$Bin/..";
use DivinumOfficium::Main qw(load_versions);
$error = '';
$debug = '';

#*** common variables arrays and hashes
#filled  getweek()
our @dayname;    #0=Adv|Nat|Epi|Quadp|Quad|Pass|Pent 1=winner|2=commemoratio/scriptura

#filled by getrank()
our $winner;          #the folder/filename for the winner of precedence
our $commemoratio;    #the folder/filename for the commemorated
our $scriptura;       #the folder/filename for the scripture reading (if winner is sancti)
our $commune;         #the folder/filename for the used commune
our $communetype;     #ex|vide
our $rank;            #the rank of the winner
our $vespera;         #1 | 3 index for ant, versum, oratio

#filled by precedence()
our %winner;                                  #the hash of the winner
our %commemoratio;                            #the hash of the commemorated
our %scriptura;                               #the hash for the scriptura
our %commune;                                 # the hash of the commune
our (%winner2, %commemoratio2, %commune2);    #same for 2nd column
our $rule;                                    # $winner{Rank}
our $communerule;                             # $commune{Rank}
our $duplex;                                  #1= simplex 2=semiduplex, 3=duplex 0=rest
                                              #4 = duplex majus, 5=duplex II class 6=duplex I class 7=higher
our $sanctiname = 'Sancti';
our $temporaname = 'Tempora';
our $communename = 'Commune';

require "$Bin/do_io.pl";
require "$Bin/horascommon.pl";
require "$Bin/dialogcommon.pl";
require "$Bin/webdia.pl";

if (-e "$Bin/monastic.pl") { require "$Bin/monastic.pl"; }
binmode(STDOUT, ':encoding(utf-8)');
$q = new CGI;

#*** get parameters
getini('horas');    #files, colors
$setupsave = strictparam('setup');
$setupsave =~ s/\~24/\"/g;
$date1 = strictparam('date1');
$browsertime = strictparam('browsertime');

#internal script, cookies
%dialog = %{setupstring($datafolder, '', 'horas.dialog')};

if (!$setupsave) {
  %setup = %{setupstring($datafolder, '', 'horas.setup')};
} else {
  %setup = split(';;;', $setupsave);
}
$officium = strictparam('officium');

if (!$setupsave && !getcookies('horasp', 'parameters')) {
  setcookies('horasp', 'parameters');
}
$ckname = ($officium =~ /officium/) ? 'horasgo' : ($Ck) ? 'horasgc' : 'horasg';
$csname = ($Ck) ? 'generalc' : 'general';

if (!$setupsave && !getcookies($ckname, $csname)) {
  setcookies($ckname, $csname);
}
$setup{'parameters'} = clean_setupsave($setup{'parameters'});
eval($setup{'parameters'});
eval($setup{"$csname"});

#*** saves parameters
$setupsave = printhash(\%setup, 1);
$setupsave =~ s/\r*\n*//g;
$setupsave =~ s/\"/\~24/g;
$hora = '';
precedence();    #for today
$odate = $date1;
$command = strictparam('command');

if ($command =~ /(Ante|Matutinum|Laudes|Prima|Tertia|Sexta|Nona|Vespera|Completorium|Past)/i) {
  $command = "pray$1";
}
$version1 = strictparam('version1');
$version2 = strictparam('version2');
if (!$version1) { $version1 = 'Divino Afflatu'; }
if (!$version2) { $version2 = 'Reduced 1955'; }
$testmode = strictparam('testmode');
$kmonth = strictparam('kmonth');
$kyear = strictparam('kyear');
if (!$kmonth) { $kmonth = $month; }
if (!$kyear) { $kyear = $year; }
@origyear = split('-', gettoday());
@monthnames = (
  'Januarius', 'Februarius', 'Martius', 'Aprilis', 'Majus', 'Junius',
  'Julius', 'Augustus', 'September', 'October', 'November', 'December',
);
@monthlength = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
$title = "Ordo: $monthnames[$kmonth-1] $kyear";
#***@daynames = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fry', 'Sat');
@daynames = ('Ndz', 'Pon', 'Wt', 'Śr', 'Czw',  'Pt', 'Sob');

#*** generate HTML
htmlHead($title, 2);
print <<"PrintTag";
<BODY VLINK=$visitedlink LINK=$link BACKGROUND="$htmlurl/horasbg.jpg" >
<FORM ACTION="Ckalendar.pl" METHOD=post TARGET=_self>
<INPUT TYPE=HIDDEN NAME=setup VALUE="$setupsave">
<INPUT TYPE=HIDDEN NAME=date1 VALUE="$date1">
<INPUT TYPE=HIDDEN NAME=kmonth VALUE=$kmonth>
<INPUT TYPE=HIDDEN NAME=kyear VALUE=$kyear>
<INPUT TYPE=HIDDEN NAME=date VALUE="$odate">
<INPUT TYPE=HIDDEN NAME=command VALUE="$command">
<INPUT TYPE=HIDDEN NAME=officium VALUE="$officium">
<INPUT TYPE=HIDDEN NAME=testmode VALUE="$testmode">
<INPUT TYPE=HIDDEN NAME=browsertime VALUE="$browsertime">

<P ALIGN=CENTER>
PrintTag

for ($i = $kyear - 9; $i <= $kyear; $i++) {
  $yn = sprintf("%04i", $i);
  print "<A HREF=# onclick=\"setky($yn)\">$yn</A>&nbsp;&nbsp;&nbsp;\n";
}
print "<A HREF=# onclick=\"callbrevi();\"><FONT COLOR=maroon>Hodie</FONT></A>&nbsp;&nbsp;&nbsp;\n";

for ($i = $kyear + 1; $i <= $kyear + 10; $i++) {
  $yn = sprintf("%04i", $i);
  print "<A HREF=# onclick=\"setky($yn)\">$yn</A>&nbsp;&nbsp;&nbsp;\n";
}
print "<BR><BR></FONT>\n";
print "$version1 / $version2 : <FONT COLOR=MAROON SIZE=+1><B><I>$title</I></B></FONT>\n";
print "<BR><BR>\n";

for ($i = 1; $i <= 12; $i++) {
  $mn = substr($monthnames[$i - 1], 0, 3);
  print "<A HREF=# onclick=\"setkm($i)\">$mn</A>\n";
  if ($i < 12) { print "&nbsp;&nbsp;&nbsp;\n" }
}
print <<"PrintTag";
<P ALIGN=CENTER>
<TABLE BORDER=$border WIDTH=90% CELLPADDING=3>
<TR><TH>Dies</TH><TH>de Tempore</TH><TH>Sanctorum</TH><TH>d.h.</TH><TR>
PrintTag
$to = $monthlength[$kmonth - 1];
if ($kmonth == 2 && leapyear($kyear)) { $to++; }

for ($cday = 1; $cday <= $to; $cday++) {
  $date1 = sprintf("%02i-%02i-%04i", $kmonth, $cday, $kyear);
  $d1 = sprintf("%02i", $cday);
  $version = $version1;
  $winner = $commemoratio = $scriptura = '';
  %winner = %commemoratio = %scriptura = {};
  setmdir($version);
  precedence($date1);    #for the daily item
  @c1 = split(';;', $winner{Rank});
  @c2 =
    (exists($commemoratio{Rank})) ? split(';;', $commemoratio{Rank})
    : (
      exists($scriptura{Rank})
      && ($c1[3] !~ /ex C[0-9]+[a-z]*/i
        || ($version =~ /trident/i && $c1[2] !~ /vide C[0-9]/i))
    ) ? split(';;', "Scriptura: $scriptura{Rank}")
    : (exists($scriptura{Rank})) ? split(';;', "Tempora: $scriptura{Rank}")
    : splice(@c2, @c2);
  $smallgray = "1 maroon";
  $c1 = $c2 = '';

  if (@c1) {
    my @cf = undef;
    @cf = split('~', setheadline($c1[0], $c1[2]));
    $c1 =
      ($c1[3] =~ /(C1[0-9])/) ? setfont(' blue', $cf[0])
      : (($c1[2] > 4 || ($c1[0] =~ /Dominica/i))
        && $c1[1] !~ /feria/i) ? setfont($redfont, $cf[0])
      : setfont($blackfont, $cf[0]);
    $c1 = "<B>$c1</B>" . setfont($smallgray, "&nbsp;&nbsp;$cf[1]");
  }

  if (@c2) {
    my @cf = undef;
    @cf = split('~', setheadline($c2[0], $c2[2]));
    $c2 =
        ($c2[3] =~ /(C1[0-9])/) ? setfont(' blue', $cf[0])
      : ($c2[2] > 4) ? setfont($redfont, $cf[0])
      : setfont($blackfont, $cf[0]);
    $c2 = "<I>$c2</I>" . setfont($smallgray, "&nbsp;&nbsp;$cf[1]");
  }
  if ($winner =~ /sancti/i) { ($c2, $c1) = ($c1, $c2); }
  if ($dirge) { $c1 .= setfont($smallblack, ' dirge'); }

  if ($version !~ /1955|1960/ && $winner{Rule} =~ /\;mtv/i) {
    $c2 .= setfont($smallblack, ' m.t.v.');
  }
  $version = $version2;
  $winner = $commemoratio = $scriptura = '';
  %winner = %commemoratio = %scriptura = {};
  setmdir($version);
  precedence($date1);    #for the daily item
  @c1 = split(';;', $winner{Rank});
  @c2 =
    (exists($commemoratio{Rank})) ? split(';;', $commemoratio{Rank})
    : (
      exists($scriptura{Rank})
      && ($c1[3] !~ /ex C[0-9]+[a-z]*/i
        || ($version =~ /trident/i && $c1[2] !~ /vide C[0-9]/i))
    ) ? split(';;', "Scriptura: $scriptura{Rank}")
    : (exists($scriptura{Rank})) ? split(';;', "Tempora: $scriptura{Rank}")
    : splice(@c2, @c2);
  $smallgray = "1 maroon";
  if (!$c2 && $dayname[2]) { $c2 = setfont($smallblack, $dayname[2]); }
  if (!$c1) { $c1 = "_"; }
  if (!$c2) { $c2 = "_"; }
  $c11 = $c12 = '';

  if (@c1) {
    my @cf = undef;
    @cf = split('~', setheadline($c1[0], $c1[2]));
    $c11 =
      ($c1[3] =~ /(C1[0-9])/) ? setfont(' blue', $cf[0])
      : (($c1[2] > 4 || ($c1[0] =~ /Dominica/i))
        && $c1[1] !~ /feria/i) ? setfont($redfont, $cf[0])
      : setfont($blackfont, $cf[0]);
    $c11 = "<B>$c11</B>" . setfont($smallgray, "&nbsp;&nbsp;$cf[1]");
  }

  if (@c2) {
    my @cf = undef;
    @cf = split('~', setheadline($c2[0], $c2[2]));
    $c12 =
        ($c2[3] =~ /(C1[0-9])/) ? setfont(' blue', $cf[0])
      : ($c2[2] > 4) ? setfont($redfont, $cf[0])
      : setfont($blackfont, $cf[0]);
    $c12 = "<I>$c12</I>" . setfont($smallgray, "&nbsp;&nbsp;$cf[1]");
  }
  if ($winner =~ /sancti/i) { ($c12, $c11) = ($c11, $c12); }
  if (!$c12 && $dayname[2]) { $c12 = setfont($smallblack, $dayname[2]); }
  if ($dirge) { $c11 .= setfont($smallblack, ' dirge'); }

  if ($version !~ /1955|1960/ && $winner{Rule} =~ /\;mtv/i) {
    $c12 .= setfont($smallblack, ' m.t.v.');
  }
  if (!$c11) { $c11 = "_"; }
  if (!$c12) { $c12 = "_"; }
  $c1 .= "<BR>$c11";

  if ($c2 !~ /\<\/P\>/i) {
    $c2 .= "<BR>$c12";
  } else {
    $c2 .= $c12;
  }
  $c1 =~ s/Hebdomadam/Hebd/i;
  $c1 =~ s/Quadragesima/Quadr/i;
  $c1 =~ s/_\<BR\>_/_/;
  $c2 =~ s/_\<BR\>_/<P ALIGN=CENTER>_<\/P>/;
  print <<"PrintTag";
<TR><TD ALIGN=CENTER><A HREF=# onclick="callbrevi(\'$date1\');">$d1</FONT></A></TD>
<TD>$c1</TD>
<TD>$c2</TD>
<TD ALIGN=CENTER>$daynames[$dayofweek]</FONT></TD>
</TR>
PrintTag
}
print <<"PrintTag";
</TABLE><BR>
PrintTag
@versions = load_versions($datafolder);
print option_selector("Version1", "document.forms[0].submit();", $version1, @versions);
print "&nbsp;&nbsp;&nbsp;";
print option_selector("Version2", "document.forms[0].submit();", $version2, @versions);
if ($error) { print "<P ALIGN=CENTER><FONT COLOR=red>$error</FONT></P>\n"; }
if ($debug) { print "<P ALIGN=center><FONT COLOR=blue>$debug</FONT></P>\n"; }
print <<"PrintTag";
</FORM>
</BODY></HTML>
PrintTag

#*** horasjs()
# javascript functions called by htmlhead
sub horasjs {
  print <<"PrintTag";

<SCRIPT TYPE='text/JavaScript' LANGUAGE='JavaScript1.2'>

function callbrevi(date) {
  if (!date) date = '';
  var officium = "$officium";
  if (!officium || !officium.match('.pl')) officium = "officium.pl";
  document.forms[0].date.value = date;
  document.forms[0].action = officium;
  document.forms[0].target = "_self"
  document.forms[0].submit();
}

function setkm(km) {
  document.forms[0].kmonth.value = km;
  document.forms[0].submit();
}

function setky(ky) {
  document.forms[0].kyear.value = ky;
  document.forms[0].submit();
}

</SCRIPT>
PrintTag
}
