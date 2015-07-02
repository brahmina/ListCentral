package ListCentral::DB::List;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;

use ListCentral::SETUP;
use ListCentral::Utilities::Date;

##########################################################
# ListCentral::DB::List 
##########################################################

=head1 NAME

   ListCentral::DB::List.pm

=head1 SYNOPSIS

   $List = new ListCentral::DB::List($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the List table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::List::init");

   my @Fields = ("Description", "CreateDate", "Public", "Status", "UserID", "ListGroupID", 
                 "Name", "StatusSet", "ListTypeID", "Ordering");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ("Description");
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate", "LastActiveDate");
   $self->{DateFields} = \@DateFields;
}

=head2 changeListGroupToUncategorized

Called when a List Group is deleted, all lists that are categorized under the given
ListGroup are changed to be Uncategorized

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $ListGroupID - The ListGroup ID
   3. $UserID - To be sure, the UserID of the owner of the ListGroup

=back

=cut

#############################################
sub changeListGroupToUncategorized {
#############################################
   my $self = shift;
   my $ListGroupID = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::DB::List->changeListGroupToUncategorized with $ListGroupID, $UserID");

   my $sql = "UPDATE $ListCentral::SETUP::DB_NAME.List SET ListGroupID = 1 WHERE UserID = $UserID AND ListGroupID = $ListGroupID";
   my $stm = $self->{dbh}->prepare($sql);
   if ($self->{dbh}->do($sql)) {
      # Good Stuff
   }else {
      $self->{Debugger}->throwNotifyingError("ERROR: with List UPDATE::: $sql\n");
   }
}

=head2 getPopularLists

Gets the most popular lists

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $where_clause - the where clause to be used on select, starting with "WHERE "

=item B<Returns: >

   1. $List - Reference to a hash with the List data

=back

=cut

#############################################
sub getPopularLists_ {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::DB::List::getPopularLists $UserID");

   my $limit;
   my $UserClause = "";
   if($UserID){
      $UserClause = "AND UserID = $UserID";
      $limit = $ListCentral::SETUP::POPULAR_LIST_BREAKDOWN_ROWS;
   }else{
      $limit = $ListCentral::SETUP::POPULAR_LIST_REPORT_ROWS;
   }

   my %List;
   my $sql = "SELECT List.*, ListPoints.MostRecent, ListPoints.24Hours, ListPoints.72Hours, ListPoints.LastWeek,
		     ListPoints.LastMonth, ListPoints.LastYear, ListPoints.AllTime, User.Username
              FROM $ListCentral::SETUP::DB_NAME.List, $ListCentral::SETUP::DB_NAME.User, $ListCentral::SETUP::DB_NAME.ListPoints
              WHERE List.UserID = User.ID AND User.Status > 0 
                    AND List.Status > 0 AND Public = 1 $UserClause
                    AND ListPoints.ListID = List.ID
              ORDER BY 24Hours DESC
              LIMIT $limit";
              
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $List{$hash->{ID}} = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with List SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   return \%List;
}

=head2 getListURL

Given a list ID, returns the lists url

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $ListID - The ID of the list t

=item B<Returns: >

   1. $URL - The url of the list

=back

=cut

#############################################
sub getListURL {
#############################################
   my $self = shift;
   my $List = shift;
   my $ListGroup = shift;

   $self->{Debugger}->debug("in ListCentral::DB::List::getListURL ID: $List->{ID}, Name: $List->{Name}, Group: $ListGroup");

   if(! $List->{ID}){
      return "";
   }

   my $ListNameURL = $List->{Name};
   $ListNameURL =~ s/\s/_/g;
   $ListNameURL =~ s/[^a-z0-9_-]//ig;
   $ListNameURL = lc($ListNameURL);
   
   $ListGroup =~ s/\s/_/g;
   $ListGroup =~ s/[^a-z0-9_-]//ig;
   $ListGroup = lc($ListGroup);

   my $URL = qq~/list/$ListGroup/$ListNameURL/$List->{UserID}/$List->{ID}/lists.html~;

   return $URL;
}


=head2 getListFavCount

Returns the count of how many lists the list has been added to

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $ListID - The ID of the list 

=item B<Returns: >

   1. $Count - The list fav count

=back

=cut

#############################################
sub getListFavsCount {
#############################################
   my $self = shift;
   my $ListID = shift;

   $self->{Debugger}->debug("in ListCentral::DB::List::getListFavCount $ListID");

   # TODO - List Favourites
   # When Favorite lists is figured out, calculate count here
   # If a list is deleted, and also on someones favs, tell user it has been deleted by it's owner
   #   and give them to option to remove it from their favs

   return 0;
}

=head2 getPopularLists

Gets the top lists for the front page

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $page - The page we are on

=item B<Returns: >

   1. $Lists - Reference to a hash with the Lists data

