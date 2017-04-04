#!/usr/bin/perl
use strict;
use LWP::Simple;

my $root_url = "http://tampahackerspace.com/wiki";
my @pages;
my $page_cnt = 0;

sub add_page
{
   my ($new_page) = @_;
   $new_page =~ s/^\s+//;
   $new_page =~ s/\s+$//;
   if ($new_page =~ /^media:/i) {
      print "Skipping ref ".$new_page."\n";
      return;
   } elsif ($new_page =~ /^file:/i) {
      print "Skipping file ".$new_page."\n";
      return;
   } elsif ($new_page =~ /^https?:/i) {
      print "Skipping external link ".$new_page."\n";
      return;
   }
   if ($new_page =~ s/(#.*$)//) {
      print "Stripping ".$1."\n";
   }
   my $found = 0;
   my $idx;
   for ($idx = 0; $idx < $page_cnt; $idx++) {
      if (($new_page eq $pages[$idx])) {
         return;
      }
   }
   print "Adding $new_page\n";
   $pages[$page_cnt++] = $new_page;
}

sub get_page
{
   my ($page) = @_;
   $page =~ s/\ /_/g;
   my $content = get($root_url."/index.php?title=".$page."&action=edit");
   my @lines = split(/[\r\n]/, $content);
   my $text_area_start = -1;
   my $text_area_stop = -1;
   if ($page =~ s/\?//g) {
      print "Removed ? from ".$page."\n";
   }
   my $line = 0;
   foreach (@lines) {
      my $curr_line = $_;
      if ($curr_line =~ /<textarea\ .*\ name=\"wpTextbox1\">/) {
         $text_area_start = $line + 1;
      }
      if ($curr_line =~ /<\/textarea>/) {
         $text_area_stop = $line;
      }
      $line++;
   }
   if (($text_area_start > -1) && ($text_area_stop > -1)) {
      if (open PARTIAL, ">".$page.".txt") {
         binmode(PARTIAL, ":utf8");
         my $idx;
         for ($idx = $text_area_start; $idx < $text_area_stop; $idx++) {
            print PARTIAL $lines[$idx]."\n";
            while ($lines[$idx] =~ s/\[\[([^\]]*)\]\]//) {
               my $link = $1;
               if ($link =~ /^([^\|]+)\|([^\|]+)$/) {
                  my ($target, $rename) = ($1, $2);
                  print "Found $target - $rename\n";
                  add_page($target);
               } else {
                  print "Found $link\n";
                  add_page($link);
               }
            }
         }
         close PARTIAL;
      }
   }
}

my $idx = 0;
add_page("Main_Page");
while ($idx < $page_cnt) {
   get_page($pages[$idx++]);
}
