package ListCentral::Utilities::Ranker;
use strict;

use POSIX qw(ceil);

use ListCentral::SETUP;

##########################################################
# ListCentral::Ranker 
##########################################################

=head1 NAME

   ListCentral::Utilities::Ranker.pm

=head1 SYNOPSIS

   $Ranker = new ListCentral::Utilities::Ranker(Debugger);

=head1 DESCRIPTION

Used to get resources from the web

=head2 ListCentral::Utilities::Ranker Constructor

=over 4

=item B<Parameters :>

   1. $Debugger

=back

=cut

########################################################
sub new {
########################################################
   my $classname=shift; 
   my $self; 
   %$self=@_; 
   bless $self,ref($classname)||$classname;

   $self->{Debugger}->debug("in ListCentral::Utilities::Ranker constructor");
   
   return ($self); 
}

=head2 setListPopularityPoints

Calculates the sum of the ListRatings on the list passed in ListID, factors in the 
rater's modifier, and saves the Points in ListPoints

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Utilities::Ranker object
   2. $ListID - The list to set the list points for

=back

=cut

#############################################
sub setListPopularityPoints {
#############################################
   my $self = shift;
   my $ListID = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::Ranker->setListPopularityPoints");

   my $ListObj = $self->{DBManager}->getTableObj("List");
   my $List = $ListObj->get_by_ID($ListID);

   # Queue up the UserPoints
   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $UserModifiers = $UserObj->getUserModifiers();

   # Get the ratings for the list
   my $ListRatingsObj = $self->{DBManager}->getTableObj("ListRatings");
   my $ListRatings = $ListRatingsObj->get_with_restraints("ListID = $ListID");

   my %RatingsKey = (1 => -1, 
                     2 => 0, 
                     3 => 1, 
                     4 => 2, 
                     5 => 3);

   # Popularity
   my $Summation = 0;
   foreach my $id(keys %{$ListRatings}) {
      my $value = $RatingsKey{$ListRatings->{$id}->{Rating}};
      my $modifiedValue = $value * $UserModifiers->{$ListRatings->{$id}->{UserID}};
      $Summation = $Summation + $modifiedValue;

      $self->{Debugger}->debug("Rating: $ListRatings->{$id}->{Rating}, value: $value, Modifier: $UserModifiers->{$ListRatings->{$id}->{UserID}}, Modified: $modifiedValue, Summation: $Summation");
   }
   $self->{Debugger}->debug("Summation: $Summation");
   $Summation = ceil($Summation);

   my $ListPointsObj = $self->{DBManager}->getTableObj("ListPoints");
   my $ListPoints = $ListPointsObj->get_with_restraints("ListID = $ListID");

   my $ListPointsSet = 0;
   foreach my $ID(keys %{$ListPoints}) {
      # There should be only one
      $ListPointsObj->update("ListPoints", ceil($Summation), $ID);
      $ListPointsSet = 1;
   }

   if(! $ListPointsSet){
      my %ListPoints = ("ListPoints.ListID" => $ListID,
                        "ListPoints.ListPoints" => $Summation,
                        "ListPoints.Status" => 1,
                        "ListPoints.DateMadePublic" => $List->{CreateDate});

      $ListPointsObj->store(\%ListPoints);
   }
}


=head2 setListActivityPoints

Calculates the activity rating of a list

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Utilities::Ranker object
   2. $ListID - The list to set the list points for

=back

=cut

