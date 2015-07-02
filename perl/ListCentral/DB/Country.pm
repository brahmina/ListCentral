package ListCentral::DB::Country;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");

use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::Country 
##########################################################

=head1 NAME

   ListCentral::DB::Country.pm

=head1 SYNOPSIS

   $Country = new ListCentral::DB::Country($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the Country table in the 
Lists database.


=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::Country::init");

   my @Fields = ("Code", "Status", "Name");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ();
   $self->{DateFields} = \@DateFields;
}


1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


