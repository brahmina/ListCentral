package Lists::DB::Advert;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::Advert 
##########################################################

=head1 NAME

   Lists::DB::Advert.pm

=head1 SYNOPSIS

   $Advert = new Lists::DB::Advert($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the Advert table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::Advert::init");

   my @Fields = ("Name", "Source", "Code", "Enabled", "Rating", "Status", "CreateDate", "Width", "Height");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;
}

1;

=head1 AUTHOR INFORMATION

   Author:  Marilyn
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


