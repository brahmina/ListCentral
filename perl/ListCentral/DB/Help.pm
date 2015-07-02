package ListCentral::DB::Help;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::Help 
##########################################################

=head1 NAME

   ListCentral::DB::Help.pm

=head1 SYNOPSIS

   $Help = new ListCentral::DB::Help($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the Help table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::Help::init");

   my @Fields = ("Name", "Url", "ContentHTML", "Status", "Ordering");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ();
   $self->{DateFields} = \@DateFields;
}

=head2 getListings

Gets the ID, Name, Url of all of the listings with status > 0

=back

=cut

#############################################
sub getListings {
#############################################
   my $self = shift;

   $self->{Debugger}->debugNow("in ListCentral::DB::Help::getListings");

   my %HelpListings;
   my $sql_select = "SELECT ID, Name, Url, Ordering
                     FROM $ListCentral::SETUP::DB_NAME.Help 
                     WHERE $self->{StatusField} > 0";
   $self->{Debugger}->debugNow("$sql_select");
   my $stm = $self->{dbh}->prepare($sql_select);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $HelpListings{$hash->{ID}} = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with $self->{Table}  SELECT: $sql_select - $DBI::errstr");
   }
   $stm->finish; 

   return \%HelpListings;
}

=head2 getNextHelpPosition

Gets the ID, Name, Url of all of the listings with status > 0

=back

=cut

#############################################
sub getNextHelpPosition {
#############################################
   my $self = shift;

   $self->{Debugger}->debugNow("in ListCentral::DB::Help::getNextHelpPosition");

   my $NextPos;
   my $sql_select = "SELECT MAX(Ordering)+1 AS NextPos FROM Help;";
   my $stm = $self->{dbh}->prepare($sql_select);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
        $NextPos = $hash->{NextPos};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with $self->{Table}  SELECT: $sql_select - $DBI::errstr");
   }
   $stm->finish; 

   return $NextPos;
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


