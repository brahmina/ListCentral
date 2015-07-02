package ListCentral::Editor;
use strict;

use ListCentral::SETUP;


##########################################################
# ListCentral::Editor 
##########################################################

=head1 NAME

   ListCentral::Editor.pm

=head1 SYNOPSIS

   $Editor = new ListCentral::Editor($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the List application

=head2 ListCentral::Editor Constructor

=over 4

=item B<Parameters :>

   1. $dbh
   2. $cgi
   3. $debug

=back

=cut

########################################################
sub new {
########################################################
   my $classname = shift; 
   my $self; 
   %$self = @_; 
   bless $self, ref($classname)||$classname;

   $self->{Debugger}->debug("in ListCentral::Editor constructor");

   if(!$self->{DBManager}){
      die "Where is Editor's DBManager??";
   }
   if(!$self->{UserManager}){
      die "Where is Editor's UserManager??";
   }
   if(!$self->{cgi}){
      die "Where is Editor's cgi??";
   }
   if(!$self->{Debugger}){
      print STDERR "No debugger? $self->{Debugger}\n";
   }

   return ($self); 
}

=head2 doEditInPlace

Does the edit in place business

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::ListManager object

=item B<Returns :>

   1. $html

=back

=cut

#####################################
sub doEditInPlace {
#####################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Editor::doEditInPlace");

   my $UserID = $self->getItemsUserID();

   my $content = "";
   if($self->{UserManager}->{ThisUser}->{ID} != $UserID){
      $content = "You shouldn't be doing that!<br />";
   }else{
      if($self->{cgi}->{"Table"}){
         if($self->{cgi}->{"Value"}){
            my $value = ListCentral::Utilities::StringFormator::unquoteText($self->{cgi}->{"Value"});
            if($self->{cgi}->{'Field'} ne "Description"){
               $value = ListCentral::Utilities::StringFormator::htmlEncode($value);
            }elsif($self->{cgi}->{'Field'} eq "Description" && ListCentral::Utilities::StringFormator::hasBadHTML($self->{cgi}->{"Value"})){
               $value = ListCentral::Utilities::StringFormator::htmlEncode($value);
            }
            my $function = "update$self->{cgi}->{'Table'}";
            $content = $self->$function($self->{cgi}->{"ID"}, $value);
         }else{            
            # Allow user to delete Description & StatusSet value here
            if($self->{cgi}->{'Field'} eq "Description"){                  
               $content = $self->updateListItem($self->{cgi}->{"ID"}, "");
            }elsif($self->{cgi}->{'Table'} eq "StatusSet"){
               my $function = "update$self->{cgi}->{'Table'}";
               $content = $self->$function($self->{cgi}->{"ID"}, "");
            }else{
               # Disable delete editable thing on eq ""
               # return the editable version of the thing
               
               my $tableObj = $self->{DBManager}->getTableObj($self->{cgi}->{'Table'});
               my $value = $tableObj->get_field_by_ID("Name", $self->{cgi}->{"ID"});
   
               my $function = "getEditable$self->{cgi}->{'Table'}";
               $content = $self->$function($self->{cgi}->{"ID"}, $value, 0);
            }
         } 
      }else{
         $content = "Something is ef'ed around here!<br />";
      }
   }
   return $content;
}

=head2 getItemsUserID

Figures out the UserID of the item being edited in place

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::ListManager object

=item B<Returns :>

   1. $html

=back

=cut

#####################################
sub getItemsUserID {
#####################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Editor::getItemsUserID");

   my $UserID;
   if($self->{cgi}->{"Table"} eq "ListItem"){
      if($self->{cgi}->{"ID"}){
         my $ListItemObj = $self->{DBManager}->getTableObj("ListItem");
         my $ListID = $ListItemObj->get_field_by_ID("ListID", $self->{cgi}->{"ID"});
         my $ListObj = $self->{DBManager}->getTableObj("List");
         $UserID = $ListObj->get_field_by_ID("UserID", $ListID);
      }
   }else{
      if($self->{cgi}->{"ID"}){
         if($self->{cgi}->{"Table"} eq "StatusSet"){
            my $ListItemStatusObj = $self->{DBManager}->getTableObj("ListItemStatus");
            my $Statuses = $ListItemStatusObj->get_with_restraints("StatusSet = $self->{cgi}->{'ID'}");
            foreach my $id(keys %{$Statuses}) {
               $UserID = $Statuses->{$id}->{"UserID"};
            }
         }else{
            my $tableObj = $self->{DBManager}->getTableObj($self->{cgi}->{"Table"});
            $UserID = $tableObj->get_field_by_ID("UserID", $self->{cgi}->{"ID"});
         }
      }
   }
   return $UserID;
}

=head2 getEditableListGroups

Gets the html for the editable list groups 

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::ListManager object

=item B<Returns :>

   1. $html

=back

=cut

#####################################
sub getEditableListGroups {
#####################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Editor::getEditableListGroups");

   my $ListGroupObj = $self->{DBManager}->getTableObj("ListGroup");
   my $ListGroups = $ListGroupObj->get_with_restraints("UserID = $self->{UserManager}->{ThisUser}->{ID}");

   my $html = "<ul class='editableUL' id='editableListGroups'>";
   foreach my $ID (sort keys %{$ListGroups}) {
      my $editableListGroup = $self->getEditableListGroup($ID, $ListGroups->{$ID}->{Name});

      $html .= qq~<li>
                     <div class="EditableListGroupDiv">
                        <a href="javascript:deleteListGroup($ID)" class="DeleteTransparent"></a>
                        <div id="ListGroup$ID" class="noneditable">$editableListGroup </div>
                     </div>
                     <img src="/images/$self->{ThemeID}/SmallUnderline.png" class="EditUnderLine" />
                  </li>~;
   }
   $html .= "</ul>";

   return $html;
}

=head2 getEditableStatusSets

Gets the html for the editable status sets

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::ListManager object

=item B<Returns :>

   1. $html

=back

=cut

#####################################
sub getEditableStatusSets {
#####################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Editor::getEditableStatusSet");

   my $ListItemStatusObj = $self->{DBManager}->getTableObj("ListItemStatus");
   my $ListItemStatus = $ListItemStatusObj->get_with_restraints("UserID = $self->{UserManager}->{ThisUser}->{ID}");

   my %StatusSets;
   foreach my $ID (sort keys %{$ListItemStatus}) {
      if($StatusSets{$ListItemStatus->{$ID}->{StatusSet}}){
         $StatusSets{$ListItemStatus->{$ID}->{StatusSet}} .= ", $ListItemStatus->{$ID}->{Name}";
      }else{
         $StatusSets{$ListItemStatus->{$ID}->{StatusSet}} = "$ListItemStatus->{$ID}->{Name}";
      }              
   }
   my $html = "<ul class='editableUL' id='editableStatusSets'>";
   foreach my $ID(sort keys %StatusSets) {
      my $editableStatusSet = $self->getEditableStatusSet($ID, $StatusSets{$ID});
      $html .= qq~<li>
                     <div class="EditableStatusSetDiv">
                        <a href="javascript:deleteStatusSet($ID)" class="DeleteTransparent"></a>
                        <div id="StatusSet$ID" class="noneditable">$editableStatusSet </div> 
                        <img src="/images/$self->{ThemeID}/SmallUnderline.png" class="EditUnderLine" />
                     </div>
                  </li>~;             
   }
   $html .= "</ul>";

   return $html;
}


=head2 getEditableListItem

Gets the html for an editable list item

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $ListItemid - The list item 
   3. Item
   4. $outterTagRequired

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub getEditableListItem {
#############################################
   my $self = shift;
   my $ListItemID = shift;
   my $Item = shift;
   my $outterTagRequired = shift;

   # When is this outter tag required? 
   #$self->{Debugger}->debug("in ListCentral::ListManager::getEditableListItem");

   my $divID = "ListItem$ListItemID";
   my $spanID = $divID . "Span";
   my $onmouseoutFunction = "onmouseout=\"showAsEditable('$divID', true)\"";
   my $onmouseoverFunction = "onmouseover=\"showAsEditable('$divID', false)\"";
   my $onclickFunction = "onclick=\"edit('$divID', this, 3)\"";
   
   my $return = qq~<span $onmouseoutFunction $onmouseoverFunction $onclickFunction id="$spanID">$Item</span>~;

   return $return;
}

=head2 getEditableListItemDescription

Gets the html for an editable list item description

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $ListItemid - The list item to get updated
   3. $Item - The Item name
   4. $outterTagRequired

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub getEditableListItemDescription {
#############################################
   my $self = shift;
   my $ListItemID = shift;
   my $Item = shift;
   my $outterTagRequired = shift;

   # When is this outter tag required?
   $self->{Debugger}->debug("in ListCentral::Editor::getEditableListItem $ListItemID & $Item");
   
   if($Item eq ""){
      return "";
   }else{
      my $divID = "ListItem$ListItemID" . "Description";
      my $spanID = $divID . "Span";
      my $onmouseoutFunction = "onmouseout=\"showAsEditable('$divID', true)\"";
      my $onmouseoverFunction = "onmouseover=\"showAsEditable('$divID', false)\"";
      my $onclickFunction = "onclick=\"edit('$divID', this, 5)\"";

      #$Item =~ s/\n/<br \/>/g;

      my $return = qq~<div $onmouseoutFunction $onmouseoverFunction $onclickFunction id="$spanID">$Item</div>~;
      #return qq~<span id="$spanID">$Item</span>~;
      #return qq~<div id="$divID"><div $onmouseoutFunction $onmouseoverFunction $onclickFunction id="$innerID">$Item</div></div>~;
   }
}



=head2 getEditableListGroup

Gets the html for on editable list group

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $ListGroupID - The list group to get updated
   3. $Name - The name of the list group

=item B<Returns :>

   1. $html - The html of the editable list group

=back

=cut

#############################################
sub getEditableListGroup {
#############################################
   my $self = shift;
   my $ListGroupID = shift;
   my $Name = shift;

   my $divID = "ListGroup$ListGroupID";
   my $onmouseoutFunction = "onmouseout=\"showAsEditable('$divID', true)\"";
   my $onmouseoverFunction = "onmouseover=\"showAsEditable('$divID', false)\"";
   my $onclickFunction = "onclick=\"edit('$divID', this, 1)\"";

   my  $return = qq~<span $onmouseoutFunction $onmouseoverFunction $onclickFunction>$Name</span>~;

   return $return;
}

=head2 getEditableStatusSet

Gets the html for on editable status set

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $ListGroupID - The list group to get updated
   3. $Name - The name of the list group

=item B<Returns :>

   1. $html - The html of the editable list group

=back

=cut

#############################################
sub getEditableStatusSet {
#############################################
   my $self = shift;
   my $StatusSetID = shift;
   my $StatusSet = shift;

   my $divID = "StatusSet$StatusSetID";
   my $onmouseoutFunction = "onmouseout=\"showAsEditable('$divID', true)\"";
   my $onmouseoverFunction = "onmouseover=\"showAsEditable('$divID', false)\"";
   my $onclickFunction = "onclick=\"edit('$divID', this, 1)\"";

   my  $return = qq~<span $onmouseoutFunction $onmouseoverFunction $onclickFunction>$StatusSet</span>~;

   return $return;
}


=head2 updateListItem

Updates a ListItem

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $ListItemid - The list item to get updated
   3. $Name - The name to change the list item to

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub updateListItem {
#############################################
   my $self = shift;
   my $ListItemID = shift;
   my $value = shift;

   $self->{Debugger}->debug("in ListCentral::Editor->updateListItem with $value");

   if(! $self->{cgi}->{Field} =~ m/Description/){
      $value =~ s/\n/ /g;
   }

   my $ListItemObj = $self->{DBManager}->getTableObj("ListItem");
   $ListItemObj->update($self->{cgi}->{Field}, $value, $ListItemID);

   my $return;
   if($self->{cgi}->{Field} eq "Name"){
      $return = $self->getEditableListItem($ListItemID, $value);
   }else{
      $return = $self->getEditableListItemDescription($ListItemID, $value);
   }

   return $return;
}

=head2 updateListGroup

Updates a List Group

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $ListGroupid - The list item to get updated
   3. $Name - The name to change the list group to

=item B<Returns :>

   1. $html - The html of the returning editable list group

=back

=cut

#############################################
sub updateListGroup {
#############################################
   my $self = shift;
   my $ListGroupID = shift;
   my $Name = shift;

   $self->{Debugger}->debug("in ListCentral::Editor->updateListGroups with $Name");

   my $ListGroupObj = $self->{DBManager}->getTableObj("ListGroup");
   $ListGroupObj->update('Name', $Name, $ListGroupID);

   my $return = $self->getEditableListGroup($ListGroupID, $Name);

   return $return;
}

=head2 updateStatusSet

Updates a Status set

=over 

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $StatusSetID - The Status Set to change
   3. $StatusSet - The comma separated satus set

=item B<Returns :>

   1. $html - The html of the returning editable status set

=back

=cut

#############################################
sub updateStatusSet {
#############################################
   my $self = shift;
   my $StatusSetID = shift;
   my $StatusSet = shift;

   $self->{Debugger}->debug("in ListCentral::Editor->updateStatusSet $StatusSetID");

   my $ListItemStatusObj = $self->{DBManager}->getTableObj("ListItemStatus");
   my @NewStatuses = split(/,/, $StatusSet);
   my $OldStatuses = $ListItemStatusObj->get_with_restraints("StatusSet = $StatusSetID");

   my $NumberOfOldStatuses = 0; 
   foreach my $k(keys %{$OldStatuses}) {
      $NumberOfOldStatuses++;
   }
   my $NumberOfNewStatuses = scalar(@NewStatuses);
   $self->{Debugger}->debug("# New: $NumberOfNewStatuses, # Old: $NumberOfOldStatuses");

   if($NumberOfOldStatuses == $NumberOfNewStatuses){
      $self->{Debugger}->debug("new == old");
      # Same number of old and new statuses
      my $count = 0;
      foreach my $OldListStatusID(sort keys %{$OldStatuses}) {
         $self->{Debugger}->debug("old: $OldStatuses->{$OldListStatusID}->{Name}, new: $NewStatuses[$count]");
         if($OldStatuses->{$OldListStatusID}->{Name} ne $NewStatuses[$count]){
            my $status = $NewStatuses[$count];
            $status =~ s/^\s+//;
            $status =~ s/\s+$//;
            $ListItemStatusObj->update("Name", $status, $OldListStatusID);
            
         }
         $count++;
      }
   }elsif($NumberOfOldStatuses < $NumberOfNewStatuses){
      $self->{Debugger}->debug("new > old");
      # More new statuses - will have to insert
      my $count = 0;
      foreach my $OldListStatusID(sort keys %{$OldStatuses}) {
         if($OldStatuses->{$OldListStatusID}->{Name} ne $NewStatuses[$count]){
            my $status = $NewStatuses[$count];
            $status =~ s/^\s+//;
            $status =~ s/\s+$//;
            $ListItemStatusObj->update("Name", $status, $OldListStatusID);
            
         }
         $count++;
      }
      while($count < $NumberOfNewStatuses){
         my %Status;
         my $status = $NewStatuses[$count];
         $status =~ s/^\s+//;
         $status =~ s/\s+$//;
         $Status{"ListItemStatus.Status"} = 1;
         $Status{"ListItemStatus.Name"} = $status;
         $Status{"ListItemStatus.StatusSet"} = $StatusSetID;
         $Status{"ListItemStatus.UserID"} = $self->{UserManager}->{ThisUser}->{ID};

         my $ListItemStatusID = $ListItemStatusObj->store(\%Status);

         $count++;
      }

   }elsif($NumberOfOldStatuses > $NumberOfNewStatuses){
      $self->{Debugger}->debug("new < old");
      # More old statuses - will have to delete
      my $count = 0;
      foreach my $OldListStatusID(sort keys %{$OldStatuses}) {
         if($count < $NumberOfNewStatuses){
            if($OldStatuses->{$OldListStatusID}->{Name} ne $NewStatuses[$count]){
               my $status = $NewStatuses[$count];
               $status =~ s/^\s+//;
               $status =~ s/\s+$//;
               $ListItemStatusObj->update("Name", $status, $OldListStatusID);
               
            }
         }else{
            $ListItemStatusObj->update("Status", 0, $OldListStatusID);
         }
         $count++;
      }
   }

   my $return = $self->getEditableStatusSet($StatusSetID, $StatusSet);

   return $return;
}


=head2 updateList

Updates a List Name -> not currently used

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $Listid - The list item to get updated

=item B<Returns :>

   1. $html - The html of the editable list name

=back

=cut

#############################################
sub updateList {
#############################################
   my $self = shift;
   my $ListID = shift;
   my $Name = shift;

   $self->{Debugger}->debug("in ListCentral::Editor->updateList");

   my $ListObj = $self->{DBManager}->getTableObj("List");
   $ListObj->update('Name', $Name, $ListID);

   my $return = $self->getEditableListName($ListID, $Name, 0);

   return $return;
}


1;

=head1 AUTHOR INFORMATION

   Author: Brahmina Burgess 
   Created: 11/17/2008

=head1 BUGS

   Not known

=cut
