package Lists::DB::ListItem;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::ListItem 
##########################################################

=head1 NAME

   Lists::DB::ListItem.pm

=head1 SYNOPSIS

   $ListItem = new Lists::DB::ListItem($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the ListItem table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::ListItem::init");

   my @Fields = ("CreateDate", "PlaceInOrder", "ListItemStatusID", "ListID", "Description", "Name", "LinkID", 
                 "ImageID", "AmazonID", "CCImageID", "EmbedID", "DateID");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ("Description");
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;

   $self->{StatusField} = "ListItemStatusID";
}

=head2 getTopListItems

Given a list ID returns the top X List Items

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListItem object
   2. $ListID - The List ID
   3. $Query - Optional Query to aid with ordering

=item B<Returns: >

   1. $ListItems - UL of top list items requested

=back

=cut

#############################################
sub getTopListItems {
#############################################
   my $self = shift;
   my $List = shift;
   my $Query = shift;

   $self->{Debugger}->debug("in Lists::DB::ListItem::getTopListItems with ListID $List->{ID} and query: $Query");
   
   my $limit = $Lists::SETUP::CONSTANTS{'NUMBER_OF_TOP_LIST_ITEMS_BRIEF_LIST_VIEW'};

   my $ListItems;
   if($Query){
      $Query =~ s/^\s+//;
      $Query =~ s/\s+$//;
      my @search_terms = split (/\s/, $Query);
      
      my $OneWordQuery = 0;
      if(scalar(@search_terms) == 1){
         $OneWordQuery = 1;
      }else{
         my $termCount = 0;
         foreach my $term (@search_terms) {
            #if(length($term) > 2){
            if($term ne "a" && $term ne "the" && $term ne "and" && $term ne "in" && $term ne "it" && $term ne "to" && $term ne "for"){
               $termCount++;
            }
         }
         if($termCount == 1){
            $OneWordQuery = 1;
         }
      }
   
      my $AndWhereClauseListItem = "";
      my $OrWhereClauseListItem = "";
      if(!$OneWordQuery){
         foreach my $term (@search_terms) {
            $AndWhereClauseListItem .= "(ListItem.Name LIKE \"$term%\" OR ListItem.Name LIKE \"% $term%\") AND";
            $OrWhereClauseListItem .= "(ListItem.Name LIKE \"$term%\" OR ListItem.Name LIKE \"% $term%\") OR";
         }
      }else{
         $AndWhereClauseListItem .= "(ListItem.Name LIKE \"$Query%\" OR ListItem.Name LIKE \"% $Query%\") ";
      }
      
      $AndWhereClauseListItem =~ s/ AND$//;
      $OrWhereClauseListItem =~ s/ OR$//;
   
      my $sql = "SELECT * 
                FROM $Lists::SETUP::DB_NAME.ListItem 
                WHERE ListID = $List->{ID}
                      AND ListItemStatusID > 0 ";
      my %results;
      my $count = 0;
      if($Query){
         $sql .= "AND $AndWhereClauseListItem";
         $sql .= "LIMIT $limit";
         $count = $self->runSQLSelect($sql, $count, \%results);
   
         if($count < $limit && !$OneWordQuery){
            $sql = "SELECT * 
                    FROM $Lists::SETUP::DB_NAME.ListItem 
                    WHERE ListID = $List->{ID}
                          AND ListItemStatusID > 0 ";
   
            $sql .= "AND $OrWhereClauseListItem";
            $sql .= "LIMIT $limit";
            $count = $self->runSQLSelect($sql, $count, \%results);
         }
      }else{
         $sql .= "LIMIT $limit";
         $count = $self->runSQLSelect($sql, $count, \%results);
      }
      $ListItems = \%results;
   }

   if(scalar keys %{$ListItems} <6){
      my $MoreListItems = $self->get_with_restraints("ListID = $List->{ID}");
   
      foreach my $ID(keys %{$MoreListItems}){
         $ListItems->{$ID} = $MoreListItems->{$ID};
      }
   }

   if($List->{Ordering} eq "d"){
      my $sortOrder = 1;
      foreach my $ID(sort {$ListItems->{$b}->{PlaceInOrder} <=> $ListItems->{$a}->{PlaceInOrder}} keys %{$ListItems}) {
         if($ListItems->{$ID}->{AmazonID}){
            $ListItems->{$ID}->{SortOrder} = $sortOrder;
            $sortOrder++;
         }elsif($ListItems->{$ID}->{ImageID}){
            $ListItems->{$ID}->{SortOrder} = $sortOrder;
            $sortOrder++;
         }elsif($ListItems->{$ID}->{CCImageID}){
            $ListItems->{$ID}->{SortOrder} = $sortOrder;
            $sortOrder++;
         }
      }
      foreach my $ID (sort {$ListItems->{$b}->{PlaceInOrder} <=> $ListItems->{$a}->{PlaceInOrder}} keys %{$ListItems}) {
         if(! $ListItems->{$ID}->{SortOrder}){
            $ListItems->{$ID}->{SortOrder} = $sortOrder;
            
         }
      }
   }else{
      my $sortOrder = 1;
      foreach my $ID(sort {$ListItems->{$a}->{PlaceInOrder} <=> $ListItems->{$b}->{PlaceInOrder}} keys %{$ListItems}) {
         if($ListItems->{$ID}->{AmazonID}){
            $ListItems->{$ID}->{SortOrder} = $sortOrder;
            $sortOrder++;
         }elsif($ListItems->{$ID}->{ImageID}){
            $ListItems->{$ID}->{SortOrder} = $sortOrder;
            $sortOrder++;
         }elsif($ListItems->{$ID}->{CCImageID}){
            $ListItems->{$ID}->{SortOrder} = $sortOrder;
            $sortOrder++;
         }
      }
      foreach my $ID (sort {$ListItems->{$a}->{PlaceInOrder} <=> $ListItems->{$b}->{PlaceInOrder}} keys %{$ListItems}) {
         if(! $ListItems->{$ID}->{SortOrder}){
            $ListItems->{$ID}->{SortOrder} = $sortOrder;
            
         }
      }
   }
   

   return $ListItems;
}

