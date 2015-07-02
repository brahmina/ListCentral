package ListCentral::Admin::Calculator;
use strict;

use ListCentral::SETUP;
use ListCentral::Utilities::Date;
use ListCentral::Utilities::Search;

##########################################################
# ListCentral::Admin::Calculator 
##########################################################

=head1 NAME

   ListCentral::Admin::Calculator.pm

=head1 SYNOPSIS

   $ListCalculator = new ListCentral::Admin::Calculator($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the List application

=head2 ListCentral::List Constructor

=over 4

=item B<Parameters :>

   1. $dbh
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

   $self->{Debugger}->debug("in ListCentral::Admin::Calculator constructor");

   if(!$self->{DBManager}){
      die $self->{Debugger}->log("Where is ListCentral::Admin::Calculator's DBManager??");
   }
   if(!$self->{Debugger}){
      print STDERR "No debugger? $self->{Debugger}\n";
   }


   $self->{ErrorMessages} = "";

   return ($self); 
}

=head2 getUserSignUps

Gets the number of users who sigened up within the date range specified by 
the sql where clause passed on CreateDate

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::Calculator object
   2. $DateClause - The date range part of the where clause

=item B<Returns :>

   1. $UsersSignups - The count of users signed up in the date range

=back

=cut

#############################################
sub getUserSignUps {
#############################################
   my $self = shift;
   my $DateClause = shift;

   my $UsersToday;
   my $UserObj = $self->{DBManager}->getTableObj("User");
   if($DateClause eq ""){
      $UsersToday = $UserObj->get_count();
   }else{
      $UsersToday = $UserObj->get_count_with_restraints($DateClause);
   } 

   return $UsersToday;
}

=head2 getUserLogins

Gets the number of users who logged in within the date range specified by 
the sql where clause passed on CreateDate

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::Calculator object
   2. $DateClause - The date range part of the where clause

=item B<Returns :>

   1. $UserLogins - The count of user logins in the date range

=back

=cut

#############################################
sub getUserLogins {
#############################################
   my $self = shift;
   my $DateClause = shift;

   my $UserLoginsToday;
   my $UserLogingsObj = $self->{DBManager}->getTableObj("UserLogins");
   if($DateClause eq ""){
      $UserLoginsToday = $UserLogingsObj->get_count();
   }else{
      $UserLoginsToday = $UserLogingsObj->get_count_with_restraints($DateClause);
   } 

   return $UserLoginsToday;
}

=head2 getListsCreated

Gets the number of lists created in within the date range specified by 
the sql where clause passed on CreateDate

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::Calculator object
   2. $DateClause - The date range part of the where clause

=item B<Returns :>

   1. $Lists - The count of lists created in the date range

=back

=cut

#############################################
sub getListsCreated {
#############################################
   my $self = shift;
   my $DateClause = shift;

   my $ListsToday;
   my $UserObj = $self->{DBManager}->getTableObj("List");
   if($DateClause eq ""){
      $ListsToday = $UserObj->get_count();
   }else{
      $ListsToday = $UserObj->get_count_with_restraints($DateClause);
   } 

   return $ListsToday;
}

=head2 getNewFeedbackRequestCount

Gets the number of New Feedback Requests

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::Calculator object

=item B<Returns :>

   1. $NewFeedbackRequestCount

=back

=cut

#############################################
sub getNewFeedbackRequestCount {
#############################################
   my $self = shift;

   my $FeedbackObj = $self->{DBManager}->getTableObj("Feedback");
   my $NewFeedbackRequestCount = $FeedbackObj->get_count_with_restraints("FeedBackStatusID = 1");

   return $NewFeedbackRequestCount;
}

=head2 getPendingFeedbackRequestCount

Gets the number of pending Feedback Requests

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::Calculator object

=item B<Returns :>

   1. $PendingFeedbackRequestCount

=back

=cut

#############################################
sub getPendingFeedbackRequestCount {
#############################################
   my $self = shift;

   my $FeedbackObj = $self->{DBManager}->getTableObj("Feedback");
   my $PendingFeedbackRequestCount = $FeedbackObj->get_count_with_restraints("FeedBackStatusID = 2");

   return $PendingFeedbackRequestCount;
}

