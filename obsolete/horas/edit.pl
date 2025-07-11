#!/usr/bin/perl
use utf8;

# vim: set encoding=utf-8 :

# Name : Laszlo Kiss
# Date : 02-01-2008
# Show/edit files

package horas;

#1;

#use warnings;
#use strict "refs";
#use strict "subs";
#use warnings FATAL=>qw(all);

use POSIX;
use FindBin qw($Bin);
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use File::Basename;
use LWP::Simple;
use Time::Local;

#use DateTime;
use locale;

our ($winner, %winner);
our $sanctiname = 'Sancti';
our $temporaname = 'Tempora';
our $communename = 'Commune';

our $error = '';

$debug = '';

require "$Bin/do_io.pl";
require "$Bin/webdia.pl";
require "$Bin/horascommon.pl";
require "$Bin/dialogcommon.pl";
require "$Bin/horas.pl";
require "$Bin/check.pl";

if (-e "$Bin/monastic.pl") { require "$Bin/monastic.pl"; }
require "$Bin/tfertable.pl";

binmode(STDOUT, ':encoding(utf-8)');

$q = new CGI;

#*** collect parameters
getini('horas');    #files, colors

$skeleton = strictparam('skeleton');
$expand1 = strictparam('expand1');
if (!$expand1) { $expand1 = 0; }
$edit1 = strictparam('edit1');
if ($edit1) { $skeleton = 0; }
$pind1 = strictparam('pind1');
$adjust = strictparam('adjust');
$masschange = strictparam('masschange');
$coupled = strictparam('coupled');
$compare = strictparam('compare');
$csearch = strictparam('csearch');
$skey = strictparam('skey');
$sstring = strictparam('sstring');
if ($sstring) { $sstring = putaccents($sstring); }
if ($csearch) { $skeleton = 0; }
$searchtext = strictparam('searchtext');
our $version = strictparam('version');
if (!$version) { $version = 'Divino Afflatu'; }
setmdir($version);

$setupsave = strictparam('setup');
$setupsave =~ s/\~24/\"/g;
%dialog = %{setupstring($datafolder, '', 'horas.dialog')};

if (!$setupsave) {
  %setup = %{setupstring($datafolder, '', 'horas.setup')};
} else {
  %setup = split(';;;', $setupsave);
}

eval($setup{'parameters'});
eval($setup{'general'});

$date = strictparam('date');
precedence($date);

$lang1 = strictparam('lang1');    #the first column
if (!$lang1 || $lang1 !~ /(latin|english|magyar)/i) { $lang1 = 'Latin'; }
$folder1 = strictparam('folder1');