=back

=cut

#############################################
sub getPopularLists {
#############################################
   my $self = shift;
   my $page = shift;

   $self->{Debugger}->debug("in ListCentral::DB::List::getPopularLists with page: $page");

   my $limit = $ListCentral::SETUP::CONSTANTS{'LISTING_ROWS_LIMIT'};
   my $start = 0;
   if($page > 1){
      $start = ($limit * $page) - $limit;
   }

   my %List;
   my $sql = "SELECT List.*, ListPoints.ListPoints, ListPoints.RankingHN, ListPoints.RankingReddit, 
                     ListPoints.Activity, ListPoints.DateMadePublic
              FROM $ListCentral::SETUP::DB_NAME.List, $ListCentral::SETUP::DB_NAME.ListPoints, $ListCentral::SETUP::DB_NAME.User
              WHERE List.UserID = User.ID AND User.Status > 0 
                    AND List.ID = ListPoints.ListID
                    AND List.UserID != $ListCentral::SETUP::ABOUT_USER_ACCOUNT
                    AND List.Status > 0 AND List.Public = 1 AND ListPoints.Status > 0
              ORDER BY RankingReddit DESC, ListPoints.DateMadePublic DESC
              LIMIT $start, $limit";
   $self->{Debugger}->debug("SQL: $sql");
   my $count = 1;          
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $List{$hash->{ID}} = $hash;
         $List{$hash->{ID}}->{SearchOrder} = $count;
         $count++;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with List SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   return \%List;
}

=head2 getNewLists

Gets the top lists for the front page

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $page - The page we are on

=item B<Returns: >

   1. $Lists - Reference to a hash with the Lists data

=back

=cut

#############################################
sub getNewLists {
#############################################
   my $self = shift;
   my $page = shift;

   $self->{Debugger}->debug("in ListCentral::DB::List::getNewLists with page: $page");

   my $limit = $ListCentral::SETUP::CONSTANTS{'LISTING_ROWS_LIMIT'};
   my $start = 0;
   if($page > 1){
      $start = ($limit * $page) - $limit;
   }

   my %List;
   my $sql = "SELECT List.*, ListPoints.ListPoints, ListPoints.RankingHN, ListPoints.RankingReddit, 
                     ListPoints.Activity, ListPoints.DateMadePublic
              FROM $ListCentral::SETUP::DB_NAME.List, $ListCentral::SETUP::DB_NAME.ListPoints, $ListCentral::SETUP::DB_NAME.User
              WHERE List.UserID = User.ID AND User.Status > 0 
                    AND List.ID = ListPoints.ListID
                    AND List.UserID != $ListCentral::SETUP::ABOUT_USER_ACCOUNT
                    AND List.Status > 0 AND List.Public = 1 AND ListPoints.Status > 0
              ORDER BY ListPoints.DateMadePublic DESC, CreateDate DESC
              LIMIT $start, $limit";
   my $count = 1;          
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $List{$hash->{ID}} = $hash;
         $List{$hash->{ID}}->{SearchOrder} = $count;
         $count++;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with List SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   return \%List;
}

=head2 getActiveLists

Gets the top lists for the front page

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $page - The page we are on

=item B<Returns: >

   1. $Lists - Reference to a hash with the Lists data

=back

=cut

#############################################
sub getActiveLists {
#############################################
   my $self = shift;
   my $page = shift;

   $self->{Debugger}->debug("in ListCentral::DB::List::getActiveLists with page: $page");

   my $limit = $ListCentral::SETUP::CONSTANTS{'LISTING_ROWS_LIMIT'};
   my $start = 0;
   if($page > 1){
      $start = ($limit * $page) - $limit;
   }

   my %List;
   my $sql = "SELECT List.*, ListPoints.ListPoints, ListPoints.RankingHN, ListPoints.RankingReddit, 
                     ListPoints.Activity, ListPoints.DateMadePublic
              FROM $ListCentral::SETUP::DB_NAME.List, $ListCentral::SETUP::DB_NAME.ListPoints, $ListCentral::SETUP::DB_NAME.User
              WHERE List.UserID = User.ID AND User.Status > 0 
                    AND List.ID = ListPoints.ListID
                    AND List.UserID != $ListCentral::SETUP::ABOUT_USER_ACCOUNT
                    AND List.Status > 0 AND List.Public = 1 AND ListPoints.Status > 0
              ORDER BY ListPoints.Activity DESC, ListPoints.DateMadePublic DESC
              LIMIT $start, $limit";
   my $count = 1;          
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $List{$hash->{ID}} = $hash;
         $List{$hash->{ID}}->{SearchOrder} = $count;
         $count++;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with List SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   return \%List;
}

=head2 getActiveLists

Gets the top lists for the front page

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $page - The page we are on

=item B<Returns: >

   1. $Lists - Reference to a hash with the Lists data

