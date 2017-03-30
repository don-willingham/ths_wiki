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
   my $found = 0;
   my $idx;
   for ($idx = 0; $idx < $page_cnt; $idx++) {
      if (($new_page eq $pages[$idx])) {
         return;
      }
   }
   if ($new_page =~ /^https?:/) {
      print "Skipping $new_page\n";
      return;
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
   if (open FULL, ">".$page.".full.txt") {
      my $line = 0;
      foreach (@lines) {
         my $curr_line = $_;
         print FULL $curr_line."\n";
         if ($curr_line =~ /<textarea\ .*\ name=\"wpTextbox1\">/) {
            $text_area_start = $line + 1;
         }
         if ($curr_line =~ /<\/textarea>/) {
            $text_area_stop = $line;
         }
         $line++;
      }
      close FULL;
   }
   if (($text_area_start > -1) && ($text_area_stop > -1)) {
      if (open PARTIAL, ">".$page.".txt") {
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

