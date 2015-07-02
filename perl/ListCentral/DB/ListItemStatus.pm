package ListCentral::DB::ListItemStatus;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::ListItemStatus 
##########################################################

=head1 NAME

   ListCentral::DB::ListItemStatus.pm

=head1 SYNOPSIS

   $ListItemStatus = new ListCentral::DB::ListItemStatus($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the ListItemStatus table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::AdImpressions::init");

   my @Fields = ("Status", "UserID", "Name", "StatusSet");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;
}

=head2 getInitialStatus

Gets the initial status of a status group and returns the id

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListItemStatus object
   2. $ID - The ListItemStatus id

=item B<Returns: >

   1. $ListItemStatus - Reference to a hash with the ListItemStatus data

=back

=cut

#############################################
sub getInitialStatus {
#############################################
   my $self = shift;
   my $Set = shift;

   $self->{Debugger}->debug("in ListCentral::DB::ListItemStatus::getInitialStatus with set: $Set");

   if($Set == 0){
      return 1;
   }

   my $ListItemStatus;
   my $sql_select = "SELECT MIN(ID) AS ID 
                     FROM $ListCentral::SETUP::DB_NAME.ListItemStatus 
                     WHERE StatusSet = $Set
                           AND Status > 0";
   my $stm = $self->{dbh}->prepare($sql_select);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $ListItemStatus = $hash->{ID};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with ListItemStatus SELECT: $sql_select - $DBI::errstr");
   }
   $stm->finish;

   return $ListItemStatus;
}

=head2 getNextStatusSetID

Gets the next status set id

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListItemStatus object

=item B<Returns: >

   1. $NextListItemStatusID - The next list item status

=back

=cut

#############################################
sub getNextStatusSetID {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::ListItemStatus::getNextStatusSetID");

   my $MaxListItemStatusID;
   my $sql_select = "SELECT MAX(StatusSet) AS StatusSetID
                     FROM $ListCentral::SETUP::DB_NAME.ListItemStatus";

   my $stm = $self->{dbh}->prepare($sql_select);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $MaxListItemStatusID = $hash->{'StatusSetID'};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with ListItemStatus SELECT: $sql_select - $DBI::errstr");
   }
   $stm->finish;

   $MaxListItemStatusID++;

   return $MaxListItemStatusID;
}

=head2 getStatusSetValue

Gets the comma separated list item status for the given status set

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::ListsManager object
   2. $Statusset - The Status Set to get the ListItemStatus for

=item B<Returns :>

   1. $content - the comma separated list item statuses

=back

=cut

#####################################
sub getStatusSetValue {
#####################################
   my $self = shift;
   my $StatusSetID = shift;
   my $DBManager = shift;


   my $TableObj = $DBManager->getTableObj("ListItemStatus");
   my $ListItemStatuses = $TableObj->get_with_restraints("StatusSet = $StatusSetID");

   my $StatusSet = "";
   foreach my $ID (sort keys %{$ListItemStatuses}) {
      if($StatusSet){
         $StatusSet .= "\/$ListItemStatuses->{$ID}->{Name}";
      }else{
         $StatusSet = "$ListItemStatuses->{$ID}->{Name}";
      }              
   }

   return $StatusSet;
}

=head2 getListItemStatusSetSelect

Gets the javascript array for the dynamic edit list item pop up form

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::ListsManager object

=item B<Returns :>

   1. $content - the javascript

=back

=cut

#############################################
sub getListItemStatusSetSelect {
#############################################
   my $self = shift;
   my $List = shift;
   my $ListItemStatusID = shift;

   $self->{Debugger}->debug("in ListCentral::ListsManager::getListItemStatusSetSelect");

   if($List->{StatusSet} == 0){
      return "";
   }

   if($ListItemStatusID == -1){
      $ListItemStatusID = $self->getInitialStatus($List->{StatusSet});
   }

   my $Select = qq~<label for="ListItem">Status:</label><select name="ListItem.ListItemStatusID" id="ListItemListItemStatusID">~;
   my $ListItemStatus = $self->get_with_restraints("StatusSet = $List->{StatusSet}");
   foreach my $ID (sort keys %{$ListItemStatus}) {
      if($ID == $ListItemStatusID){
         $Select .= qq~<option value="$ID" selected="selected">$ListItemStatus->{$ID}->{Name}</option>~;
      }else{
         $Select .= qq~<option value="$ID">$ListItemStatus->{$ID}->{Name}</option>~;
      }
      
   }
   $Select .= qq~</select>~;

   return $Select;
}

=head2 getListItemStatusSetJSArray

Gets the javascript array for the dynamic edit list item pop up form

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::ListsManager object

=item B<Returns :>

   1. $content - the javascript

=back

=cut

#############################################
sub getListItemStatusSetJSArray {
#############################################
   my $self = shift;
   my $ListID = shift;
   my $DBManager = shift;

   $self->{Debugger}->debug("in ListCentral::ListsManager::getListItemStatusSetJSArray");

   my $ListObj = $DBManager->getTableObj("List");

   my $JS = "StatusSetSelect = new Array();\n";
   my $List = $ListObj->get_by_ID($ListID);
   my $ListGroupStatus = $self->get_with_restraints("StatusSet = $List->{StatusSet}");
   foreach my $ID (sort keys %{$ListGroupStatus}) {
      $JS .= "StatusSetSelect[$ID] = '$ListGroupStatus->{$ID}->{Name}';\n";
   }
   $JS .= "StatusSetSelect[0] = 'Deleted';\n";
   return $JS;
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 21/1/2008

=head1 BUGS

   Not known

=cut


