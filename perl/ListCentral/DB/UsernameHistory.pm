package ListCentral::DB::UsernameHistory;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;

use ListCentral::SETUP;

##########################################################
# ListCentral::DB::UsernameHistory 
##########################################################

=head1 NAME

   ListCentral::DB::UsernameHistory.pm

=head1 SYNOPSIS

   $UsernameHistory = new ListCentral::DB::UsernameHistory($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the UsernameHistory table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::UsernameHistory::init");

   my @Fields = ("UserID", "Username", "Date");
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


