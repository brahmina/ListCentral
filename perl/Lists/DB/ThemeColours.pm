package Lists::DB::ThemeColours;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::ThemeColours 
##########################################################

=head1 NAME

   Lists::DB::ThemeColours.pm

=head1 SYNOPSIS

   $ThemeColours = new Lists::DB::ThemeColours($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the ThemeColours table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::AdImpressions::init");

   my @Fields = ("ThemeID", "Status", "Colour", "Position");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ();
   $self->{DateFields} = \@DateFields;
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


