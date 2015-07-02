package ListCentral::DB::Theme;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::Theme 
##########################################################

=head1 NAME

   ListCentral::DB::Theme.pm

=head1 SYNOPSIS

   $Theme = new ListCentral::DB::Theme($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the Theme table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::AdImpressions::init");

   my @Fields = ("Status", "Name");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ();
   $self->{DateFields} = \@DateFields;
}

=head2 getThemeVisuals

Returns the javascript for the member theme visualization

=over 4

=item B<Parameters :>

   1. $self - Reference to a ApplicationFramework::Processor object

=itme B<Returns : >

   1. $js - the javascript, array of arrays of theme colours

=back

=cut

#############################################
sub getThemeVisuals {
#############################################
   my $self = shift;
   my $DBManager = shift;

   $self->{Debugger}->debug("in ListCentral::DB::Theme->getThemeVisuals");

   # Get the Theme Info
   my $ThemeColourObj = $DBManager->getTableObj("ThemeColours");

   my $Themes = $self->get_all();

   my $count = 0;
   my $js = "themeColours = new Array();\n";
   foreach my $ID(sort keys  %{$Themes}) {
      my $ThemeColours = $ThemeColourObj->get_with_restraints("ThemeID = $ID");
      $js .= "themeColours[$ID] = new Array(";
      foreach my $id(sort{$ThemeColours->{$a}->{Position} <=> $ThemeColours->{$b}->{Position}} keys %{$ThemeColours}) {
         $js .= "'$ThemeColours->{$id}->{Colour}',";
      }
      $js =~ s/,$//;
      $js .= ");\n";
   }

   return $js;
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