#############################################
sub setListActivityPoints {
#############################################
   my $self = shift;
   my $ListID = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::Ranker->setListActivityPoints");

   my $ListObj = $self->{DBManager}->getTableObj("List");
   my $List = $ListObj->get_by_ID($ListID);

   # Activity
   my $Activity = 0;
   my %ActivityKey = ("Comment" => 2, 
                      "OnsiteListHits" => 1, 
                      "OffSiteListHits" => 1);

   my $TimeAgo = time() - (3*24*60*60); # 3 days ago
   my $CommentObj = $self->{DBManager}->getTableObj("Comment");
   my $CommentCount = $CommentObj->get_count_with_restraints("ListID = $ListID AND CreateDate > $TimeAgo");

   my $ListHitsObj = $self->{DBManager}->getTableObj("ListHits");
   my $OffSiteListHitsCount = $ListHitsObj->get_distinct_field_count_with_restraints("IP", 
                  "UserID IS NULL AND Email = 0 AND ListID = $ListID AND CreateDate > $TimeAgo");
   my $OffSiteListHitsCount = $ListHitsObj->get_distinct_field_count_with_restraints("IP", 
                  "UserID IS NULL AND Email = 0 AND ListID = $ListID AND CreateDate > $TimeAgo");
   my $OnSiteListHitsCount = $ListHitsObj->get_distinct_field_count_with_restraints("IP", 
                  "UserID IS NOT NULL AND Email = 0 AND ListID = $ListID AND CreateDate > $TimeAgo");

   $Activity = ($CommentCount * $ActivityKey{"Comment"}) + 
               ($OffSiteListHitsCount * $ActivityKey{"OffSiteListHits"}) + 
               ($OnSiteListHitsCount * $ActivityKey{"OnsiteListHits"});

   my $ListPointsObj = $self->{DBManager}->getTableObj("ListPoints");
   my $ListPoints = $ListPointsObj->get_with_restraints("ListID = $ListID");

   my $ListPointsSet = 0;
   foreach my $ID(keys %{$ListPoints}) {
      $ListPointsObj->update("Activity", ceil($Activity), $ID);
      $ListPointsSet = 1;
   }

   if(! $ListPointsSet){
      my %ListPoints = ("ListPoints.ListID" => $ListID,
                        "ListPoints.Activity" => $Activity,
                        "ListPoints.Status" => 1,
                        "ListPoints.DateMadePublic" => $List->{CreateDate});

      $ListPointsObj->store(\%ListPoints);
   }
}

=head2 setListRanking

Handles the process of doing the rankings

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Utilities::Ranker object

=back

=cut

#############################################
sub setListRanking {
#############################################
   my $self = shift;
   my $ListID = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::Ranker->setListRanking");

   my $ListPointsObj = $self->{DBManager}->getTableObj("ListPoints");
   my $ListPoints = $ListPointsObj->get_with_restraints("ListID = $ListID");

   foreach my $ID(keys %{$ListPoints}) {
      # There should only be one

      # Hacker News Ranking
      my $ageInHours = (time() - $ListPoints->{$ID}->{DateMadePublic}) / (60*60);
      my $HNRanking = $ListPoints->{$ID}->{ListPoints}/ (($ageInHours + 2)**1.5);
      $ListPointsObj->update("RankingHN", ceil($HNRanking), $ID);

      # Reddit Ranking
      my $deltaTime = $ListPoints->{$ID}->{DateMadePublic} - 1209859500;
      # 1209859500 is Date constant May 4th 2008, 12:05a (Brahmina's 30th b-day)
      my $direction = 1;
      if($ListPoints->{$ID}->{ListPoints} == 0){
         $direction = 0;
      }elsif($ListPoints->{$ID}->{ListPoints} < 0){
         $direction = -1;
      }
      my $Z = abs($ListPoints->{$ID}->{ListPoints}) > 1 ? abs($ListPoints->{$ID}->{ListPoints}) : 1;
      my $RedditRanking = $self->log10($Z) + (($direction * $deltaTime)) / 15000;

      $ListPointsObj->update("RankingReddit", ceil($RedditRanking), $ID);
   }
}

=head2 log10

Performs log base 10 on the value passed and returns the result

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Utilities::Ranker object
   2. $value to be logged

=item B<Parameters :>

   1. $result

=back

=cut

#############################################
sub log10 {
#############################################
   my $self = shift;
   my $n = shift;

   return log($n)/log(10);
}

=head2 DeleteAdvert

Handles the process of deleting an advert in the List Central System

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::AdvertManager object

=item B<Prints :>

   1. $page - The page to be displayed

=back

=cut

#############################################
sub DeleteAdvert {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::AdvertManager::DeleteAdvert");

   my $AdvertObj = $self->{DBManager}->getTableObj("Advert");
   my $AdvertID = $self->{cgi}->{"Advert.ID"};
   $AdvertObj->update("Status", 0, $AdvertID);

   return "$ListCentral::SETUP::ADMIN_DIR_PATH/advert_management.html";
}

