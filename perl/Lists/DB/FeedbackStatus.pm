package Lists::DB::FeedbackStatus;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::FeedbackStatus 
##########################################################

=head1 NAME

   Lists::DB::FeedbackStatus.pm

=head1 SYNOPSIS

   $FeedbackStatus = new Lists::DB::FeedbackStatus($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the FeedbackStatus table in the 
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