=head2 getHits

Gets the number of hits within the date range specified by 
the sql where clause passed on CreateDate

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::Calculator object
   2. $DateClause - The date range part of the where clause

=item B<Returns :>

   1. $Hits - The count of hits within the date range

=back

=cut

#############################################
sub getHits {
#############################################
   my $self = shift;
   my $DateClause = shift;

   $DateClause =~ s/CreateDate/Date/gi;

   my $HitsToday;
   my $HitlogObj = $self->{DBManager}->getTableObj("Hitlog");
   if($DateClause eq ""){
      $HitsToday = $HitlogObj->get_count();
   }else{
      $HitsToday = $HitlogObj->get_count_with_restraints($DateClause);
   } 


   return $HitsToday;
}

=head2 getOnsiteListHits

Gets the number of onsite list hits within the date range specified by 
the sql where clause passed on CreateDate

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::Calculator object
   2. $DateClause - The date range part of the where clause

=item B<Returns :>

   1. $Hits

=back

=cut

#############################################
sub getOnsiteListHits {
#############################################
   my $self = shift;
   my $DateClause = shift;

   my $OnsiteListHits;
   my $ListHitsObj = $self->{DBManager}->getTableObj("ListHits");
   if($DateClause eq ""){
      $OnsiteListHits = $ListHitsObj->get_distinct_field_count_with_restraints("UserID", "UserID IS NOT NULL AND Email = 0");
   }else{
      $OnsiteListHits = $ListHitsObj->get_distinct_field_count_with_restraints("UserID", "UserID IS NOT NULL AND Email = 0 AND $DateClause");
   } 
   
   return $OnsiteListHits;
}

=head2 getOffsiteListHits

Gets the number of offsite list hits within the date range specified by 
the sql where clause passed on CreateDate

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::Calculator object
   2. $DateClause - The date range part of the where clause

=item B<Returns :>

   1. $Hits

=back

=cut

#############################################
sub getOffsiteListHits {
#############################################
   my $self = shift;
   my $DateClause = shift;

   my $OffsiteListHits;
   my $ListHitsObj = $self->{DBManager}->getTableObj("ListHits");
   if($DateClause eq ""){
      $OffsiteListHits = $ListHitsObj->get_distinct_field_count_with_restraints("IP", "UserID IS NULL AND Email = 0");
   }else{
      $OffsiteListHits = $ListHitsObj->get_distinct_field_count_with_restraints("IP", "UserID IS NULL AND Email = 0 AND $DateClause");
   } 

   return $OffsiteListHits;
}

=head2 getListsEmailed

Gets the number of times lists have been emailed out

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::Calculator object
   2. $DateClause - The date range part of the where clause

=item B<Returns :>

   1. $Hits

=back

=cut

#############################################
sub getListsEmailed {
#############################################
   my $self = shift;
   my $DateClause = shift;

   my $OffsiteListHits;
   my $ListHitsObj = $self->{DBManager}->getTableObj("ListHits");
   if($DateClause eq ""){
      $OffsiteListHits = $ListHitsObj->get_distinct_field_count_with_restraints("IP", "Email = 1");
   }else{
      $OffsiteListHits = $ListHitsObj->get_distinct_field_count_with_restraints("IP", "Email = 1 AND $DateClause");
   } 

   return $OffsiteListHits;
}

=head2 getTopReferrers

Gets the 

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::Manager object

=item B<Returns :>

   1. $TopReferrers

=back

=cut

#############################################
sub getTopReferrers {
#############################################
   my $self = shift;

   my $ReferrerObj = $self->{DBManager}->getTableObj("Referrers");
   my $TopReferrers = $ReferrerObj->getTopReferrers($ListCentral::SETUP::TOP_REFERRERS_TO_DISPLAY);

   return $TopReferrers;
}


=head2 getActiveUserInfo

Gets the active user info need for the Active User Report and the calculation of
the ActivityScore

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::Manager object

=item B<Returns :>

   1. $TopReferrers

=back

=cut