=head2 PlaceAdvert

Places an advert, by entering an entry in the AdvertAdSpaces table

Also doubles as the data entry place for the Ad Space ratings

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::AdvertManager object

=item B<Prints :>

   1. $content - The page to be displayed next

=back

=cut

#############################################
sub PlaceAdvert {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::AdvertManager::PlaceAdvert"); 

   my $AdvertAdSpacesObj = $self->{DBManager}->getTableObj("AdvertAdSpaces");
   my $AdSpacesObj = $self->{DBManager}->getTableObj("AdSpaces");
   
   foreach my $param (sort{$a cmp $b} keys %{$self->{cgi}}) {
      if($param =~ m/Adspace(\d+)_AdvertID/){
         my $AdSpaceID = $1;
         my $AdvertID = $self->{cgi}->{$param};
         if($AdvertID && $AdSpaceID){
            my $AdvertAdSpaces = $AdvertAdSpacesObj->get_with_restraints("AdSpacesID = $AdSpaceID");
            my $AdvertAdSpacesID;
            foreach my $ID(keys %{$AdvertAdSpaces}) {
               $AdvertAdSpacesID = $ID;
            }
            if( !$AdvertAdSpacesID){
               my %AdvertAdSpaces = ("AdvertAdSpaces.AdvertID" => $AdvertID,
                                     "AdvertAdSpaces.AdSpacesID" => $AdSpaceID);
               $AdvertAdSpacesObj->store(\%AdvertAdSpaces);
            }elsif($AdvertID != $AdvertAdSpaces->{AdvertID}){
               $AdvertAdSpacesObj->update("AdvertID", $AdvertID, $AdvertAdSpacesID);
            }
         }elsif($AdSpaceID && $AdvertID eq ""){
            my $AdvertAdSpaces = $AdvertAdSpacesObj->get_with_restraints("AdSpacesID = $AdSpaceID");
            foreach my $ID(keys %{$AdvertAdSpaces}) {
               $AdvertAdSpacesObj->update("Status", 0, $ID);
            }            
         }
      }elsif($param =~ m/Rating(\d+)/){
         my $AdSpaceID = $1;
         my $AdSpaces = $AdSpacesObj->get_by_ID($AdSpaceID);
         if($AdSpaces->{Rating} != $self->{cgi}->{$param}){
            $AdSpacesObj->update("Rating", $self->{cgi}->{$param}, $AdSpaceID);
         }
      }
   }

   return "$ListCentral::SETUP::ADMIN_DIR_PATH/advert_management.html";
}

=head2 getAdvert

Gets the code for the advert to be displayed in the Ad Space corresponding to
the AdSpaceID passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::AdvertManager object
   2. $AdSpaceID

=item B<Prints :>

   1. $AdCode - The code for the advert requested

=back

=cut

#############################################
sub getAdvert {
#############################################
   my $self = shift;
   my $params = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::AdvertManager::getAdvert with $params");

   my ($AdSpaceID, $extra) = split("_", $params);
   $extra = lc($extra);

   if(! $AdSpaceID){
      return "";
   }

   if($self->{Request}->uri() !~ m/$extra/ && $extra ne "page"){
      return "";
   }

   # Special cases 
   if($AdSpaceID == 14 && $self->{ThemeID} != 1){
      # The ad at the top of the page
      return "";
   }

   my $AdvertAdSpacesObj = $self->{DBManager}->getTableObj("AdvertAdSpaces");
   my $AdvertAdSpaces = $AdvertAdSpacesObj->get_with_restraints("AdSpacesID = $AdSpaceID");

   my $AdvertID;
   my $count = 0;
   foreach my $id (keys %{$AdvertAdSpaces}) {
      $AdvertID = $AdvertAdSpaces->{$id}->{AdvertID};
      $count++;
   }

   if(! $AdvertID){
      return "";
   }


   $self->addAdImpression($AdvertID, $AdSpaceID);

   my $AdvertObj = $self->{DBManager}->getTableObj("Advert");
   my $Advert = $AdvertObj->get_by_ID($AdvertID);

   return $Advert->{Code};
}

