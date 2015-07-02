package Lists::DB::ComplaintsAgainstUser;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::ComplaintsAgainstUser 
##########################################################

=head1 NAME

   Lists::DB::ComplaintsAgainstUser.pm

=head1 SYNOPSIS

   $ComplaintsAgainstUser = new Lists::DB::ComplaintsAgainstUser($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the ComplaintsAgainstUser table in the 
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

   my @Fields = ("InfractionID", "UserID", "CreateDate", "FeedbackID", "AdminUser", "ReportingUserID", "Status");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;
}


1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 27/9/2008

=head1 BUGS

   Not known

=cut


