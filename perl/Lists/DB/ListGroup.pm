package Lists::DB::ListGroup;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::ListGroup 
##########################################################

=head1 NAME

   Lists::DB::ListGroup.pm

=head1 SYNOPSIS

   $ListGroup = new Lists::DB::ListGroup($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the ListGroup table in the 
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

   my @Fields = ("CreateDate", "Status", "UserID", "Name");
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


