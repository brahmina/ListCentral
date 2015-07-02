package Lists::DB::PersistentCookies;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::PersistentCookies 
##########################################################

=head1 NAME

   Lists::DB::PersistentCookies.pm

=head1 SYNOPSIS

   $PersistentCookies = new Lists::DB::PersistentCookies($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the PersistentCookies table in the 
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

   my @Fields = ("UserID", "RandomString", "CreateDate", "Used", "Status");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;
}
   
1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


