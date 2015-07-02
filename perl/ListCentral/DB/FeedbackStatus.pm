package ListCentral::DB::FeedbackStatus;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::FeedbackStatus 
##########################################################

=head1 NAME

   ListCentral::DB::FeedbackStatus.pm

=head1 SYNOPSIS

   $FeedbackStatus = new ListCentral::DB::FeedbackStatus($dbh, $debug);

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

   $self->{Debugger}->debug("in ListCentral::DB::AdImpressions::init");

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