=back

=cut

#############################################
sub getAllPublicLists {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::List::getAllPublicLists");

   my %Lists;
   my $sql = "SELECT List.*
              FROM $ListCentral::SETUP::DB_NAME.List, $ListCentral::SETUP::DB_NAME.User
              WHERE List.UserID = User.ID AND User.Status > 0
                    AND List.UserID != $ListCentral::SETUP::ABOUT_USER_ACCOUNT
                    AND List.Status > 0 AND List.Public = 1";
   $self->{Debugger}->debug("sql: $sql");
   my $count = 1;          
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $Lists{$hash->{ID}} = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with List SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   return \%Lists;
}


=head2 getTopListsCount

Gets the total amount of lists for the that lists of lists pages

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object

=item B<Returns: >

   1. $Lists - Reference to a hash with the Lists data

=back

=cut

#############################################
sub getListsCount {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::List::getListsCount");

   my $Count = 0;
   my $sql = "SELECT COUNT(List.ID) AS Count
              FROM $ListCentral::SETUP::DB_NAME.List, $ListCentral::SETUP::DB_NAME.User
              WHERE List.UserID = User.ID AND User.Status > 0 
                    AND List.UserID != $ListCentral::SETUP::ABOUT_USER_ACCOUNT
                    AND List.Status > 0 AND List.Public = 1";
              
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $Count = $hash->{Count};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with List SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   return $Count;
}

=head2 getRecentLists

Gets the total amount of lists for the top lists page

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object

=item B<Returns: >

   1. $Lists - Reference to a hash with the Lists data

=back

=cut

#############################################
sub getRecentLists {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::List::getRecentLists");

   my %Lists;
   my $sql = "SELECT List.*
              FROM $ListCentral::SETUP::DB_NAME.List, $ListCentral::SETUP::DB_NAME.User
              WHERE List.UserID = User.ID AND User.Status > 0  
                    AND List.Status > 0 && Public = 1
                    AND List.UserID != $ListCentral::SETUP::ABOUT_USER_ACCOUNT
              ORDER BY List.CreateDate DESC
              LIMIT $ListCentral::SETUP::CONSTANTS{'RECENT_LISTS_LIMIT'}";
   my $sortOrder = 1;
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $Lists{$hash->{ID}} = $hash;
         $Lists{$hash->{ID}}->{SortOrder} = $sortOrder;
         $sortOrder++;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with List SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   return \%Lists;
}

=head2 getListInfo

Pass hash ref of with limited list info, returns hash ref of full list info, 
including user name, x list items, formatted dates, ratings, # of favorited

Should be used for listing: search, tags, favourite lists

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListItemStatus object
   2. $HashRef - Keys of hash are List IDs
   3. $DBManager
   4. $UserManager
   5. $isListing - 1 if for a listings page, 0 otherwise

=item B<Returns: >

   1. $HashRef - Keys of hash are List IDs

=back

=cut