if (!$folder1) {
  $folder1 = ($winner =~ /tempora/i) ? 'Tempora' : 'Sancti';
  if ($winner =~ /M\//i) { $folder1 .= 'M'; }
}

$prefix1 = strictparam('prefix1');
$filename1 = strictparam('filename1');

if (!$filename1) {
  $filename1 =
      ($folder1 =~ /Tempora/i) ? "$dayname[0]-$dayofweek"
    : ($folder1 =~ /sancti/i) ? get_sday_e($month, $day, $year)
    : '';
  if ($folder1 =~ /Tempora/i && $dayofweek > 0 && $monthday) { $filename1 = $monthday; }
}

$lang2 = strictparam('lang2');    #the second column
if (!$lang2 || $lang2 !~ /(latin|english|magyar|none|search)/i) { $lang2 = 'polski'; }
if ($folder1 =~ /program/i && $lang2 !~ /search/i) { $lang2 = 'none'; }
$folder2 = strictparam('folder2');

if (!$folder2) {
  $folder2 = ($winner =~ /tempora/i) ? 'Tempora' : 'Sancti';
  if ($winner =~ /(TemporaM|SanctiM)/) { $folder2 .= 'M'; }
}
$prefix2 = strictparam('prefix2');
$filename2 = strictparam('filename2');

if (!$filename2) {
  $filename2 =
      ($folder2 =~ /Tempora/i) ? "$dayname[0]-$dayofweek"
    : ($folder2 =~ /sancti/i) ? get_sday_e($month, $day, $year)
    : '';
  if ($folder2 =~ /Tempora/i && $dayofweek > 0 && $monthday) { $filename2 = $monthday; }
}

if ($coupled) { $folder2 = $folder1; $filename2 = $filename1; $prefix2 = $prefix1; }
if ($folder1 =~ /M$/) { $version = 'pre Trident Monastic'; }

@folders1 = (
  Ordinarium, Psalterium, Tempora, Sancti, Commune, psalms,
  'psalms1', Tabulae, tones, Martyrologium, Martyrologium1, Martyrologium2,
  program, TemporaM, SanctiM, CommuneM, Regula, test,
);
@folders2 = (
  Ordinarium, Psalterium, Tempora, Sancti, Commune, psalms, 'psalms1', Tabulae,
  tones, Martyrologium, TemporaM, SanctiM, CommuneM, Regula, test,
);
if (!(-d "$datafolder/$lang1/test")) { pop(@folders1); }
if (!(-d "$datafolder/$lang2/test")) { pop(@folders2); }

@languages = splice(@laguages, @languages);
opendir(DIR, $datafolder);
@a = readdir(DIR);
close DIR;

foreach $item (@a) {
  if ($item !~ /\./ && (-d "$datafolder/$item") && $item =~ /^[A-Z]/ && $item !~ /(help|ordo)/i) {
    push(@languages, $item);
  }
}

$save = strictparam('save');
if ($folder1 =~ /program/) { $edit1 = 0; $save = 0; $adjust = 0; $masschange = 0; $coupled = 0; $compare = 0; }
if ($adjust) { $save = 1; }
if ($savesetup < 2) { $save = 0; }

#*** save after edit
if ($savesetup > 1 && $save && $folder1 !~ /program/i) {
  $newtext = '';
  $newtext .= strictparam("Lat0");

  if ($newtext) {
    $newtext =~ s/\r\r/\r/sg;
    my $f1 = ($folder1 =~ /tones/) ? $folder1 : "$lang1/$folder1";

    if ($ENV{DIVINUM_OFFICIUM_SAVE}) {
      if (do_write("$datafolder/$f1/$filename1.txt", $newtext)) {
      } else {
        $error = "$datafolder/$f1/$filename1.txt could not be saved!";
      }
    } else {
      $error = "File save is disabled.";
    }
  }
}

#*** collect files for column1
@files1 = splice(@files1, @files1);
$flag = 0;
$flag1 = 0;

if ($folder1) {
  if ($folder1 =~ /program/i) {
    $dirname1 = "$Bin";
    $ext1 = "pl";
  } elsif ($folder1 =~ /tones/i) {
    $dirname1 = "$datafolder/tones";
    $ext1 = "txt";
  } elsif ($folder1 =~ /(Tabulae|Martyrologium1)/i) {
    $dirname1 = "$datafolder/Latin/$folder1";
    $ext1 = 'txt';
  } else {
    $dirname1 = "$datafolder/$lang1/$folder1";
    $ext1 = "txt";
  }

  if (opendir(DIR, $dirname1)) {
    @item = readdir(DIR);
    closedir DIR;

    foreach $item (@item) {
      if ($item =~ /^$prefix1/i) { $flag1 = 1; }
    }
    if (!$flag1) { $prefix1 = ''; }    #wrong prefix

    foreach $item (@item) {
      if ($item =~ /.$ext1$/i && (!$prefix1 || $item =~ /^$prefix1/i)) {
        $item =~ s/\.$ext1$//;
        if ($item =~ /^$filename1$/) { $flag = 1; }
        push(@files1, $item);
      }
    }
  }

  @files1 = sort(@files1);

  if (!$flag) {
    $filename = '';
    if ($folder1 =~ /Tempora/i) { $filename1 = "$dayname[0]-$dayofweek"; }
    if ($folder1 =~ /Sancti/i) { $filename1 = get_sday_e($month, $day, $year); }
    if ($folder1 =~ /Tempora/i && $dayofweek > 0 && $monthday) { $filename1 = $monthday; }
    if ($folder1 =~ /martyr/i) { $filename1 = nextday($month, $day, $year); }

    if ($folder1 =~ /commune/i) {
      if ($winner{Rank} =~ /C[0-9]+/) {
        $filename1 = $&;
      } elsif ($commemoratio{Rank} =~ /C[0-9]+/) {
        $filename1 = $&;
      }
    }
    if (!$filename1 || !-e "$dirname1/$filename1.$ext1") { $filename1 = $files1[0]; }
  }
}

#*** collect files for column2
if ($lang2 !~ /(none|serach)/i) {
  @files2 = ();
  $flag = 0;
  $flag1 = 0;

  if ($folder2 =~ /tones/i) {
    $dirname2 = "$datafolder/tones";
    $ext2 = "txt";
  } elsif ($folder2 =~ /(Tabulae|Martyrologium1)/i) {
    $dirname2 = "$datafolder/Latin/$folder2";
    $ext2 = 'txt';
  } else {
    $dirname2 = "$datafolder/$lang2/$folder2";
    $ext2 = "txt";
  }

  if ($folder2 && opendir(DIR, "$dirname2")) {
    @item = readdir(DIR);
    closedir DIR;

    foreach $item (@item) {
      if ($item =~ /^$prefix2/i) { $flag1 = 1; }
    }
    if (!$flag1) { $prefix2 = ''; }

    foreach $item (@item) {
      if ($item =~ /.txt$/i && (!$prefix2 || $item =~ /^$prefix2/i)) {
        $item =~ s/\.txt$//;
        if ($item =~ /^$filename2$/) { $flag = 1; }
        push(@files2, $item);
      }
    }
    @files2 = sort(@files2);

    if (!$flag) {
      $filename = '';
      if ($folder2 =~ /Tempora/i) { $filename2 = "$dayname[0]-$dayofweek"; }
      if ($folder2 =~ /Sancti/i) { $filename2 = get_sday_e($month, $day, $year); }
      if ($folder2 =~ /Tempora/i && $dayofweek > 0 && $monthday) { $filename2 = $monthday; }
      if ($folder2 =~ /martyr/i) { $filename2 = nextday($month, $day, $year); }

      if ($folder2 =~ /commune/i) {
        if ($winner{Rank} =~ /C[0-9]+/) {
          $filename2 = $&;
        } elsif ($commemoratio{Rank} =~ /C[0-9]+/) {
          $filename2 = $&;
        }
      }
      if (!$filename2 || !-e "$datafolder/$lang2/$folder2/$filename2.txt") { $filename2 = $files2[0]; }
    }
  }
}

$txlat = $txvern = '';

#*** load files to show/edit
$title = ($savesetup > 1 && $folder1 !~ /program/i) ? 'Edit' : 'Show';
$title .= " files";
if ($skeleton) { $title = 'Skeleton'; }

@txlat = ();
@txvern = ();

(@txlat = do_read("$dirname1/$filename1.$ext1"))
  or ($folder1 =~ /program/ && (@txlat = do_read("$Bin/$filename1.$ext1")))
  or ($error .= "$dirname1/$filename1.$ext1 or $Bin/$filename1 cannot open");

if ($lang2 !~ /(none|search)/i) {
  if (@txvern = do_read("$dirname2/$filename2.txt")) {
  } else {
    $error .= "$dirname2/$filename2.txt cannot open";
  }
} elsif ($lang2 =~ /search/i) {
  if (!$searchtext) { $searchtext = searchrut($sstring, $skey); }
  $txvern = searchnext($searchtext);
}

$setupsave = printhash(\%setup, 1);
$setupsave =~ s/\r*\n*//g;
$setupsave =~ s/\"/\~24/g;

#*** format files typografically
if ($adjust) {
  if ($edit1) { @txlat = adjust(\@txlat, $folder1, $lang1); }
}

#*** generate HTML head widgets
htmlHead($title, 2);
print <<"PrintTag";
<BODY VLINK=$visitedlink LINK=$link BACKGROUND=\"$htmlurl/horasbg.jpg\"> 
<FORM ACTION="edit.pl" METHOD=post TARGET=_self>
<TABLE ALIGN=CENTER BORDER=1 CELLPADDING=8><TR>
<TD ALIGN=CENTER><FONT SIZE=1>lang1<BR></FONT>
<SELECT SIZE=5 NAME=lang1 onchange=\"submit1();\">
PrintTag

foreach $item (@languages) {
  $selected = ($item =~ /^$lang1$/i) ? "SELECTED" : "";
  print "<OPTION $selected VALUE=\"$item\">$item\n";
}
print "</SELECT></TD>\n";

print "<TD ALIGN=CENTER><FONT SIZE=1>folder1<BR></FONT>" . "<SELECT SIZE=5 NAME=folder1 onchange=\"submit1()\">\n";

@folders = @folders1;

foreach $item (@folders) {
  $selected = ($item =~ /^$folder1$/i) ? "SELECTED" : "";
  print "<OPTION $selected VALUE=\"$item\">$item\n";
}
print "</SELECT></TD>\n";

print "<TD ALIGN=CENTER><FONT SIZE=1>prefix1<BR></FONT>"
  . "<INPUT TYPE=TEXT NAME=prefix1 SIZE=5 VALUE=\"$prefix1\" onchange=\"submit1();\"></TD>\n";

print "<TD ALIGN=CENTER><FONT SIZE=1>file1<BR></FONT>" . "<SELECT SIZE=5 NAME=filename1 onchange=\"submit1();\">";

foreach $item (@files1) {
  $selected = ($item =~ /^$filename1$/i) ? "SELECTED" : "";
  print "<OPTION $selected VALUE=\"$item\">$item\n";
}
print "</SELECT></TD><TD> </TD>\n";

print "<TD ALIGN=CENTER><FONT SIZE=1>lang2<BR></FONT>";
print "<SELECT SIZE=5 NAME=lang2 onchange=\"submit1();\">";
$selected = ($lang2 =~ /^none$/i) ? "SELECTED" : "";
print "<OPTION $selected VALUE=none>none\n";
$selected = ($lang2 =~ /^search$/i) ? "SELECTED" : "";
print "<OPTION $selected VALUE=search>search\n";

foreach $item (@languages) {
  $selected = ($item =~ /^$lang2$/i) ? "SELECTED" : "";
  print "<OPTION $selected VALUE=\"$item\">$item\n";
}
print "</SELECT></TD>\n";

if ($lang2 =~ /search/i) {
  print "<TD ALIGN=CENTER><FONT SIZE=1>key<BR></FONT>" . "<INPUT TYPE=TEXT NAME=skey SIZE=5 VALUE=$skey></TD>\n";
  print "<TD ALIGN=CENTER><FONT SIZE=1>search for<BR></FONT>"
    . "<INPUT TYPE=TEXT NAME=sstring SIZE=16 VALUE=\"$sstring\"></TD>\n";
} elsif ($lang2 !~ /(none|search)/i) {
  print "<TD ALIGN=CENTER><FONT SIZE=1>folder2<BR></FONT>" . "<SELECT SIZE=5 NAME=folder2 onchange=\"submit1()\">\n";
  @folders = @folders2;

  foreach $item (@folders) {
    $selected = ($item =~ /^$folder2$/i) ? "SELECTED" : "";
    print "<OPTION $selected VALUE=\"$item\">$item\n";
  }
  print "</SELECT></TD>\n";

  print "<TD ALIGN=CENTER><FONT SIZE=1>prefix2<BR></FONT>"
    . "<INPUT TYPE=TEXT SIZE=5 NAME=prefix2 VALUE=\"$prefix2\" onchange=\"submit1();\"></TD>";

  print "<TD ALIGN=CENTER><FONT SIZE=1>file2<BR></FONT>" . "<SELECT SIZE=5 NAME=filename2 onchange=\"submit1();\">";

  foreach $item (@files2) {
    $selected = ($item =~ /^$filename2$/i) ? "SELECTED" : "";
    print "<OPTION $selected VALUE=\"$item\">$item\n";
  }
  print "</SELECT></TD>\n";
}
print "</TR></TABLE>\n";

print "<P ALIGN=CENTER>\n";

if (!$edit1) {
  $checked = ($skeleton) ? 'CHECKED' : "";
  print "Skeleton:<INPUT TYPE=checkbox NAME=skeleton onclick='submit1()' $checked>";
}

if ($folder1 !~ /program/i) {
  if ($lang2 !~ /(none|search)/i) {
    $checked = ($coupled) ? 'CHECKED' : '';
    print "&nbsp;&nbsp;&nbsp;\n";
    print "Coupled:<INPUT TYPE=checkbox NAME='coupled' onclick='submit1()' $checked>\n";
    $checked = ($compare) ? 'CHECKED' : '';
    print "&nbsp;&nbsp;&nbsp;\n";
    print "Compare:<INPUT TYPE=checkbox NAME='compare' onclick='submit1()' $checked>\n";
  }
  $checked = ($edit1) ? 'CHECKED' : '';
  print "&nbsp;&nbsp;&nbsp;\n";
  my $ename = ($savesetup < 2) ? 'Scrolled' : 'Edit';
  print "$ename:<INPUT TYPE=checkbox NAME=edit1 onclick='submit1()' $checked>";
}

if ($savesetup > 1 && ($edit1) && $folder1 !~ /program/i) {
  print "&nbsp;&nbsp;&nbsp;&nbsp;<A HREF=# onclick='savetext();'>Save</A>\n";
}
print "&nbsp;&nbsp;&nbsp;\n";
print "<A HREF=# onclick='window.close()'>Close</A>\n";

if ($lang2 !~ /(none|search)/i && $folder1 !~ /program/i) {
  print "&nbsp;&nbsp;&nbsp;&nbsp;";
  print "<A HREF=# onclick='switchrut();'>Switch</A>\n";
}

if ($savesetup > 1 && $edit1) {
  print "&nbsp;&nbsp;&nbsp;&nbsp;";
  print "<A HREF=# onclick='adjust();'>Adjust</A>\n";
  print "&nbsp;&nbsp;&nbsp;&nbsp;";
  print "<A HREF=# onclick='masschange();'>Mass change</A>\n";
}

if ($lang2 =~ /search/i) {
  print "&nbsp;&nbsp;&nbsp;&nbsp;";
  print "<A HREF=# onclick='searchrut();'>Search</A>\n";
}

print "$checkerr\n";
print "<TABLE ALIGN=CENTER BORDER=2 CELLPADDING=8 WIDTH=95%>\n";

$cols = ($txvern || @txvern) ? 40 : 85;
$width = ($txvern || @txvern) ? 'WIDTH=50%' : '';

#*** regular printout
if (!$skeleton) {
  $row1 = 25;    #@txlat;

  #prepare program for printout
  if ($folder1 =~ /program/i && !$edit1) {
    for ($i = 0; $i < @txlat; $i++) {
      $txlat[$i] =~ s/\</\&lt\;/sg;
      $txlat[$i] =~ s/\>/\&gt\;/sg;
      $txlat[$i] =~ s/\&nbsp\;/\&npsp\;/g;
      $txlat[$i] =~ s/ /\&nbsp\;/g;
    }
  }

  $ln = ($edit1) ? "" : "<BR>";

  foreach $item (@txlat) {
    $txlat .= "$item\n$ln";
  }

  $ln = ($edit1) ? "" : "<BR>";

  if (@txvern) {
    foreach $item (@txvern) {
      $txvern .= "$item\n$ln";
    }
  }
  $pind1 = 1;
  my $disabled = ($savesetup < 2) ? "BACKGROUND-COLOR:#eeeeee;" : '';
  my $readonly = ($savesetup < 2) ? "READONLY" : '';
  print "<TR><TD $background VALIGN=TOP $width>";

  if (!$edit1) {
    print $txlat;
  } else {
    $txlat =~ s/TEXTAREA/TEXT\_AREA/g;
    print "<P ALIGN=CENTER>";
    print "<TEXTAREA ROWS=$row1 $readonly COLS=\"$cols\" NAME=\"Lat0\" WRAP=virtual $width"
      . " STYLE={FONT-SIZE:120%;$disabled} onclick='changed1=1'>\n";
    print "$txlat";
    print "</TEXTAREA></P>\n";
  }
  print "</TD>";

  if ($txvern) {
    print "<TD background VALIGN=TOP>";

    if (!$edit1 || $searchtext || $txvern =~ /enter search string/i) {
      print $txvern;
    } else {
      print "<TEXTAREA READONLY ROWS=$row1 COLS=$cols NAME=Vern0 WRAP=virtual"
        . " STYLE={FONT-SIZE:120%;BACKGROUND-COLOR:#eeeeee;}>\n";
      print "$txvern";
      print "</TEXTAREA></P>\n";
    }
    print "</TD></TR>\n";
  }

}

#*** skeleton printout
elsif ($folder1 !~ /program/i) {
  $ind1 = $ind2 = $pind1 = 0;
  my $skfont = ($compare) ? $blackfont : $redfont;

  while ($ind1 < @txlat || $ind2 < @txvern) {
    ($text1, $ind1) = getunit(\@txlat, $ind1);
    ($text2, $ind2) = getunit(\@txvern, $ind2);

    if ($compare) {
      $text1 =~ s/\n[0-9: ]+/\n/;
      $text1 =~ s/\n[0-9: ]+/ /g;
      $text2 =~ s/\n[0-9: ]+/\n/;
      $text2 =~ s/\n[0-9: ]+/ /g;
      $text1 =~ s/ +/ /g;
      $text2 =~ s/ +/ /g;
    }

    @text1 = split("\n", $text1);
    @text2 = split("\n", $text2);

    print "<TR><TD $background $width VALIGN=TOP>" . setfont($skfont, $text1[0]);

    if ($text1[0]) {
      print "&nbsp;&nbsp:<INPUT TYPE=RADIO NAME=expind1 VALUE=expand onclick=\"expand(1,$ind1)\">";
    }

    if ($compare) {
      lcompare($text1, $text2);

      if ($ind1 == $expand1) {
        for ($i = 1; $i < @text1; $i++) { print "<BR>" . tcompare($text1[$i], $text2[$i]); }
      }
    } elsif ($ind1 == $expand1) {
      for ($i = 1; $i < @text1; $i++) { print "<BR>$text1[$i]"; }
    }
    print "</TD>\n";

    if (@txvern) {
      print "<TD $background $width VALIGN=TOP>" . setfont($skfont, $text2[0]);

      if ($compare) {
        lcompare($text2, $text1);

        if ($ind1 == $expand1) {
          for ($i = 1; $i < @text2; $i++) { print "<BR>" . tcompare($text2[$i], $text1[$i]); }
        }
      } elsif ($ind1 == $expand1) {
        for ($i = 1; $i < @text2; $i++) { print "<BR>$text2[$i]"; }
      }

      print "</TD></TR>\n";
    }
  }

}

#*** program skeleton
else {
  $ind1 = $pind1 = 0;

  while ($ind1 < @txlat) {
    ($text1, $ind1) = getunit1(\@txlat, $ind1);

    @text1 = split("\n", $text1);
    print "<TR><TD $background>" . setfont($redfont, $text1[0]);

    if ($text1[0]) {
      print "&nbsp;&nbsp:<INPUT TYPE=RADIO NAME=expind1 VALUE=expand onclick=\"expand(1,$ind1)\">";
    }

    if ($ind1 == $expand1) {
      for ($i = 1; $i < @text1; $i++) { print "<BR>$text1[$i]"; }
    }
    print "</TD>\n";
  }
  print "</TR>";
}
print "</TABLE><BR>\n";

#*** end of HTML file
if ($error) { print "<P ALIGN=CENTER><FONT COLOR=red>$error</FONT></P>\n"; }
if ($debug) { print "<P ALIGN=center><FONT COLOR=blue>$debug</FONT></P>\n"; }

print <<"PrintTag";
<INPUT TYPE=HIDDEN NAME=save VALUE='0'>
<INPUT TYPE=HIDDEN NAME=setup VALUE="$setupsave">
<INPUT TYPE=HIDDEN NAME=expand1 VALUE="$expand1">
<INPUT TYPE=HIDDEN NAME=pind1 VALUE="$pind1">
<INPUT TYPE=HIDDEN NAME=masschange VALUE=0>
<INPUT TYPE=HIDDEN NAME=adjust VALUE=0>
<INPUT TYPE=HIDDEN NAME=csearch VALUE="">
<INPUT TYPE=HIDDEN NAME=date VALUE="$date">
<INPUT TYPE=HIDDEN NAME=searchtext VALUE="$searchtext">
<INPUT TYPE=HIDDEN NAME=version VALUE="$version">
</FORM>
</BODY></HTML>
PrintTag

#*** javascript functions
sub horasjs {
  print <<"PrintTag";

<SCRIPT TYPE='text/JavaScript' LANGUAGE='JavaScript1.2'>

var changed1 = 0;
var savesetup = (!"$savesetup") ? 0 : "$savesetup";

function submit1() {  
  if (savesetup  < 2 || !changed1) {document.forms[0].submit(); return;}
  if (confirm('Save edited text?')) {savetext(); return;}
  document.forms[0].submit();
}

function savetext() { 
  document.forms[0].lang1.value="$lang1";
  document.forms[0].folder1.value="$folder1";
  document.forms[0].filename1.value="$filename1";
  
  document.forms[0].save.value = '1';  
  document.forms[0].submit();
}

function adjust() {  
  document.forms[0].adjust.value = '1';
  document.forms[0].submit();
}

function masschange() {
  document.forms[0].masschange.value = '1';
  adjust();
}

function searchrut() {	 
  document.forms[0].searchtext.value = '';
  document.forms[0].csearch.value = '1';
  submit1();
}

function searchnext(lang, folder, file, prefix) {
  document.forms[0].lang1.value = lang;
  document.forms[0].folder1.value = folder;
  document.forms[0].filename1.value = file;
  document.forms[0].prefix1.value = prefix;
  submit1();
}

function expand(i, ind) { 
  if (i == 1 && "$expand1" && ind == "$expand1") {ind = 0;}

  document.forms[0].expand1.value = ind;
  document.forms[0].submit();
}

function switchrut() { 
  var a = document.forms[0].lang1.value;
  document.forms[0].lang1.value = document.forms[0].lang2.value;
  document.forms[0].lang2.value = a;

  a = document.forms[0].folder1.value;
  document.forms[0].folder1.value = document.forms[0].folder2.value;
  document.forms[0].folder2.value = a;

  a = document.forms[0].prefix1.value;
  document.forms[0].prefix1.value = document.forms[0].prefix2.value;
  document.forms[0].prefix2.value = a;

  a = document.forms[0].filename1.value;
  document.forms[0].filename1.value = document.forms[0].filename2.value;
  document.forms[0].filename2.value = a;
 
  submit1();
}    


</SCRIPT>
PrintTag
}

#*** adjust($text, $folder, $lang) adjust raw files sub
sub adjust {
  my $t = shift;
  my @t = @$t;
  my $folder = shift;
  my $lang = shift;

  if ($lang =~ /magyar/i && $folder =~ /(ordinarium|psalterium|psalms)/i & $masschange) { return accents($t); }

  #contract hyphenation
  my $j = 0;
  my @o = splice(@o, @o);

  for ($i = 0; $i < @t; $i++) {
    $t[$i] =~ s/~//;

    if ($t[$i] =~ /\-\s*$/) {
      $o[$j] .= "$`";
    } else {
      $o[$j] .= $t[$i];
      $j++;
    }
  }

  if ($folder =~ /martyr/i && $lang =~ /english/i) {
    $j = 0;
    @t = splice(@t, @t);

    for ($i = 0; $i < @o; $i++) {
      if ($o[$i] !~ /\.\]*\s*$/) {
        $t[$j] .= chompd($o[$i]) . ' ';
      } else {
        $t[$j] .= $o[$i];
        $t[$j] =~ s/  / /g;
        $j++;
      }
    }
    return (@t);
  } elsif ($folder =~ /martyr/i) {
    return @o;
  }

  #mark with ~ to be contracted
  my $mode = '';

  for ($i = 0; $i < @o; $i++) {
    my $flag = 0;

    #hash keys
    if ($o[$i] =~ /\[([a-z 0-9]+?)\]/i) {
      $block = $1;

      if ($block =~ /(Capitulum|Ant\s+[1-4]|Ant\s+(Prima|Tertia|Sexta|Nona)|Lectio|Responsory|Oratio|Versum)/i) {
        $mode = $1;
      } else {
        $mode = '';
      }
      $flag = 1;
    }

    #Ant [a-z] skipped

    if ($block =~ /Ant\s*[a-z]+/i && $block !~ /Ant\s+(Prima|Tertia|Sexta|Nona)/) {
      if ($i > 0) { $o[$i - 1] =~ s/~//; }
      next;
    }

    #special markers
    if ($o[$i] =~ /^\s*[\!]Hymnus/i) { $mode = ''; $flag = 1; }
    if ($o[$i] =~ /^\s*[RrV]\./) { $mode = 'Versum'; $flag = 2; }
    if ($mode =~ /versum/i && $o[$i] =~ /^\s*\*/) { $flag = 2; }

    if ($o[$i] =~ /^\s*[\$\&\@]/) { $mode = ''; $flag = 1; }

    if ($o[$i] =~ /^\s*[!_]/) {
      $flag = 1;
    }
    if ($o[$i] =~ /^\s*([0-9:]+ |v\.)/ && $mode =~ /lectio/i) { $flag = 2; }

    #empty or short line
    if (!$o[$i] || $o[$i] =~ /^\s*$/ || length($o[$i]) < 4) { $flag = 1; }

    if ($flag) {
      if ($i > 0) { $o[$i - 1] =~ s/~//; }
      if ($flag == 1) { next; }
    }
    if (!$mode) { next; }

    #set tilde
    $o[$i] =~ s/\s*$//;
    $o[$i] .= "~\n";
    next;
  }

  #make long lines
  @t = splice(@t, @t);
  $o[0] =~ s/^\s*//;
  $j = 0;

  for ($i = 0; $i < @o; $i++) {
    if (!$t[$j] || $t[$j] =~ /~\n/) {
      $t[$j] =~ s/[~\n]//;
      $t[$j] =~ s/\s*$//;

      if ($j == 0) {
        $t[$j] = $o[$i];
      } else {
        $t[$j] .= " $o[$i]";
      }
    } else {
      $j++;
      $t[$j] = $o[$i];
    }
  }

  if ($masschange && $folder !~ /Martyr/i) {
    for ($i = 0; $i < @t; $i++) {
      if ($lang =~ /latin/i) {
        if ($t[$i] !~ /(vide|ex)\s+C[0-9][a-z]/) {
          $t[$i] =~ s/([a-z])\-([a-z])/$1$2/ig;
          $t[$i] =~ s/([a-z ])6([a-z])/$1o$2/ig;
          $t[$i] =~ s/([a-z])1([a-z])/$1l$2/ig;
          $t[$i] =~ s/([a-z])\)*3([a-z])/$io$2/ig;
          $t[$i] =~ s/([a-z])[0-9]([a-z])/$1$2/ig;
        }
        $t[$i] =~ s/([a-z])\^([a-z])/$1e$2/ig;
        $t[$i] =~ s/([a-z])H([a-z])/$1li$2/g;
        $t[$i] =~ s/([a-z])iii([a-z])/$1iu$2/ig;
        $t[$i] =~ s/([a-oq-z])ii([a-z][a-z])/$1u$2/ig;

      } elsif ($lang =~ /english/i) {
        $t[$i] =~ s/\"//g;
        $t[$i] =~ s/\[(.*?[\,\.\?\;]+.*?)\]/\($1\)/g;    #[...] to (...)
        $t[$i] =~ s/\s([\;\,\.\?\!])/$1/g;

      } elsif ($lang =~ /magyar/i) {
        @t = accents(\@t);
      }
    }
  }

  $checkerr = "";
  if ($folder =~ /(Commune|Sancti|Tempora|test)/i) { $checkerr = check(\@t); }
  $checkerr =~ s/\n/\<BR\>\n/sg;
  if ($checkerr) { $checkerr = "<BR><FONT COLOR RED>$checkerr</FONT></BR>"; }

  #wrap
  @o = splice(@o, @o);
  $limit = 10000;
  $break = "~\n";
  $mode = '';
  $t[-1] =~ s/\~//;

  foreach $str (@t) {
    if ($str =~ /\[([a-z 0-9]+?)\]/i) {
      $block = $1;

      if ($block =~ /(Capitulum|Ant\s*[1-4]|Ant\s+(Prima|Tertia|Sexta|Nona)|Lectio|Responsory|Oratio|Versum)/i) {
        $mode = $1;
      } else {
        $mode = '';
      }
    }

    if (!$mode) {
      push(@o, $str);
      next;
    }
    if (length($str) < $limit) { push(@o, $str); next; }
    my @str = split(/([\s\,\;])/, $str);
    my $count = 0;
    $str = '';

    foreach (@str) {
      if ($count + length($_) > $limit && length($_) > 1) {
        push(@o, "$str$break");
        $count = 0;
        $str = '';
      }
      $str .= $_;
      $count += length($_);
    }
    push(@o, $str);
  }

  for ($i = 0; $i < @o; $i++) {
    $o[$i] =~ s/  / /g;
    $o[$i] =~ s/ ~/~/;
    $o[$i] =~ s/ \n/\n/;
  }
  return @o;
}

sub accents {
  my $t = shift;
  my @t = @$t;

  for ($i = 0; $i < @t; $i++) {
    $t[$i] =~ s/a'/á/g;
    $t[$i] =~ s/e'/é/g;
    $t[$i] =~ s/i'/í/g;
    $t[$i] =~ s/o'/ó/g;
    $t[$i] =~ s/o:/ö/g;
    $t[$i] =~ s/o"/õ/g;
    $t[$i] =~ s/u'/ú/g;
    $t[$i] =~ s/u:/ü/g;
    $t[$i] =~ s/u"/û/g;
    $t[$i] =~ s/A'/Á/g;
    $t[$i] =~ s/E'/É/g;
    $t[$i] =~ s/O'/Ó/g;
    $t[$i] =~ s/O:/Ö/g;
    $t[$i] =~ s/O"/Ô/g;
    $t[$i] =~ s/U'/Ú/g;
    $t[$i] =~ s/U:/Ü/g;
    $t[$i] =~ s/U"/Û/g;

    $t[$i] =~ s/&#337;/õ/g;
    $t[$i] =~ s/&#369;/û/g;
  }
  return @t;
}

#*** get blocks for program files
sub getunit1 {

  my $s = shift;
  my @s = @$s;
  my $ind = shift;
  my $t = '';
  my $plen = 1;

  while ($ind < @s) {
    my $line = chompd($s[$ind]);
    $ind++;
    $t .= "$line\n";
    if ($s[$ind] =~ /^\#\*\*\*/) { last; }
  }
  return ($t, $ind);
}

sub searchrut {
  my $search = shift;
  my $skey = shift;
  my $searchtext = '';
  if (!$search) { return; }

  my $casesense = ($search =~ /[A-Z]/) ? 1 : 0;

  $searchtext = "$search found in $lang1/$folder1 files with prefix $prefix1:;;";
  my $ext = ($folder1 =~ /program/i) ? 'pl' : 'txt';

  foreach $fname (@files1) {
    my $filename =
      ($folder1 =~ /program/i)
      ? "$Bin/$fname.pl"
      : "$datafolder/$lang1/$folder1/$fname.txt";

    if (@lines = do_read($filename)) {
      $text = join('', @lines);
    } else {
      $error .= "$filename cannot open";
    }
    my $num = 0;
    $casesense = 0;

    if (!$skey) {
      while (($casesense && $text =~ /$search/g) || (!$casesense && $text =~ /$search/ig)) { $num++; }
    } else {
      $num = countskey($text, $search, $skey, $casesense);
    }
    if ($num) { $searchtext .= "$fname=$num;;"; }
  }

  return $searchtext;
}

sub countskey {

  my $text = shift;
  my $search = shift;
  my $skey = shift;
  my $casesense = shift;

  my @t = split("\n", $text);
  my $line;
  my $flag = 0;
  my $count = 0;

  foreach $line (@t) {
    if ($line =~ /^\s*\[$skey/i) {
      $flag = 1;
      next;
    } elsif ($line =~ /^\s*\[[a-z0-9\-\_ ]+\]/i) {
      $flag = 0;
      next;
    }

    if ($flag) {
      while (($casesense && $line =~ /$search/g) || (!$casesense && $line =~ /$search/ig)) { $count++; }
    }
  }
  return $count;
}

sub searchnext {
  my $searchtext = shift;
  my $tx = '';
  if (!$searchtext) { return "Enter search string and optional [key], press Search tab"; }
  my @t = split(";;", $searchtext);
  my $l1 = $lang1;
  my $f1 = $folder1;
  my $pf = $prefix1;

  if ($t[0] =~ / ([a-z]+)\/([a-z]+) /i) { $l1 = $1; $f1 = $2; }
  if ($t[0] =~ /prefix (.*?)\:$/) { $pf = $1; }

  $tx = "$t[0]<BR><BR>\n";
  my ($i, $str);

  for ($i = 1; $i < @t; $i++) {
    if (!$t[$i]) { next; }

    if ($t[$i] !~ /\=/) {
      next;
    } else {
      $name = $`;
      $str = " <FONT SIZE=1>=$'</FONT>";
    }
    $tx .= "<A HREF=# onclick=\"searchnext(\'$l1\', \'$f1\', \'$name\',\'$pf\');\">$name</A> $str<BR>\n";
  }
  return $tx;
}

#*** get_sday_e($month, $day, $year)
#get filename for saint for the given date
sub get_sday_e {
  my ($month, $day, $year) = @_;
  my $fname = get_sday($month, $day, $year);
  if ($version =~ /1570/ && (-e "$datafolder/Latin/Sancti/$fname" . "o.txt")) { return $fname . 'o'; }
  if ($version =~ /Trident/i && (-e "$datafolder/Latin/Sancti/$fname" . "t.txt")) { return $fname . 't'; }
  if ($version =~ /Newcal/i && (-e "$datafolder/Latin/Sancti/$fname" . "n.txt")) { return $fname . 'n'; }
  if ($version =~ /1960/ && (-e "$datafolder/Latin/Sancti/$fname" . "r.txt")) { return $fname . 'r'; }
  if (!(-e "$datafolder/Latin/Sancti/$fname.txt") && $winner =~ /Sancti\/(.*?)\.txt/) { $fname = $1; }
  return $fname;
}

sub lcompare {

  my $t1 = shift;
  my $t2 = shift;

  my @t1 = split("\n", $t1);
  my @t2 = split("\n", $t2);
  my ($n1, $n2, $i, $j);

  my $sum = 0;
  my $esum = 0;
  my $n = @t1;

  if ($n < @t2) { $n = @t2; }

  print " (";

  for ($i = 1; $i < $n; $i++) {
    my $l1 = $t1[$i];
    my @l1 = split(' ', $l1);
    $n1 = @l1;
    my $l2 = $t2[$i];
    my @l2 = split(' ', $l2);
    $n2 = @l2;
    my $m = $l1;
    if ($n2 > $m) { $m = $n2; }
    $flag = 0;

    for ($j = 0; $j < $m; $j++) {
      if (deaccent($l1[$j]) ne deaccent($l2[$j])) { $flag++; }
    }

    if ($n1 == $n2 && !$flag) {
      print "$n1 ";
    } else {
      print "<FONT COLOR=red>$n1</FONT> ";
    }
    $sum .= $n1;
    $esum += $flag;
  }
  print ")";
  $n1 = @t1 - 1;
  $n2 = @t2 - 1;

  if ($n1 == $n2) {
    print " $n1";
  } else {
    print "<FONT color=RED> $n1</FONT>";
  }
  if ($esum) { print " <B><FONT SIZE=+1 COLOR=RED>$esum</FONT></B>"; }
}

sub tcompare {
  my $t1 = shift;
  my $t2 = shift;
  if (!$t2 || !$t1) { return $t1; }

  my @t1 = split(' ', $t1);
  my @t2 = split(' ', $t2);
  my $n = @t1;
  if ($n < @t2) { $n = @t2; }
  my ($w1, $w2, $i);
  my $str = '';

  for ($i = 0; $i < $n; $i++) {
    $w1 = deaccent($t1[$i]);
    $w2 = deaccent($t2[$i]);

    if ($w1 eq $w2) {
      $str .= "$t1[$i] ";
    } else {
      $str .= "<FONT COLOR=RED>$t1[$i] </FONT>";
    }
  }
  return $str;
}

sub deaccent {
  my $w = shift;

  $w =~ s/[!@#$%&*()\-_=+,<.>?'";:0-9 ]//g;

  $w =~ s/á/a/g;
  $w =~ s/é/e/g;
  $w =~ s/í/i/g;
  $w =~ s/ó/o/g;
  $w =~ s/ú/u/g;
  $w =~ s/Á/A/g;
  $w =~ s/É/E/g;
  $w =~ s/Í/I/g;
  $w =~ s/Ó/O/g;
  $w =~ s/Ú/U/g;
  $w =~ s/ae/æ/g;
  $w =~ s/áe/æ/g;
  $w =~ s/oe/œ/g;
  $w =~ s/óe/œ/g;
  $w =~ s/Ae/Æ/g;
  $w =~ s/Áe/Æ/g;
  $w =~ s/Oe/Œ/g;
  $w =~ s/Óe/Œ/g;
  $w =~ s/ý/y/g;
  $w =~ s/([nraeiouáéíóöõúüûÁÉÓÖÔÚÜÛ])i([aeiouáéíóöõúüûÁÉÓÖÔÚÜÛ])/$1j$2/ig;
  $w =~ s/^i([aeiouAEIOUáéíóöõúüûÁÉÓÖÔÚÜÛ])/j$1/g;
  $w =~ s/^I([aeiouAEIOUáéíóöõúüûÁÉÓÖÔÚÜÛ])/J$1/g;
  return $w;
}

sub putaccents {
  my $t = shift;
  $t =~ s/''/ '/;

  $t =~ s/a'/á/g;
  $t =~ s/e'/é/g;
  $t =~ s/i'/í/g;
  $t =~ s/o'/ó/g;
  $t =~ s/o:/ö/g;
  $t =~ s/o"/õ/g;
  $t =~ s/u'/ú/g;
  $t =~ s/u:/ü/g;
  $t =~ s/u"/û/g;
  $t =~ s/A'/Á/g;
  $t =~ s/E'/É/g;
  $t =~ s/&#337;/õ/g;
  $t =~ s/&#369;/û/g;
  $t =~ s/O'/Ó/g;
  $t =~ s/O:'/Ö/g;
  $t =~ s/O:/Ô/g;
  $t =~ s/U'/Ú/g;
  $t =~ s/U:/Ü/g;
  $t =~ s/U"/Û/g;
  $t =~ s/y'/ý/g;

  return $t;
}
