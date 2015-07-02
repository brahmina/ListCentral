package ListCentral::DB::EmailSent;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::EmailSent 
##########################################################

=head1 NAME

   ListCentral::DB::EmailSent.pm

=head1 SYNOPSIS

   $EmailSent = new ListCentral::DB::EmailSent($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the EmailSent table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::EmailSent::init");

   my @Fields = ("EmailAddress", "EmailID", "SentDate", "Status");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("SentDate");
   $self->{DateFields} = \@DateFields;
}

1;

=head1 AUTHOR INFORMATION

   Author:  with EmailSent from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