=head2 addAdImpression

Adds an AdImpression for the Advert ID passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::AdvertManager object
   2. $AdvertId - The advert ID

=back

=cut

#############################################
sub addAdImpression {
#############################################
   my $self = shift;
   my $AdvertID = shift;
   my $AdSpaceID = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::AdvertManager->addAdImpression with Advert: $AdvertID, AdSpace: $AdSpaceID");

   my $AdImpressionsObj = $self->{DBManager}->getTableObj("AdImpressions");

   use ListCentral::Utilities::Date;
   my $todayAtMidnight = ListCentral::Utilities::Date::getTodayAtMidnight();

   my $foundOne = 0; my $AdImpressionID; 
   my $AdImpressions = $AdImpressionsObj->get_with_restraints("Date = $todayAtMidnight AND AdvertID = $AdvertID AND AdSpacesID = $AdSpaceID");
   foreach my $ID(keys %{$AdImpressions}) {
      if($AdImpressions->{$ID}->{Impressions}){
         # There should be only one 
         $foundOne++;
         $AdImpressionID = $ID;
      }
   }
   if($foundOne == 1){
      my $Impressions = $AdImpressions->{$AdImpressionID}->{Impressions} + 1;
      $self->{Debugger}->debug("updating Impressions with $Impressions");
      $AdImpressionsObj->update("Impressions", $Impressions, $AdImpressionID);
   }elsif($foundOne > 1){
      #$self->{Debugger}->throwNotifyingError("Error: More than on Impression entry for one Advert/AdSpace, Day pair ($AdvertID, $todayAtMidnight)");
   }else{
      my %AdImpression = ("AdImpressions.AdvertID" => $AdvertID,
                          "AdImpressions.Date" => $todayAtMidnight,
                          "AdImpressions.Impressions" => 1,
                          "AdImpressions.AdSpacesID" => $AdSpaceID);
      $AdImpressionsObj->store(\%AdImpression);
   }

   
}

=head2 getAvailableAdverts

Gets the code for the advert to be displayed in the Ad Space corresponding to
the AdSpaceID passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::AdvertManager object
   2. $AdSpaceID

=item B<Prints :>

   1. $AdCode - The code for the advert requested

=back

=cut

#############################################
sub getAvailableAdverts {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::AdvertManager::getAvailableAdverts");

   my $AdvertObj = $self->{DBManager}->getTableObj("Advert");
   my $Adverts = $AdvertObj->get_all();
   my $advert_row_file = "$ListCentral::SETUP::ADMIN_DIR_PATH/Utilities/Ranker/advert_row.html";
   my $AdvertsHTML = "";
   foreach my $ID(keys %{$Adverts}) {
      if($Adverts->{$ID}->{Enabled}){
         $Adverts->{$ID}->{EnabledOptions} = qq~<option value="1" selected>Yes</option><option value="0">No</option>~;
      }else{
         $Adverts->{$ID}->{EnabledOptions} = qq~<option value="1">Yes</option><option value="0" selected>No</option>~;
      }
      $Adverts->{$ID}->{Dimensions} = $Adverts->{$ID}->{Width} . "x" . $Adverts->{$ID}->{Height};

      my %Data = ("Advert" => $Adverts->{$ID});

      $AdvertsHTML .= $self->getBasicPage($advert_row_file, \%Data);
   }
   return $AdvertsHTML;
}

=head2 getAdvertSpaces

Gets the code for the advert to be displayed in the Ad Space corresponding to
the AdSpaceID passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::AdvertManager object
   2. $AdSpaceID

=item B<Prints :>

   1. $AdCode - The code for the advert requested

=back

=cut