=head2 changeListItemsStatusToNone

Called when a Status Set is deleted, all list items that are assigned within the given StatusSet are
assigned the ListItemStatusIS 1 -> ""

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $StatusSet - The ListGroup ID
   3. $UserID - To be sure, the UserID of the owner of the ListGroup

=back

=cut

#############################################
sub changeListItemsStatusToNone {
#############################################
   my $self = shift;
   my $StatusSet = shift;
   my $UserID = shift;
   my $ListItemStatusObj = shift;

   $self->{Debugger}->debug("in Lists::DB::List->ListchangeListGroupToUncategorized with $StatusSet, $UserID");

   my $ListItemStatus = $ListItemStatusObj->get_with_restraints("StatusSet = $StatusSet");

   foreach my $ListItemStatusID(keys %{$ListItemStatus}) {
      my $sql = "UPDATE $Lists::SETUP::DB_NAME.ListItem INNER JOIN $Lists::SETUP::DB_NAME.List on ListItem.ListID = List.ID
                 SET ListItemStatusID = 1 
                 WHERE List.UserID = $UserID AND 
                       ListItem.ListItemStatusID = $ListItemStatusID";
      my $stm = $self->{dbh}->prepare($sql);
      if ($self->{dbh}->do($sql)) {
         # Good Stuff
      }else {
         $self->{Debugger}->throwNotifyingError("ERROR: with List UPDATE::: $sql\n");
      }
   }
}

=head2 getListItemsSample

Gets the samples of list items for the list corresponding to the reference 
to a ListHash passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListItem object
   2. $ListHash - Field name to be updated
   3. $ImageObj - Reference to an Image DB Object from the DBManager
   4. $LinkObj - Reference to an Link DB Object from the DBManager
   5. $Query - Optional query being sent by the user on search

