package ListCentral::DB::Email;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::Email 
##########################################################

=head1 NAME

   ListCentral::DB::Email.pm

=head1 SYNOPSIS

   $Email = new ListCentral::DB::Email($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the Email table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::Email::init");

   my @Fields = ("Subject", "HTML", "Text", "CreateDate", "Status");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;
}

1;

=head1 AUTHOR INFORMATION

   Author:  with Email from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


