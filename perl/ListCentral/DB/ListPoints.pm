package ListCentral::DB::ListPoints;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::ListPoints 
##########################################################

=head1 NAME

   ListCentral::DB::ListPoints.pm

=head1 SYNOPSIS

   $ListPoints = new ListCentral::DB::ListPoints($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the ListPoints table in the 
Lists database.


=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::ListPoints::init");

   my @Fields = ("ListID", "ListPoints", "RankingHN", "RankingReddit", "Activity", "DateMadePublic", "Status");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("DateMadePublic");
   $self->{DateFields} = \@DateFields;
}

=head2 getByListID

Gets the ListPoints entry corresponding the the UserID passed and returns a reference to a hash containing
the ListPoints information 

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListPoints object
   2. $ListID - The ListPoints id

=item B<Returns: >

   1. $ListPoints - Reference to a hash with the ListPoints data

=back

=cut

#############################################
sub getByListID {
#############################################
   my $self = shift;
   my $ListID = shift;

   $self->{Debugger}->debug("in ListCentral::DB::ListPoints::getByListID with $ListID");

   my $ListPoints;
   my $sql_select = "SELECT * 
                     FROM $ListCentral::SETUP::DB_NAME.ListPoints 
                     WHERE ListID = $ListID
                           AND Status > 0";

   my $stm = $self->{dbh}->prepare($sql_select);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $ListPoints = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with ListPoints SELECT: $sql_select - $DBI::errstr");
   }
   $stm->finish;

   return $ListPoints;
}


1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 27/9/2008

=head1 BUGS

   Not known

=cut


