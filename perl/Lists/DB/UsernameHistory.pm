package Lists::DB::UsernameHistory;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;

use Lists::SETUP;

##########################################################
# Lists::DB::UsernameHistory 
##########################################################

=head1 NAME

   Lists::DB::UsernameHistory.pm

=head1 SYNOPSIS

   $UsernameHistory = new Lists::DB::UsernameHistory($dbh, $debug);

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

   $self->{Debugger}->debug("in Lists::DB::UsernameHistory::init");

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


