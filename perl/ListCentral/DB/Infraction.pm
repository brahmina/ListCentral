package ListCentral::DB::Infraction;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::Infraction 
##########################################################

=head1 NAME

   ListCentral::DB::Infraction.pm

=head1 SYNOPSIS

   $Infraction = new ListCentral::DB::Infraction($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the Infraction table in the 
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

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 27/9/2008

=head1 BUGS

   Not known

=cut


