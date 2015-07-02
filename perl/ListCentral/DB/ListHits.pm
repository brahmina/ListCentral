package ListCentral::DB::ListHits;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::ListHits 
##########################################################

=head1 NAME

   ListCentral::DB::ListHits.pm

=head1 SYNOPSIS

   $ListHits = new ListCentral::DB::ListHits($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the ListHits table in the 
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

   my @Fields = ("CreateDate", "Status", "UserID", "ListID", "Referrer", "Email", "IP");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;
}   

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 21/1/2008

=head1 BUGS

   Not known

=cut