#############################################
sub getActiveUserInfo {
#############################################
   my $self = shift;

   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $ActiveUsers = $UserObj->getActiveUsers();

   foreach my $ID(keys %{$ActiveUsers}) {
      $self->{UserManager}->getUserInfo($ActiveUsers->{$ID});
      $self->getUserActivityInfo($ActiveUsers->{$ID});
   }

   return $ActiveUsers;
}

=head2 getSummaryInfo

Gets the info for the Summary Statistics report of the form

$SummaryStats->{StatsItem}->{daysback}

=over 4

=item B<Parameters :>

   1. $self - Reference to a Printer object

=item B<Returns :>

   1. $SummaryInfo - Reference to a hash with the summary stats info requested

=back

=cut

#############################################
sub getSummaryInfo {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in List::Admin::Calculator::getSummaryInfo");

   my %SummaryStats;

   foreach my $daysBack(@ListCentral::SETUP::SUMMARY_STATS_DAYS_BACK) {
      my $DateClause = "";
      if($daysBack){
         my $lastMidnight = ListCentral::Utilities::Date::getTodayAtMidnight();
         my $earliestDate = $lastMidnight - ($daysBack * 86400); # 86400 is seconds in one day
         my $latestDate = $lastMidnight - (($daysBack-1) * 86400);
         $DateClause = " CreateDate > $earliestDate && CreateDate < $latestDate";
      }

      $self->{Debugger}->debug("daysBack: $daysBack");

      $SummaryStats{"ListsCreated"}{$daysBack} = $self->getListsCreated($DateClause);
      $SummaryStats{"OffsiteListHits"}{$daysBack} = $self->getOffsiteListHits($DateClause);
      $SummaryStats{"OnsiteListHits"}{$daysBack} = $self->getOnsiteListHits($DateClause);
      $SummaryStats{"PageHits"}{$daysBack} = $self->getHits($DateClause);
      $SummaryStats{"UserSignUps"}{$daysBack} = $self->getUserSignUps($DateClause);
      $SummaryStats{"UserLogins"}{$daysBack} = $self->getUserLogins($DateClause);
   }

   return \%SummaryStats;
}



=head2 calculateActivityScore

Calculates the given user's activity score - Where the math of it is

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::Manager object

=item B<Returns :>

   1. $ActivityScore

=back

=cut

#############################################
sub calculateActivityScore {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in List::Admin::Calculator::calculateActivityScore");

   my $ActivityInfo = $self->getActivityScoreInfo($UserID);

   my $ActivityScore = ((5 * $ActivityInfo->{"ListsCount"}->{"Week"}) + (3 * $ActivityInfo->{"ListsCount"}->{"Year"}) +
                     (2 * $ActivityInfo->{"PublicListItemsCount"}->{"Week"}) + (1 * $ActivityInfo->{"PublicListItemsCount"}->{"Year"}) + 
                     (2 * $ActivityInfo->{"CommentCount"}->{"Week"}) + (1 * $ActivityInfo->{"CommentCount"}->{"Year"}) +
                     (3 * $ActivityInfo->{"FeedbackSubmitted"}->{"Week"}) + (2 * $ActivityInfo->{"FeedbackSubmitted"}->{"Year"}) +
                     (0.5 * $ActivityInfo->{"Logins"}->{"Week"}) + (0.33 * $ActivityInfo->{"Logins"}->{"Year"}))
                   / (1 + (2 * $ActivityInfo->{"UserComplaints"}->{"Week"}) + (1 * $ActivityInfo->{"UserComplaints"}->{"Year"}));

   return $ActivityScore;
}

=head2 getActivityScoreInfo

Gets the information about the userID passed that is required for calculating the user's
activity score

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::Manager object
   2. $self - The UserID to get the activty info for

=item B<Returns :>

   1. $ActivityInfo - Ref to a hash ->{Factor}->{'Week' or 'Year'}

=back

=cut

