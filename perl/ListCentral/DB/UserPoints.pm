package ListCentral::DB::UserPoints;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;

use ListCentral::SETUP;

##########################################################
# ListCentral::DB::UserPoints 
##########################################################

=head1 NAME

   ListCentral::DB::UserPoints.pm

=head1 SYNOPSIS

   $UserPoints = new ListCentral::DB::UserPoints($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the UserPoints table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::UserPoints::init");

   my @Fields = ("UserID", "MostRecent", "24Hours", "72Hours", "LastWeek", "LastMonth", "LastYear", 
                  "AllTime", "ActivityMostRecent", "Activity24Hours", "Activity72Hours", "ActivityLastWeek", 
                  "ActivityLastMonth", "ActivityLastYear", "ActivityAllTime", "Status");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ();
   $self->{DateFields} = \@DateFields;
}

=head2 getByUserID

Gets the UserPoints entry corresponding the the UserID passed and returns a reference to a hash containing
the UserPoints information 

=over 4

=item B<Parameters :>

   1. $self - Reference to a UserPoints object
   2. $ListID - The UserPoints id

=item B<Returns: >

   1. $UserPoints - Reference to a hash with the UserPoints data

=back

=cut

#############################################
sub getByUserID {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::DB::UserPoints::getByUserID with $UserID");

   my $UserPoints;
   my $sql_select = "SELECT * 
                     FROM $ListCentral::SETUP::DB_NAME.UserPoints 
                     WHERE UserID = $UserID
                           AND Status > 0";

   my $stm = $self->{dbh}->prepare($sql_select);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $UserPoints = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with UserPoints SELECT: $sql_select - $DBI::errstr");
   }
   $stm->finish;

   return $UserPoints;
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 27/9/2008

=head1 BUGS

   Not known

=cut