=item B<Returns :>

   1. $ListItemSamplesHTML - The HTML of the list samples

=back

=cut

#############################################
sub getListItemsSample {
#############################################
   my $self = shift;
   my $ListHash = shift;
   my $DBManager = shift;
   my $UserManager = shift;
   my $Query = shift;

   $self->{Debugger}->debug("in Lists::DB::ListItem::getListItemsSample -> $ListHash->{Name}");

   my $Items = $self->getTopListItems($ListHash, $Query);

   my @SampleSpaces;
   my $CurrentSpace = 0;
   my $ListItemsInSubList = 0;
   foreach my $ItemID(sort{$Items->{$a}->{SortOrder} <=> $Items->{$b}->{SortOrder}} keys %{$Items}) {
      if($CurrentSpace >= $Lists::SETUP::CONSTANTS{'LIST_ITEM_SAMPLE_SPACES'}){
         $self->{Debugger}->debug("--- leaving forech with CurrentSpace: $CurrentSpace, Lists::SETUP::LIST_ITEM_SAMPLE_SPACES: $Lists::SETUP::LIST_ITEM_SAMPLE_SPACES");
         last;
      }

      my $link; my $imgsrc;
      my $listName = $self->getListingSampleListName($Items->{$ItemID}->{Name});
      if($Items->{$ItemID}->{LinkID}){
         my $LinkObj = $DBManager->getTableObj("Link");
         my $Link = $LinkObj->get_by_ID($Items->{$ItemID}->{LinkID});
         $link = $Link->{Link};
      }
      
      if($Items->{$ItemID}->{AmazonID}){
         my $AmazonLinksObj = $DBManager->getTableObj("AmazonLinks");
         my $AmazonLinks = $AmazonLinksObj->get_by_ID($Items->{$ItemID}->{AmazonID});

         my $Amazon = new Lists::Utilities::Amazon(Debugger => $self->{Debugger}, DBManager => $self->{DBManager}, 
                                                      UserManager => $self->{UserManager});
         my $country = $Amazon->getCountryByRemoteIP();
         $imgsrc = $AmazonLinks->{$country . "Image"};
         $link = $AmazonLinks->{$country};
         
         
         if($link eq ""){
            my @Countries = ("US", "CA", "UK");
            foreach my $c(@Countries) {
               if($link eq ""){
                  $link = $AmazonLinks->{$c};
                  $imgsrc = $AmazonLinks->{$c . "Image"};
               }
            }
         }
      }elsif($Items->{$ItemID}->{ImageID}){
         my $ImageObj = $DBManager->getTableObj("Image");
         my $Image = $ImageObj->get_by_ID($Items->{$ItemID}->{ImageID});
         $imgsrc = $Lists::SETUP::USER_CONTENT_PATH . "/" . $ListHash->{UserDir} . "/" . 
                           $Image->{ID} . "S." . $Image->{Extension};
         $link = $ListHash->{ListURL};
      }elsif($Items->{$ItemID}->{CCImageID}){
         my $CCImageObj = $DBManager->getTableObj("CCImage");
         my $CCImage = $CCImageObj->get_by_ID($Items->{$ItemID}->{CCImageID});

         $imgsrc = $CCImage->{Image};
         $link = $ListHash->{ListURL};
      }

      if($imgsrc){
         $SampleSpaces[$CurrentSpace] = qq~<ul class="ListItemsSummaryImages"><li><div class="ListingListNameOverImage"><a href="$link" target="_new">$listName</a></div>~;
         $SampleSpaces[$CurrentSpace] .= qq~<div class="ListItemsSummaryImagesDiv"><a href="$link"><img src="$imgsrc" alt="$Items->{$ItemID}->{Name}" class="ListingsImage" /></a></div> </li></ul>~;
         $CurrentSpace++;
      }else{
         # No images
         $self->{Debugger}->debug("ListItemsInSubList: $ListItemsInSubList - $Items->{$ItemID}->{Name}");
         if($ListItemsInSubList == 0){
            $SampleSpaces[$CurrentSpace] = qq~<ul class="ListItemsSummary">~;
         }

         if($link){
            $SampleSpaces[$CurrentSpace] .= qq~<li><a href="$link" target="_new">$Items->{$ItemID}->{Name}</a></li>~;
         }else{
            $SampleSpaces[$CurrentSpace] .= qq~<li>$Items->{$ItemID}->{Name}</li>~;
         }

         $ListItemsInSubList++;
         if($ListItemsInSubList == 3){
            $SampleSpaces[$CurrentSpace] .= qq~</ul>~;
            $ListItemsInSubList = 0;
            $CurrentSpace++;
         }
      }     
   }

   my $samples = ""; 
   foreach my $list(@SampleSpaces) {
      if($list !~ m/<\/ul>$/){
         $list .= "</ul>";
      }
      $samples .= $list;
   }

   if($samples eq ""){
      $samples = qq~<ul class="ListItemsSummary"><li>no list items yet</li></ul>~;
   }
   return $samples;
}