#############################################
sub getActivityScoreInfo {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in List::Admin::Calculator::getActivityScoreInfo $UserID");

   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $UserWeek = $UserObj->get_by_ID($UserID);
   my $UserYear = $UserObj->get_by_ID($UserID);

   $self->getUserActivityInfo($UserWeek, $ListCentral::SETUP::RANKING_TIMEFRAMES{'LastWeek'}, "LastWeek");
   $self->getUserActivityInfo($UserYear, $ListCentral::SETUP::RANKING_TIMEFRAMES{'LastYear'}, "LastYear");

   my %ActivityInfo;
   $ActivityInfo{"ListsCount"}{"Week"} = $UserWeek->{ListsCount}; 
   $ActivityInfo{"ListsCount"}{"Year"} = $UserYear->{ListsCount};
   $ActivityInfo{"PublicListItemsCount"}{"Week"} = $UserWeek->{PublicListItemsCount}; 
   $ActivityInfo{"PublicListItemsCount"}{"Year"} = $UserYear->{PublicListItemsCount};
   $ActivityInfo{"CommentCount"}{"Week"} = $UserWeek->{CommentCount}; 
   $ActivityInfo{"CommentCount"}{"Year"} = $UserYear->{CommentCount};
   $ActivityInfo{"FeedbackSubmitted"}{"Week"} = $UserWeek->{FeedbackSubmitted}; 
   $ActivityInfo{"FeedbackSubmitted"}{"Year"} = $UserYear->{FeedbackSubmitted};
   $ActivityInfo{"Logins"}{"Week"} = $UserWeek->{Logins}; 
   $ActivityInfo{"Logins"}{"Year"} = $UserYear->{Logins};
   $ActivityInfo{"UserComplaints"}{"Week"} = $UserWeek->{UserComplaints}; 
   $ActivityInfo{"UserComplaints"}{"Year"} = $UserYear->{UserComplaints};

   return \%ActivityInfo;
}

=head2 calculateListPoints

Calculates the List Points for the List given for each of the time periods 
and updates the ListPoints table

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::Calculator object
   2. $ListID - The list id

=back

=cut

#############################################
sub calculateUserPoints {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in List::Admin::Calculator::calculateUserPoints $UserID");

   my $UserPointsObj = $self->{DBManager}->getTableObj("UserPoints");
   my $UserPointsRow = $UserPointsObj->getByUserID($UserID);
   if(! $UserPointsRow->{ID}){
      my %UserPoints = ('UserPoints.UserID' => $UserID,
                        'UserPoints.MostRecent' => 0,
                        'UserPoints.24Hours' => 0,
                        'UserPoints.72Hours' => 0,
                        'UserPoints.LastWeek' => 0,
                        'UserPoints.LastMonth' => 0,
                        'UserPoints.LastYear' => 0,
                        'UserPoints.AllTime' => 0,
                        'UserPoints.ActivityMostRecent' => 0,
                        'UserPoints.Activity24Hours' => 0,
                        'UserPoints.Activity72Hours' => 0,
                        'UserPoints.ActivityLastWeek' => 0,
                        'UserPoints.ActivityLastMonth' => 0,
                        'UserPoints.ActivityLastYear' => 0,
                        'UserPoints.ActivityAllTime' => 0,
                        'UserPoints.Status' => 1
                        );
      $UserPointsObj->store(\%UserPoints);
      $UserPointsRow = $UserPointsObj->getByUserID($UserID);
   }

   foreach my $field(keys %ListCentral::SETUP::RANKING_TIMEFRAMES) {
      my $Seconds = $ListCentral::SETUP::RANKING_TIMEFRAMES{$field};
      my $UPs = $self->getUserListPointsSum($UserID, $field);
      if($UPs != $UserPointsRow->{$field}){
         $UserPointsObj->update($field, $UPs, $UserPointsRow->{ID});
      }

      my $activityField = "Activity" . $field;
      my $UserActivityPoints = $self->getUserActivityPoints($UserID, $Seconds);
      if($UserActivityPoints != $UserPointsRow->{$activityField}){
         $UserPointsObj->update($activityField, $UserActivityPoints, $UserPointsRow->{ID});
      }
   }
}

=head2 getUserListPointsSum

Sums up the list points for a given user and time frame and returns the result

=over 4

=item B<Parameters :>

   1. $self - Reference to a Printer object
   2. $UserID - The UserID
   3. $TimeFrame - From the fields in the table ListPoints

=item B<Returns :>

   1. $UserInfo - Reference to a hash with the User info requested

=back

