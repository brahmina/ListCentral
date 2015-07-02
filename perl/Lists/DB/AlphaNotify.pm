package Lists::DB::AlphaNotify;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::AlphaNotify 
##########################################################

=head1 NAME

   Lists::DB::AlphaNotify.pm

=head1 SYNOPSIS

   $AlphaNotify = new Lists::DB::AlphaNotify($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the AlphaNotify table in the 
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

   my @Fields = ("Email", "CreateDate", "Status");
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