=head2 getListItemsInfo

Given a refernce to a hash with list items info, gets the other list item info needed 
foreach list item and adds it to the hash

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $ListItems - Reference to a hash with the list items in it
   3. $List - Reference to a hash with the parent list infor

=back

=cut

#############################################
sub getListItemsInfo {
#############################################
   my $self = shift;
   my $ListItems = shift;
   my $List = shift;
   my $Editor = shift;

   $self->{Debugger}->debug("in Lists::ListManager->getListItemsInfo");

   my $ImageObj = $self->{DBManager}->getTableObj("Image");
   my $LinkObj = $self->{DBManager}->getTableObj("Link");

   use Lists::Utilities::Amazon;
   my $Amazon = new Lists::Utilities::Amazon(DBManager => $self->{DBManager}, Debugger => $self->{Debugger},
                                                UserManager => $self->{UserManager});

   foreach my $ListItemID(sort{$ListItems->{$a}->{PlaceInOrder} <=> $ListItems->{$b}->{PlaceInOrder}} keys %{$ListItems}) {
      if($ListItems->{$ListItemID}->{ListItemName}){
         next;
      }
      $self->{Debugger}->debug("ListItem: $ListItemID - $ListItems->{$ListItemID}->{Name}");

      # Get the link if there is one   
      if($ListItems->{$ListItemID}->{LinkID}){
         my $Link = $LinkObj->get_by_ID($ListItems->{$ListItemID}->{LinkID});
         $ListItems->{$ListItemID}->{ListItemName} = qq~<a href="$Link->{Link}" target="_new">$ListItems->{$ListItemID}->{Name}</a>~;  
      }elsif($ListItems->{$ListItemID}->{AmazonID}){
         my $AmazonLink = $Amazon->getAmazonLink($ListItems->{$ListItemID}->{AmazonID});
         $ListItems->{$ListItemID}->{ListItemName} = qq~<a href="$AmazonLink" target="_new">$ListItems->{$ListItemID}->{Name}</a>~;  
      }

      # Get the ListItem Name and Description, editable if necessary
      # Use the link over the editable list name
      if($self->{UserManager}->{ThisUser}->{ID} == $List->{UserID}){
         if(! $ListItems->{$ListItemID}->{ListItemName}){
            $ListItems->{$ListItemID}->{ListItemName} = $Editor->getEditableListItem($ListItemID, $ListItems->{$ListItemID}->{Name});
         }
         
         $ListItems->{$ListItemID}->{ListItemDescription} = $Editor->getEditableListItemDescription($ListItemID, $ListItems->{$ListItemID}->{Description});

         if($ListItems->{$ListItemID}->{ListItemDescription}){
            my $divID = "ListItem" . $ListItemID . "Description";
            $ListItems->{$ListItemID}->{ListItemDescription} = qq~<div id="$divID" class="noneditable">
                                 	    $ListItems->{$ListItemID}->{ListItemDescription}
                                 	</div>~;
         }
      }elsif(!$ListItems->{$ListItemID}->{ListItemName}){
         $ListItems->{$ListItemID}->{ListItemName} = $ListItems->{$ListItemID}->{Name};
	 $ListItems->{$ListItemID}->{ListItemDescription} = $ListItems->{$ListItemID}->{Description};
      }else{
         $ListItems->{$ListItemID}->{ListItemDescription} = $ListItems->{$ListItemID}->{Description};
      }

      # Set the divID
      my $divID = "ListItem$ListItemID";
      $ListItems->{$ListItemID}->{divID} = $divID;      
   }
}

