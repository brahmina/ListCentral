package Lists::DB::AdSpaces;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::AdSpaces 
##########################################################

=head1 NAME

   Lists::DB::AdSpaces.pm

=head1 SYNOPSIS

   $AdSpaces = new Lists::DB::AdSpaces($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the AdSpaces table in the 
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

   my @Fields = ("Name", "Rating", "Status", "Width", "Height");
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


