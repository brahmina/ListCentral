package Lists::DB::Date;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::Date 
##########################################################

=head1 NAME

   Lists::DB::Date.pm

=head1 SYNOPSIS

   $Date = new Lists::DB::Date($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the Date table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::Date::init");

   my @Fields = ("DateEng", "DateEpoch", "UserID", "Status", "EmailFrequency");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ();
   $self->{DateFields} = \@DateFields;
}

=head2 saveDate

Saves a new Date

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $id - The id of the date saved

=back

=cut

#############################################
sub saveDate {
#############################################
   my $self = shift;
   my $cgi = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in Lists::DB::Date");

   my %Date;
   $Date{"Date.DateEng"} = $cgi->{"ListItem.Date"};
   $Date{"Date.DateEpoch"} = Lists::Utilities::Date::getEpochDateTime($cgi->{"ListItem.Date"});
   if(! $Date{"Date.DateEpoch"}){
      # Error
      return  $Lists::SETUP::MESSAGES{'MALFORMED_DATE'};
   }
   
   $Date{"Date.UserID"} = $cgi->{"ListItem.Date"};
   $Date{"Date.EmailFrequency"} = $cgi->{"ListItem.EmailFrequency"};
   $Date{"Date.Status"} = 1;
   $Date{"Date.UserID"} = $UserID;
   
   my $DateID = $self->store(\%Date);

   return $DateID;
}

1;

=head1 AUTHOR INFORMATION

   Author:  Marilyn
   Created: 12/12/2009

=head1 BUGS

   Not known

=cut


