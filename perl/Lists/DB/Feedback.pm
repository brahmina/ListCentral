package Lists::DB::Feedback;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::Feedback 
##########################################################

=head1 NAME

   Lists::DB::Feedback.pm

=head1 SYNOPSIS

   $Feedback = new Lists::DB::Feedback($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the Feedback table in the 
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

   my @Fields = ("CreateDate", "FeedbackTypeID", "FeedbackStatusID", "ReportingUserID", "Message", 
                     "ProblematicUserID", "ProblematicListID", "Status", "Email", "IP", "Spam");
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