=cut

#############################################
sub getUserListPointsSum {
#############################################
   my $self = shift;
   my $UserID = shift;
   my $TimeFrame = shift;

   my $ListObj = $self->{DBManager}->getTableObj("List");
   my $ListPointsObj = $self->{DBManager}->getTableObj("ListPoints");
   my $Lists = $ListObj->get_with_restraints("UserID = $UserID"); 

   my $ListPointsSum = 0;
   foreach my $ListID (keys %{$Lists}) {
      my $ListPoints = $ListPointsObj->getByListID($ListID);
      $ListPointsSum += $ListPoints->{$TimeFrame};
   }
   return $ListPointsSum;
}

=head2 getUserActivityPoints

Gets all the info about the User associated with the UserID passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Printer object
   2. $UserID - The UserID
   3. $SecondsBack

=item B<Returns :>

   1. $UserInfo - Reference to a hash with the User info requested

=back

=cut

#############################################
sub getUserActivityPoints {
#############################################
   my $self = shift;
   my $UserID = shift;
   my $SecondsBack = shift;

   $self->{Debugger}->debug("in User::Admin::Calculator::getUserActivityPoints : $UserID, $SecondsBack");

   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $User = $UserObj->get_by_ID($UserID);
   $self->getUserActivityInfo($User, $SecondsBack);

   # Do Math here
   my $UserPoints = 0;
   if(! ($User->{"PendingReport"} || $User->{"ValidReport"}) && ! $User->{"UserComplaints"}){
      $UserPoints = ((2 * $User->{"PublicListItemsCount"}) +
                     (1 * $User->{"CommentCount"}) +
                     (1 * $User->{"ListsCount"}) +
                     (1 * $User->{"FeedbackSubmitted"}) +
                     (0.5 * $User->{"Ratings"}) +
                     (0.5 * $User>{"Logins"}));
   }else{
      $UserPoints = -1;
   }

   return $UserPoints;
}

=head2 getUserActivityInfo

Gets all the info about the user associated with the UserID passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Printer object
   2. $Id - The UserID

=item B<Returns :>

   1. $UserInfo - Reference to a hash with the user info requested

=back

=cut

#############################################
sub getUserActivityInfo {
#############################################
   my $self = shift;
   my $UserHash = shift;
   my $SecondsBack = shift;
   my $TimeFrame = shift;

   $self->{Debugger}->debug("in List::Admin::Calculator::getUserActivityInfo - $SecondsBack");

   my $DateClause = "";
   if($SecondsBack){
      my $earliestDate = time() - $SecondsBack; 
      $DateClause = " AND CreateDate > $earliestDate";
   }  

   my $ListObj = $self->{DBManager}->getTableObj("List");
   my $ListItemObj = $self->{DBManager}->getTableObj("ListItem");
   my $CommentObj = $self->{DBManager}->getTableObj("Comment");
   my $FeedbackObj = $self->{DBManager}->getTableObj("Feedback");
   my $UserLoginsObj = $self->{DBManager}->getTableObj("UserLogins");
   my $ComplaintsObj = $self->{DBManager}->getTableObj("ComplaintsAgainstUser");
   my $ListRatingsObj = $self->{DBManager}->getTableObj("ListRatings");

   my $ID = $UserHash->{ID};

   # Items requiring calculations
   $UserHash->{ListsCount} = $ListObj->get_count_with_restraints("UserID = $ID $DateClause");

   my $ListItemCount = 0;
   my $UsersPublicLists = $ListObj->get_with_restraints("UserID = $ID AND Public = 1 $DateClause");
   foreach my $ListID(keys %{$UsersPublicLists}) {
      $ListItemCount += $ListItemObj->get_count_with_restraints("ListID = $ListID");
   }
   $UserHash->{PublicListItemsCount} = $ListItemCount;
   $UserHash->{CommentCount} = $CommentObj->get_count_with_restraints("CommenterID = $ID $DateClause");
   $UserHash->{FeedbackSubmitted} = $FeedbackObj->get_count_with_restraints("ReportingUserID = $ID $DateClause");
   $UserHash->{Logins} = $UserLoginsObj->get_count_with_restraints("UserID = $ID $DateClause");
   $UserHash->{UserComplaints} = $ComplaintsObj->get_count_with_restraints("UserID = $ID $DateClause");
   $UserHash->{Ratings} = $ListRatingsObj->get_count_with_restraints("UserID = $ID $DateClause");

   $UserHash->{PendingReport} = $FeedbackObj->get_count_with_restraints("ProblematicUserID = $ID AND (FeedbackStatusID = 1 || FeedbackStatusID = 2)"); 
   $UserHash->{ValidReport} = $FeedbackObj->get_count_with_restraints("ProblematicUserID = $ID AND ValidComplaint = 1"); 

   $UserHash->{ListPointsSum} = $self->getUserListPointsSum($UserHash->{ID}, $TimeFrame);
}

