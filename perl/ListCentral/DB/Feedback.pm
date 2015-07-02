package ListCentral::DB::Feedback;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::Feedback 
##########################################################

=head1 NAME

   ListCentral::DB::Feedback.pm

=head1 SYNOPSIS

   $Feedback = new ListCentral::DB::Feedback($dbh, $debug);

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

   $self->{Debugger}->debug("in ListCentral::DB::AdImpressions::init");

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