#############################################
sub getListInfo {
#############################################
   my $self = shift;
   my $ListHash = shift;
   my $DBManager = shift;
   my $UserManager = shift;
   my $isListings = shift;

   $self->{Debugger}->debug("in ListCentral::ListManager::getListInfo $ListHash->{ID}");

   if($ListHash->{ListName}){
      return;
   }

   my $UserObj = $DBManager->getTableObj("User"); 
   my $ListRatingsObj = $DBManager->getTableObj("ListRatings");
   my $ListTagsObj = $DBManager->getTableObj("ListTag");
   my $ListItemObj = $DBManager->getTableObj("ListItem");
   my $ListGroupObj = $DBManager->getTableObj("ListGroup");
   my $CommentObj = $DBManager->getTableObj("Comment");
   my $ListPointsObj = $DBManager->getTableObj("ListPoints");
   my $ImageObj = $DBManager->getTableObj("Image");
   my $LinkObj = $DBManager->getTableObj("Link");
   my $TagObj = $DBManager->getTableObj("Tag");

   $ListHash->{DescriptionParagraph} = $ListHash->{Description};

   $ListHash->{ListName} = $ListHash->{Name};
   # Shortened list name for the listings
   if(length($ListHash->{ListName}) > $ListCentral::SETUP::CONSTANTS{'MAX_LIST_NAME_LENGTH_LISTING'}){
      $ListHash->{ListName} = substr ($ListHash->{ListName}, 0, ($ListCentral::SETUP::CONSTANTS{'MAX_LIST_NAME_LENGTH_LISTING'} - 2)) . "...";
   }

   # The User Name
   if($ListHash->{UserID}){
      my $User = $UserObj->get_by_ID($ListHash->{UserID});
      $UserManager->getUserInfo($User);

      $ListHash->{UserURL} = $User->{UserURL};
      $ListHash->{Username} = $User->{Username};
      $ListHash->{AvatarDisplay} = $User->{AvatarDisplay};
      $ListHash->{UserDir} = $User->{UserDir};
   }else{
      # This case should not be happening
      $ListHash->{Username} = "Unknown";
      $ListHash->{UserURL} = "Unknown";
   }

   # List Group
   $ListHash->{ListGroup} = $ListGroupObj->get_field_by_ID("Name", $ListHash->{ListGroupID});

   $ListHash->{ListURL} = $self->getListURL($ListHash, $ListHash->{ListGroup});

   # The Ratings    
   my $clickable = 0;
   if($UserManager->{ThisUser}->{ID}){
      $clickable = 1;
   }
   ($ListHash->{ListRating}, $ListHash->{ListRatingText}) = $ListRatingsObj->getListRatingsHTML($ListHash->{ID}, $clickable);

   # Top x list items, if(cgi->{Query} order by ones that match query -> UL returned
   # isListings flag here because we only need samples if this is for a listings page
   if($isListings){
      $ListHash->{ItemsSample} = $ListItemObj->getListItemsSample($ListHash, $DBManager, $UserManager, $self->{cgi}->{Query});
   }

   # Dates Formatted
   $ListHash->{FormattedCreateDate} = ListCentral::Utilities::Date::getShortHumanFriendlyDate($ListHash->{CreateDate});
   if($ListHash->{Public}){
      $ListHash->{DateMadePublicFormatted} = ListCentral::Utilities::Date::getShortHumanFriendlyDate($ListHash->{DateMadePublic});
   }else{
      $ListHash->{DateMadePublicFormatted} = "private";
   }
   

   # Favorties
   #$ListHash->{FavoriteCount} = $self->getListFavsCount($ListHash->{ID});

   # Comment Count
   $ListHash->{CommentCount} = $CommentObj->getListCommentCount($ListHash->{ID});

   if($ListHash->{CommentCount} == 1){
      $ListHash->{CommentText} = "Comment";
   }else{
      $ListHash->{CommentText} = "Comments";
   }

   # Tags
   ($ListHash->{Tags}, $ListHash->{TagCount}, $ListHash->{StrippedTags}) = $TagObj->getListTags($ListHash->{ID}, $DBManager, 0);

   if(! $ListHash->{Public}){
      
      if($ListHash->{UserID} == $UserManager->{ThisUser}->{ID}){
         $ListHash->{ListPoints} = qq~<span class="Publishable">private list</span><br /><a href="$ListHash->{ListURL}?todo=PublishList&ListID=$ListHash->{ID}" class="PublishLink">publish</a>~;
      }else{
         $ListHash->{ListPoints} = "private list";
      }
   }else{
      use POSIX;
      my $ListPoints = $ListPointsObj->getByListID($ListHash->{ID});      
      my $points = ceil($ListPoints->{"ListPoints"});

      $self->{Debugger}->debug("ListPoints: " . $ListPoints->{"ListPoints"});
      if($ListHash->{ListPoints} == 1){
         $ListHash->{ListPoints} = $points . " point";
      }else{
         $ListHash->{ListPoints} = $points . " points";
      }
   }
}

=head2 getBriefListInfo

Pass hash ref of with limited list info, returns hash ref of full list info, 
including user name, x list items, formatted dates, ratings, # of favorited

Should be used for listing: search, tags, favourite lists

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListItemStatus object
   2. $HashRef - Keys of hash are List IDs

=item B<Returns: >

   1. $HashRef - Keys of hash are List IDs

=back

=cut

#############################################
sub getBriefListInfo {
#############################################
   my $self = shift;
   my $ListHash = shift;
   my $DBManager = shift;

   $self->{Debugger}->debug("in ListCentral::ListManager::getBriefListInfo $ListHash->{ID}");

   my $ListPointsObj = $DBManager->getTableObj("ListPoints");
   my $ListGroupObj = $DBManager->getTableObj("ListGroup");

   $ListHash->{FormattedCreateDate} = ListCentral::Utilities::Date::getShortHumanFriendlyDate($ListHash->{CreateDate});
   $ListHash->{ListGroup} = $ListGroupObj->get_field_by_ID("Name", $ListHash->{ListGroupID});
   $ListHash->{ListURL} = $self->getListURL($ListHash, $ListHash->{ListGroup});

   if(! $ListHash->{Public}){
      $ListHash->{ListPoints} = "X";
   }else{
      use POSIX;
      my $ListPoints = $ListPointsObj->getByListID($ListHash->{ID});      
      my $points = ceil($ListPoints->{"ListPoints"});

      $self->{Debugger}->debug("ListPoints: " . $ListPoints->{"ListPoints"});
      $ListHash->{ListPoints} = $points;
   }
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 21/1/2008

=head1 BUGS

   Not known

=cut