#############################################
sub getAdvertSpaces {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::AdvertManager::getAdverSpaces");

   my $AdSpacesObj = $self->{DBManager}->getTableObj("AdSpaces");
   my $AdvertAdSpacesObj = $self->{DBManager}->getTableObj("AdvertAdSpaces");
   my $AdSpaces = $AdSpacesObj->get_all();
   my $adspace_row_file = "$ListCentral::SETUP::ADMIN_DIR_PATH/Utilities/Ranker/adspace_row.html";

   my $AdSpacesHTML = "";
   foreach my $ID(sort{$a <=> $b} keys %{$AdSpaces}) {

      my $AdvertID = "";
      my $AdvertAdSpaces = $AdvertAdSpacesObj->get_with_restraints("AdSpacesID = $ID");
      foreach my $ID(keys %{$AdvertAdSpaces}) {
         $AdvertID = $AdvertAdSpaces->{$ID}->{AdvertID};
      }
      $AdSpaces->{$ID}->{Dimensions} = $AdSpaces->{$ID}->{Width} . "x" . $AdSpaces->{$ID}->{Height};
      my $AdvertDropDown = $self->getAvailableAdvertsDropdown($AdvertID, $ID);

      my %Data = ("AdSpace" => $AdSpaces->{$ID},
                  "AdvertDropDown" => $AdvertDropDown);

      $AdSpacesHTML .= $self->getBasicPage($adspace_row_file, \%Data);
   }
   return $AdSpacesHTML;
}

=head2 getAvailableAdverts

Gets the code for the advert to be displayed in the Ad Space corresponding to
the AdSpaceID passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::AdvertManager object
   2. $AdvertID - Optional selected advert id

=item B<Prints :>

   1. $AdvertsSelect - The code for the adverts dropdown requested

=back

=cut

#############################################
sub getAvailableAdvertsDropdown {
#############################################
   my $self = shift;
   my $AdvertID = shift;
   my $AdSpaceID = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::AdvertManager::getAvailableAdvertsDropdown");

   my $AdSpacesObj = $self->{DBManager}->getTableObj("AdSpaces");
   my $AdSpace = $AdSpacesObj->get_by_ID($AdSpaceID);

   my $AdvertObj = $self->{DBManager}->getTableObj("Advert");
   my $Adverts = $AdvertObj->get_all();
   my $advert_row_file = "$ListCentral::SETUP::ADMIN_DIR_PATH/Utilities/Ranker/advert_row.html";
   my $selectname = "Adspace".$AdSpaceID."_AdvertID";
   my $AdvertsSelect = "<select name='$selectname'>";
   $AdvertsSelect .= qq~<option value="" selected>None</option>~;
   foreach my $ID(keys %{$Adverts}) {
      if($Adverts->{$ID}->{Width} <= $AdSpace->{Width} && $Adverts->{$ID}->{Height} <= $AdSpace->{Height}){
         if($ID == $AdvertID){
            $AdvertsSelect .= qq~<option value="$ID" selected>$Adverts->{$ID}->{Name}</option>~;
         }else{
            $AdvertsSelect .= qq~<option value="$ID">$Adverts->{$ID}->{Name}</option>~;
         }
      }
   }
   $AdvertsSelect .= "</select>";

   return $AdvertsSelect;
}

=head2 getAvailableAdverts

Gets the code for the advert to be displayed in the Ad Space corresponding to
the AdSpaceID passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::AdvertManager object
   2. $AdvertID - Optional selected advert id

=item B<Prints :>

   1. $AdvertsSelect - The code for the adverts dropdown requested

=back

=cut

