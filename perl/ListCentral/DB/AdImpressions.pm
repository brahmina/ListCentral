package ListCentral::DB::AdImpressions;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::AdImpressions 
##########################################################

=head1 NAME

   ListCentral::DB::AdImpressions.pm

=head1 SYNOPSIS

   $AdImpressions = new ListCentral::DB::AdImpressions($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the AdImpressions table in the 
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

   my @Fields = ("AdvertID", "Date", "Impressions", "Status", "Earnings", "AdSpacesID");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("Date");
   $self->{DateFields} = \@DateFields;
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


