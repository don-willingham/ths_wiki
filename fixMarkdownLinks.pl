#!/usr/bin/perl
use strict;

# http://tampahackerspace.com/wiki/index.php/Special:WantedPages
# has several (22 at the time of writing) "wanted pages"
my $create_wanted_pages = 0;

sub fixMarkdown
{
   my ($filename) = @_;
   if (open IN, "<".$filename) {
      my $changes = 0;
      my $line_cnt = 0;
      my @lines;
      while (<IN>) {
         my $curr_line = $_;
         chomp $curr_line;
         if ($curr_line =~ /\(([^\ ]+)\ "wikilink"\)/) {
            my $link = $1;
            print "Link ".$link;
            if ($link =~ /\.md$/) {
               if (-e $link) {
                  print " found";
               } else {
                  print " not found";
               }
            } else {
               if (-e $link.".md") {
                  print "+.md found";
                  $curr_line =~ s/\($link\ "wikilink"/\($link.md\ "wikilink"/;
                  $changes++;
               } else {
                  print "+.md not found";
               }
            }
            print "\n";
         }
         $lines[$line_cnt++] = $curr_line;
      }
      close IN;
      if ($changes > 0) {
         if (open OUT, ">".$filename) {
            my $idx;
            for($idx=0;$idx<$line_cnt;$idx++) {
               print OUT $lines[$idx]."\n";
            }
            close OUT;
         } else {
            print "ERROR: Couldn't open ".$filename." for writing\n";
         }
      }
   }
}
my @files = glob("*.md");
foreach (@files) {
   my $curr_file = $_;
   fixMarkdown($curr_file);
}