=head2 getListingSampleListName

Does the shortening of the list name with ... for the listing pages if the list name is
longer then SETUP::CONSTANTS{'SAMPLE_LIST_NAME_LIMIT'}

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $ListItems - Reference to a hash with the list items in it
   3. $List - Reference to a hash with the parent list infor

=back

=cut

#############################################
sub getListingSampleListName {
#############################################
   my $self = shift;
   my $listName = shift;

   $self->{Debugger}->debug("List Item name length for sample: " . length($listName));

   $listName =~ s/'/&#39;/g;
   if(length($listName) > ($Lists::SETUP::CONSTANTS{'SAMPLE_LIST_NAME_WITH_IMAGES_LIMIT'} + 1)){
      $listName = substr($listName, 0, $Lists::SETUP::CONSTANTS{'SAMPLE_LIST_NAME_WITH_IMAGES_LIMIT'}) . "...";
   }

   return $listName;
}

=head2 getListItems

Get ListItems to be displayed in the normal view, includes paging

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListItem object
   2. $where_clause - the where clause to be used on select, starting with "WHERE "

=item B<Returns: >

   1. $ListItem - Reference to a hash with the ListItem data

=back

=cut

#############################################
sub getListItems {
#############################################
   my $self = shift;
   my $List = shift;
   my $page = shift;

   $self->{Debugger}->debug("in Lists::DB::ListItem::getListItems with $List->{ID}");

   if(! $page){
      $page = 1;
   }  

   # Determine if the list has many images
   my $sql = "SELECT COUNT(ImageID) as ImageCount, COUNT(CCImageID) as CCImageCount,
                      Count(EmbedID) as EmbedCount, COUNT(AmazonID) as AmazonCount
              FROM $Lists::SETUP::DB_NAME.ListItem 
              WHERE ListID = $List->{ID} AND ListItemStatusID > 0";
   my $extraCount = 0;
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $extraCount += $hash->{ImageCount};
         $extraCount += $hash->{CCImageCount};
         $extraCount += $hash->{EmbedCount};
         $extraCount += $hash->{AmazonCount};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with ListItem SELECT: $sql - $DBI::errstr");
   }

   my $limit; my $start;
   if($extraCount > $Lists::SETUP::CONSTANTS{'IMAGE_LIST_ITEM_LIMIT'}){
      $start = ($page - 1) * $Lists::SETUP::CONSTANTS{'IMAGE_LIST_ITEM_LIMIT'}; 
      $limit = $Lists::SETUP::CONSTANTS{'IMAGE_LIST_ITEM_LIMIT'};
   }else{
      $start = ($page - 1) * $Lists::SETUP::CONSTANTS{'LIST_ITEM_LIMIT_PER_PAGE'}; 
      $limit = $Lists::SETUP::CONSTANTS{'LIST_ITEM_LIMIT_PER_PAGE'};
   }

   my $ordering = "ASC";
   if($List->{Ordering} eq "d"){
      $ordering = "DESC";
   }

   my %ListItem; 
   my $SortOrder = 1;
   my $sql = "SELECT * 
              FROM $Lists::SETUP::DB_NAME.ListItem 
              WHERE ListID = $List->{ID} AND ListItemStatusID > 0 
              ORDER BY ListItemStatusID ASC, PlaceInOrder $ordering
              LIMIT $start, $limit";
   $self->{Debugger}->debug("$sql");
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $ListItem{$hash->{ID}} = $hash;
         $ListItem{$hash->{ID}}->{SortOrder} = $SortOrder;
         $SortOrder++;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with ListItem SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   my $More = 0;
   my $sql = "SELECT COUNT(ID) AS ListItemCount
              FROM $Lists::SETUP::DB_NAME.ListItem 
              WHERE ListID = $List->{ID} AND ListItemStatusID > 0 ";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         if($hash->{ListItemCount} > ($start + $limit)){
            $More = 1;
         }
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with ListItem SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;


   return (\%ListItem, $More);
}


