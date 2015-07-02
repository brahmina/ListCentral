package Lists::DB::FeedbackReply;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::FeedbackReply 
##########################################################

=head1 NAME

   Lists::DB::FeedbackReply.pm

=head1 SYNOPSIS

   $FeedbackReply = new Lists::DB::FeedbackReply($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the FeedbackReply table in the 
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

   my @Fields = ("FeedbackID", "AdminUser", "ReplyDate", "Reply", "Note", "Status");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("ReplyDate");
   $self->{DateFields} = \@DateFields;
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 27/9/2008

=head1 BUGS

   Not known

=cut


