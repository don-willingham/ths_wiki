#!/usr/bin/perl
use strict;
use LWP::UserAgent ();

my $root_url = "https://wiki.tampahackerspace.com";
my @pages;
my $page_cnt = 0;
my $write_full = 0;

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;

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
   my $response = $ua->get($root_url."/index.php?title=".$page."&action=edit");
   my $content;
   if ($response->is_success) {
      $content = $response->decoded_content;
   } else {
      print "Failed to get page ".$page." : ".$response->status_line."\n";
      return;
   }
   my @lines = split(/[\r\n]/, $content);
   my $text_area_start = -1;
   my $text_area_stop = -1;
   if ($page =~ s/\?//g) {
      print "Removed ? from ".$page."\n";
   }
   # Trim leading :'s
   $page =~ s/^:+//;
   if ($page =~ s/\:/\//g) {
      print "Converted : to / for ".$page."\n";
      my $subdir = $page;
      $subdir =~ s/\/[^\/]+$//;
      mkdir $subdir;
   }
   if ($write_full) {
      if (open FULL, ">".$page.".full.txt") {
         binmode(FULL, ":utf8");
      } else {
         die("Failed to open ".$page.".full.txt for writing");
      }
   }
   my $line = 0;
   foreach (@lines) {
      my $curr_line = $_;
      if ($write_full) {
         print FULL $curr_line."\n";
      }
      if ($curr_line =~ s/(<\/p>)?<textarea\ .*\ name=\"wpTextbox1\">//) {
         while ($curr_line =~ s/<input type="hidden" value="[^\"]+" name="[^\"]+"\/>//) { }
         $curr_line =~ s/<div id="toolbar"><\/div>//;
         $text_area_start = $line;
         $lines[$line] = $curr_line;
      }
      if ($curr_line =~ /<\/textarea>/) {
         $text_area_stop = $line;
      }
      $line++;
   }
   if ($write_full) {
      close FULL;
   }
   if (($text_area_start > -1) && ($text_area_stop > -1)) {
      if (open PARTIAL, ">".$page.".txt") {
         binmode(PARTIAL, ":utf8");
         my $idx;
         for ($idx = $text_area_start; $idx < $text_area_stop; $idx++) {
            if ($lines[$idx] =~ /^\[\[Category:[^\]]+\]\]$/) {
               # Don't print the categories to the file
            } else {
               print PARTIAL $lines[$idx]."\n";
            }
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
add_page("Category:Main");
while ($idx < $page_cnt) {
   get_page($pages[$idx++]);
}
