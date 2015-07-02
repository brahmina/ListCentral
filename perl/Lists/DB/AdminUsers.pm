package Lists::DB::AdminUser;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::AdminUser 
##########################################################

=head1 NAME

   Lists::DB::AdminUser.pm

=head1 SYNOPSIS

   $AdminUser = new Lists::DB::AdminUser($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the AdminUser table in the 
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

   my @Fields = ("Username", "Password", "Status", "Name", "Email");
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


