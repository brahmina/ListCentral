#!/usr/lib/perl

# Used to help create a new theme
# Work still required for images

use strict;

my $COLOR1 = "121d52"; # Dark blue
my $COLOR2 = "1D687A"; # Green Blue
my $COLOR3 = "BDEAFF"; # Light Blue
my $COLOR4 = "FFFF66"; # Yellow
my $COLOR5 = "FFFFFF"; # White
my $ThemeID = 2;

print "Hiya!\n";

my $results = `mkdir /home/marilyn/Documents/www/html/Lists/css/$ThemeID`;
print "Made dir /home/marilyn/Documents/www/html/Lists/css/$ThemeID: $results\n";

my @Directories = ('/home/marilyn/Documents/www/html/Lists/css/Base/mozilla', '/home/marilyn/Documents/www/html/Lists/css/Base/ie');


foreach my $dir (@Directories) {
   my $NewDir = $dir;
   $NewDir =~ s/Base/$ThemeID/;
   my $results = `mkdir $NewDir`;
   print "Made dir $NewDir: $results\n";

   opendir(DIR, $dir) || die "can't opendir $dir: $!";
   my @Files = grep {-f "$dir/$_" } readdir(DIR);
   closedir DIR;

   foreach my $filename (@Files) {
      my $file = "$dir/$filename";
      open(PAGE, $file) || die "cannot open file: $file - $!";
      my @lines = <PAGE>;
      close PAGE;

      my $content = "";
      foreach my $line (@lines) {
         if($line =~ m/<!--(.+)-->/){
            if($line =~ m/<!--COLOR1-->/){
               $line =~ s/<!--COLOR1-->/$COLOR1/;
            }
            if($line =~ m/<!--COLOR2-->/){
               $line =~ s/<!--COLOR2-->/$COLOR2/;
            }
            if($line =~ m/<!--COLOR3-->/){
               $line =~ s/<!--COLOR3-->/$COLOR3/;
            }
            if($line =~ m/<!--COLOR4-->/){
               $line =~ s/<!--COLOR4-->/$COLOR4/;
            }
            if($line =~ m/<!--COLOR5-->/){
               $line =~ s/<!--COLOR5-->/$COLOR5/;
            }
            if($line =~ m/<!--THEME_NO-->/){
               $line =~ s/<!--THEME_NO-->/$ThemeID/;
            }
         }
         $content .= $line;
      }

      # Write the content to the file
      my $NewFile = $file;
      $NewFile =~ s/Base/$ThemeID/;

      open NEWFILE, "> $NewFile" or die "Can't open $NewFile : $!\n";
      print NEWFILE $content;
      close NEWFILE;

      print "Wrote file: $NewFile\n";
   }
}

print "Cya! \n";