#############################################
sub getAdImpressionsReport {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::AdvertManager::getAdImpressionsReport");

   my $AdImpressionsObj = $self->{DBManager}->getTableObj("AdImpressions");
   my $AdvertObj = $self->{DBManager}->getTableObj("Advert");
   my $AdSpacesObj = $self->{DBManager}->getTableObj("AdSpaces");

   my %AdvertAdSpacePairs;
   my $todayAtMidnight = ListCentral::Utilities::Date::getTodayAtMidnight();
   my $sevenDaysAgoEpoch = $todayAtMidnight - (6 * 86400);
   my $AdImpressions = $AdImpressionsObj->get_with_restraints("Date >= $sevenDaysAgoEpoch");
   foreach my $ID(keys %{$AdImpressions}) {
      my $key = $AdImpressions->{$ID}->{AdvertID} . "_" . $AdImpressions->{$ID}->{AdSpacesID};
      $AdvertAdSpacePairs{$key}{$AdImpressions->{$ID}->{Date}}{"Impressions"} = $AdImpressions->{$ID}->{Impressions};
      $AdvertAdSpacePairs{$key}{$AdImpressions->{$ID}->{Date}}{"Earnings"} = $AdImpressions->{$ID}->{Earnings}; 
      $AdvertAdSpacePairs{$key}{$AdImpressions->{$ID}->{Date}}{"Clicks"} = $AdImpressions->{$ID}->{Clicks}; 

      if($AdImpressions->{$ID}->{Clicks}){
         $AdvertAdSpacePairs{$key}{$AdImpressions->{$ID}->{Date}}{"Conversion"} = 100 * ($AdImpressions->{$ID}->{Clicks}/$AdImpressions->{$ID}->{Impressions}); 
      }else{
         $AdvertAdSpacePairs{$key}{$AdImpressions->{$ID}->{Date}}{"Conversion"} = "&nbsp;";
      }
   }

   my $SevenDaysAgo = ListCentral::Utilities::Date::getBriefHumanFriendlyDate($todayAtMidnight - (7 * 86400));
   my $SixDaysAgo = ListCentral::Utilities::Date::getBriefHumanFriendlyDate($todayAtMidnight - (6 * 86400));
   my $FiveDaysAgo = ListCentral::Utilities::Date::getBriefHumanFriendlyDate($todayAtMidnight - (5 * 86400));
   my $FourDaysAgo = ListCentral::Utilities::Date::getBriefHumanFriendlyDate($todayAtMidnight - (4 * 86400));
   my $ThreeDaysAgo = ListCentral::Utilities::Date::getBriefHumanFriendlyDate($todayAtMidnight - (3 * 86400));
   my $TwoDaysAgo = ListCentral::Utilities::Date::getBriefHumanFriendlyDate($todayAtMidnight - (2 * 86400));

   
   my $AdImpressionsReport;
   my $adimpresssions_row = "$ListCentral::SETUP::ADMIN_DIR_PATH/Utilities/Ranker/adimpressions_row.html";
   foreach my $pair(keys %AdvertAdSpacePairs) {
      my ($AdvertID, $AdSpaceID) = split("_", $pair);
      if(! $AdvertID && $AdSpaceID){
         $self->{Debugger}->debug("What the fuck is this? pair: $pair");
         next;
      }
      my $Advert = $AdvertObj->get_by_ID($AdvertID);
      my $AdSpace = $AdSpacesObj->get_by_ID($AdSpaceID);

      my $impressions = "<tr><td>Impressions</td>"; 
      my $clicks = "<tr><td>Clicks</td>"; 
      my $earnings = "<tr><td>Earnings</td>";  
      my $conversion = "<tr><td>Conversion</td>";
      foreach my $date(sort keys %{$AdvertAdSpacePairs{$pair}}) {
         $impressions .= "<td>$AdvertAdSpacePairs{$pair}{$date}{Impressions}</td>";
         $clicks .= "<td><input type='text' value='$AdvertAdSpacePairs{$pair}{$date}{Clicks}' name='Clicks_$pair' /></td>";
         $earnings .= "<td><input type='text' value='$AdvertAdSpacePairs{$pair}{$date}{Earnings}' name='Earnings_$pair' /></td>";
         $conversion .= "<td>$AdvertAdSpacePairs{$pair}{$date}{Conversion}</td>";
      }

      my %Data = ("Advert" => $Advert,
                  "AdSpace" => $AdSpace,
                  "Impressions" => $impressions,
                  "Clicks" => $clicks,
                  "Earnings" => $earnings,
                  "Conversion" => $conversion,
                  "7DaysAgo" => $SevenDaysAgo,
                  "6DaysAgo" => $SixDaysAgo,
                  "5DaysAgo" => $FiveDaysAgo,
                  "4DaysAgo" => $FourDaysAgo,
                  "3DaysAgo" => $ThreeDaysAgo,
                  "2DaysAgo" => $TwoDaysAgo
                  );

      $AdImpressionsReport .= $self->getBasicPage($adimpresssions_row, \%Data);
   }

   return $AdImpressionsReport;
}