=head2 getMinPlaceInOrder

Get ListItem entries resulting from the select performed using the where clause passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListItem object
   2. $where_clause - the where clause to be used on select, starting with "WHERE "

=item B<Returns: >

   1. $ListItem - Reference to a hash with the ListItem data

=back

=cut

#############################################
sub getMinPlaceInOrder {
#############################################
   my $self = shift;
   my $ListID = shift;
   my $ListItemStatusID = shift;

   $self->{Debugger}->debug("in Lists::DB::ListItem::GetMinPlaceInOrder with ListID: $ListID, and ListItemStatusID: $ListItemStatusID");

   my $MinPlaceInOrder = 0;
   my $sql = "SELECT MIN(PlaceInOrder) AS theMin
              FROM $Lists::SETUP::DB_NAME.ListItem 
              WHERE ListID = $ListID AND ListItemStatusID = $ListItemStatusID";

   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $MinPlaceInOrder = $hash->{"theMin"};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with ListItem SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   $self->{Debugger}->debug("ListItem::getMinPlacInOrder returning $MinPlaceInOrder after:\n$sql");

   return $MinPlaceInOrder;
}

=head2 getMaxPlaceInOrder

Get ListItem entries resulting from the select performed using the where clause passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListItem object
   2. $where_clause - the where clause to be used on select, starting with "WHERE "

=item B<Returns: >

   1. $ListItem - Reference to a hash with the ListItem data

=back

=cut

#############################################
sub getMaxPlaceInOrder {
#############################################
   my $self = shift;
   my $ListID = shift;
   my $ListItemStatusID = shift;

   $self->{Debugger}->debug("in Lists::DB::ListItem::getMaxPlaceInOrder with ListID: $ListID, and ListItemStatusID: $ListItemStatusID");

   my $LastPlaceInOrder;
   my $sql = "SELECT MAX(PlaceInOrder) AS MPIO 
              FROM $Lists::SETUP::DB_NAME.ListItem 
              WHERE ListID = $ListID AND ListItemStatusID = $ListItemStatusID";
   $self->{Debugger}->debug("$sql");
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $LastPlaceInOrder = $hash->{MPIO};
         $self->{Debugger}->debug("MaxPlaceInOrder --> $hash->{MPIO}, $LastPlaceInOrder");
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with ListItem SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   if(!$LastPlaceInOrder){
      $LastPlaceInOrder = 0;
   }

   return $LastPlaceInOrder;
}

=head2 clearListItemExtras

Clears the extras off a list item (AmazonID, ImageID, EmbedID, & CCImageID)

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListItem object
   2. $ListItemID - The ListItem ID
   3. $OneToKeep - Optional Won't clear this one

=back

=cut

#############################################
sub clearListItemExtras {
#############################################
   my $self = shift;
   my $ListItem = shift;
   my $OneToKeep = shift;

   $self->{Debugger}->debug("in Lists::DB::ListItem::clearListItemExtras with $ListItem->{ID}, $OneToKeep");
   
   my @Extras = ("AmazonID", "ImageID", "EmbedID", "CCImageID");

   foreach my $field(@Extras) {
      if($field ne $OneToKeep){
         if($ListItem->{$field}){
            $self->update($field, "", $ListItem->{ID});
         }
      }
   }
}


1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 21/1/2008

=head1 BUGS

   Not known

=cut



