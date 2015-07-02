package Lists::DB::UserLogins;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::UserLogins 
##########################################################

=head1 NAME

   Lists::DB::UserLogins.pm

=head1 SYNOPSIS

   $UserLogins = new Lists::DB::UserLogins($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the UserLogins table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::UserLogins::init");

   my @Fields = ("IP", "UserID", "CreateDate");
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