#####################################################################################################
#####################################################################################################
#####################################################################################################

=head2 calculateListPoints

Calculates the List Points for the List given for each of the time periods 
and updates the ListPoints table

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::Calculator object
   2. $ListID - The list id

=back

=cut

#############################################
sub calculateListPointsNOTUSED {
#############################################
   my $self = shift;
   my $ListID = shift;

   $self->{Debugger}->debug("in List::Admin::Calculator::calculateListPoints $ListID");

   my $ListPointsObj = $self->{DBManager}->getTableObj("ListPoints");
   my $ListPointsRow = $ListPointsObj->getByListID($ListID);
   if(! $ListPointsRow->{ID}){
      my %ListPoints = ('ListPoints.ListID' => $ListID,
                        'ListPoints.MostRecent' => 0,
                        'ListPoints.24Hours' => 0,
                        'ListPoints.72Hours' => 0,
                        'ListPoints.LastWeek' => 0,
                        'ListPoints.LastMonth' => 0,
                        'ListPoints.LastYear' => 0,
                        'ListPoints.AllTime' => 0,
                        'ListPoints.Status' => 1
                        );
      $ListPointsObj->store(\%ListPoints);
   }
   my $ListPointsRow = $ListPointsObj->getByListID($ListID);

   foreach my $field(keys %ListCentral::SETUP::RANKING_TIMEFRAMES) {
      my $Seconds = $ListCentral::SETUP::RANKING_TIMEFRAMES{$field};
      my $LPs = $self->getListPoints($ListID, $Seconds);

      if($LPs != $ListPointsRow->{$field}){
         $ListPointsObj->update($field, $LPs, $ListPointsRow->{ID});
      }
   }
}

=head2 getListPoints

Gets all the info about the list associated with the ListID passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Printer object
   2. $ListID - The ListID
   3. $SecondsBack

=item B<Returns :>

   1. $ListInfo - Reference to a hash with the list info requested

=back

=cut

#############################################
sub getListPoints {
#############################################
   my $self = shift;
   my $ListID = shift;
   my $SecondsBack = shift;

   $self->{Debugger}->debug("in List::Admin::Calculator::getListPointsInfo : $ListID, $SecondsBack");

   my $ListObj = $self->{DBManager}->getTableObj("List");
   my $List = $ListObj->get_by_ID($ListID);
   $self->getListInfo($List, $SecondsBack);

   # Do Math here
   my $ListPoints = 0;
   if(! ($List->{"PendingReport"} || $List->{"ValidReport"})){
      $ListPoints = ((1 * $List->{"ListHits"}->{"OnSite"}) + 
                     (2 * $List->{"ListHits"}->{"OffSite"}) +
                     (3 * $List->{"ListComments"}) +
                     (2 * $List->{"ListEmails"}) +
                     (0.1 * $List->{"ListRatings"}->{1}) +
                     (0.5 * $List->{"ListRatings"}->{2}) +
                     (1 * $List->{"ListRatings"}->{3}) +
                     (2 * $List->{"ListRatings"}->{4}) +
                     (3 * $List->{"ListRatings"}->{5}));
   }else{
      $ListPoints = -1;
   }

   return $ListPoints;
}

=head2 getListInfo

Gets all the info about the list associated with the List passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Printer object
   2. $ID - The ListID

=item B<Returns :>

   1. $ListInfo - Reference to a hash with the user info requested

=back

