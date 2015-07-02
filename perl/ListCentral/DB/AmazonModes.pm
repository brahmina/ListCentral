package ListCentral::DB::AmazonModes;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::AmazonModes 
##########################################################

=head1 NAME

   ListCentral::DB::AmazonModes.pm

=head1 SYNOPSIS

   $AmazonModes = new ListCentral::DB::AmazonModes($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the AmazonModes table in the 
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

   my @Fields = ("Mode", "Name");
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