=head2 getBasicPage

A more basic version of getPage 

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $page - the page to print
   3. $Data - Up to 2 level hash with corresponding data

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub getBasicPage {
#############################################
   my $self = shift;
   my $page = shift;
   my $Data = shift;

   #$self->{Debugger}->debug("in ListCentral::ListsManager->getTableRows with page $page, $Data");

   if($self->{UserManager}->{ThisUser}->{ID}){
      $page =~ s/$ListCentral::SETUP::DIR_PATH\///;
      if(-e "$ListCentral::SETUP::DIR_PATH/loggedin/$page"){      
         $page = "$ListCentral::SETUP::DIR_PATH/loggedin/$page";
      }else{
         $page = "$ListCentral::SETUP::DIR_PATH/$page";
      }   
   }

   # File Cache
   my @lines;
   if($self->{BasicFileCache}->{$page}){
      @lines = @{$self->{BasicFileCache}->{$page}};
   }else{     
      my $template = $page;
      if(! open (PAGE, $template)){
         my $error = "Cannot write file: $template $!";
         $self->{Debugger}->log($error);
         $self->{ErrorMessages} = $error;
         return $self->getPage("$ListCentral::SETUP::DIR_PATH/error.html");
      }
      @lines = <PAGE>;
      close PAGE;

      my @linesSave = @lines;
      $self->{BasicFileCache}->{$page} = \@linesSave;
   }


   my $content = "";
   foreach my $line (@lines) {
      if($line =~ m/<!--(.+)-->/){
         #$self->{Debugger}->debug("getPage tag: $1");
         if($line =~ m/<!--URL-->/){
            my $url = "http://$ENV{HTTP_HOST}";
            $line =~ s/<!--URL-->/$url/;
         }elsif($line =~ m/<!--SETUP\.([\w_]+)-->/){
            my $variable = $1;
            $line =~ s/<!--SETUP\.$variable-->/$ListCentral::SETUP::CONSTANTS{$variable}/;
         }elsif($line =~ m/<!--Self\.([\w\.]+)-->/g){
            my $variable = $1;
            if($variable =~ m/ErrorMessages/ && $self->{$variable}){
               $self->{$variable} = "<p class=\"error\">$self->{$variable}</p>";
            }
            $line =~ s/<!--Self\.$variable-->/$self->{$variable}/g;
         }elsif($line =~ m/<!--CGI\.([\w\.]+)-->/){
            my $field = $1;
            my $value = $self->{cgi}->{$field};
            $line =~ s/<!--CGI\.$field-->/$value/;
         }elsif($line =~ m/<!--ErrorMessages-->/){
            if($self->{ErrorMessages}){
               $self->{ErrorMessages} = "<p class=\"error\">$self->{ErrorMessages}</p>";
            }
            $line =~ s/<!--ErrorMessages-->/$self->{ErrorMessages}/;
         }elsif($line =~ m/<!--GetOutputFromFunc\.(\w+)-->/){
            my $func = $1;
            my $output = $self->$func();
            $line =~ s/<!--GetOutputFromFunc\.$func-->/$output/;
         }elsif($line =~ m/<!--Data\.([\w_]+)-->/){
            my $field = $1;
            if($field =~ m/(\w+)_(\w+)/){
               my $hashName = $1;
               my $hashValue = $2;
               $line =~ s/<!--Data\.$field-->/$Data->{$hashName}->{$hashValue}/;
            }else{
               $line =~ s/<!--Data\.$field-->/$Data->{$field}/;
            }
         }else{
            if($line =~ m/<!--(.+)-->/){
               my $tag = $1;
               #$self->{Debugger}->log("ERROR: Unknown Tag: $tag");
            }else{
               #$self->{Debugger}->log("ERROR: Unknown Tag, Line: <textarea>$line</textarea>");
            }            
         }
      }
      $content .= $line;
   }
   return $content;
}




1;

=head1 AUTHOR INFORMATION

   Author:  Brahmina Burgess
   Last Updated: 13/03/2009

=head1 BUGS

   Not known

=cut