=cut

#############################################
sub getListInfo {
#############################################
   my $self = shift;
   my $ListHash = shift;
   my $SecondsBack = shift;

   $self->{Debugger}->debug("in List::Admin::Calculator::getListInfo - $SecondsBack");

   my $DateClause = "";
   if($SecondsBack){
      my $earliestDate = time() - $SecondsBack; 
      $DateClause = " AND CreateDate > $earliestDate";
   }   

   my $ListObj = $self->{DBManager}->getTableObj("List");
   my $ListItemObj = $self->{DBManager}->getTableObj("ListItem");
   my $CommentObj = $self->{DBManager}->getTableObj("Comment");
   my $FeedbackObj = $self->{DBManager}->getTableObj("Feedback");
   my $ListRatingsObj = $self->{DBManager}->getTableObj("ListRatings");
   my $ListHitsObj = $self->{DBManager}->getTableObj("ListHits");
   my $ListGroupObj = $self->{DBManager}->getTableObj("ListGroup");
   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $ListRatingsObj = $self->{DBManager}->getTableObj("ListRatings");
   my $Clickable = 0;

   my $ID = $ListHash->{ID};

   $ListHash->{CreateDateFormatted} = ListCentral::Utilities::Date::getHumanFriendlyDate($ListHash->{CreateDate});

   $ListHash->{Username} = $UserObj->get_field_by_ID("Username", $ListHash->{UserID});
   $ListHash->{ListItemCount} = $ListItemObj->get_count_with_restraints("ListID = $ID");
   $ListHash->{ListGroup} = $ListGroupObj->get_field_by_ID("Name", $ListHash->{ListGroupID});
   $ListHash->{ListURL} = $ListObj->getListURL($ListHash, $ListHash->{ListGroup});

   $ListHash->{ListHits}->{OnSite} = $ListHitsObj->get_count_with_restraints("ListID = $ID AND UserID IS NOT NULL AND Email = 0 $DateClause");
   $ListHash->{ListHitsOnSite} = $ListHash->{ListHits}->{OnSite};
   $ListHash->{ListHits}->{OffSite} = $ListHitsObj->get_count_with_restraints("ListID = $ID AND Referrer IS NOT NULL AND Email = 0 $DateClause");
   $ListHash->{ListHitsOffSite} = $ListHash->{ListHits}->{OffSite};
   $ListHash->{ListEmails} = $ListHitsObj->get_count_with_restraints("ListID = $ID AND Email = 1 $DateClause");
   $ListHash->{TotalListHits} = $ListHash->{ListHitsOnSite} + $ListHash->{ListHitsOffSite};
   $ListHash->{ListComments} = $CommentObj->get_count_with_restraints("ListID = $ID $DateClause");

   $ListHash->{ListRating} = $ListRatingsObj->getListRatingsHTML($ID, $Clickable);
   $ListHash->{ListRatings}->{1} = $ListRatingsObj->get_count_with_restraints("ListID = $ID AND Rating = 1 $DateClause");
   $ListHash->{ListRatings}->{2} = $ListRatingsObj->get_count_with_restraints("ListID = $ID AND Rating = 2 $DateClause");
   $ListHash->{ListRatings}->{3} = $ListRatingsObj->get_count_with_restraints("ListID = $ID AND Rating = 3 $DateClause");
   $ListHash->{ListRatings}->{4} = $ListRatingsObj->get_count_with_restraints("ListID = $ID AND Rating = 4 $DateClause");
   $ListHash->{ListRatings}->{5} = $ListRatingsObj->get_count_with_restraints("ListID = $ID AND Rating = 5 $DateClause");  

   $ListHash->{PendingReport} = $FeedbackObj->get_count_with_restraints("ProblematicListID = $ID AND (FeedbackStatusID = 1 || FeedbackStatusID = 2)"); 
   $ListHash->{ValidReport} = $FeedbackObj->get_count_with_restraints("ProblematicListID = $ID AND ValidComplaint = 1"); 

}



1;

=head1 AUTHOR INFORMATION

   Author: Brahmina Burgess with help from the ApplicationFramework
   Created: 1/11/2007

=head1 BUGS

   Not known

=cut
