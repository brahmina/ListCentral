package Lists::Utilities::AdServer;
use strict;

use Lists::SETUP;

##########################################################
# Lists::AdServer 
##########################################################

=head1 NAME

   Lists::Utilities::AdServer.pm

=head1 SYNOPSIS

   $AdServer = new Lists::Utilities::AdServer(Debugger);

=head1 DESCRIPTION

Used to get resources from the web

=head2 Lists::Utilities::AdServer Constructor

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

   $self->{Debugger}->debug("in Lists::Utilities::AdServer constructor");

   $self->{Tab}->{AvailableAdvertsTab} = 1;
   
   return ($self); 
}

=head2 AddAdvert

Handles the process of adding a new advert in the List Central System

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::AdvertManager object

=item B<Prints :>

   1. $page - The page to be displayed

=back

=cut

#############################################
sub AddAdvert {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::Admin::AdvertManager::AddAdvert");

   my $AdvertObj = $self->{DBManager}->getTableObj("Advert");

   my %Advert;
   foreach my $param (sort{$a cmp $b} keys %{$self->{cgi}}) {
      if($param =~ m/Advert\.(\w+)/){
         $Advert{$param} = $self->{cgi}->{$param};
         $self->{cgi}->{$param} =~ s/"/'/g;
      }
   }

   $Advert{"Advert.Status"} = 1;
   my $AdvertID = $AdvertObj->store(\%Advert);   

   $self->{Tab}->{AdPlacementTab} = 1;

   return "$Lists::SETUP::ADMIN_DIR_PATH/advert_management.html";
}

=head2 EditAdvert

Handles the process of editing an advert in the List Central System

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::AdvertManager object

=item B<Prints :>

   1. $page - The page to be displayed

=back

=cut

#############################################
sub EditAdvert {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::Admin::AdvertManager::EditAdvert");

   my $AdvertObj = $self->{DBManager}->getTableObj("Advert");
   my $AdvertID = $self->{cgi}->{"Advert.ID"};
   my $Advert = $AdvertObj->get_by_ID($AdvertID);

   my %Advert;
   foreach my $param (sort{$a cmp $b} keys %{$self->{cgi}}) {
      if($param =~ m/Advert\.(\w+)/){
         my $field = $1;
         if($field eq "Dimensions"){
            my ($width, $height) = split("x", $self->{cgi}->{$param});
            if($width != $Advert->{Width}){
               $AdvertObj->update("Width", $width, $AdvertID);
            }
            if($height != $Advert->{Height}){
               $AdvertObj->update("Height", $height, $AdvertID);
            }
         }else{
            if($self->{cgi}->{$param} ne $Advert->{$field}){
               $self->{cgi}->{$param} =~ s/"/'/g;
               $AdvertObj->update($field, $self->{cgi}->{$param}, $AdvertID);
            }
         }
      }
   }

   return "$Lists::SETUP::ADMIN_DIR_PATH/advert_management.html";
}


=head2 DeleteAdvert

Handles the process of deleting an advert in the List Central System

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::AdvertManager object

=item B<Prints :>

   1. $page - The page to be displayed

=back

=cut

#############################################
sub DeleteAdvert {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::Admin::AdvertManager::DeleteAdvert");

   my $AdvertObj = $self->{DBManager}->getTableObj("Advert");
   my $AdvertID = $self->{cgi}->{"Advert.ID"};
   $AdvertObj->update("Status", 0, $AdvertID);

   return "$Lists::SETUP::ADMIN_DIR_PATH/advert_management.html";
}

=head2 PlaceAdvert

Places an advert, by entering an entry in the AdvertAdSpaces table

Also doubles as the data entry place for the Ad Space ratings

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::AdvertManager object

=item B<Prints :>

   1. $content - The page to be displayed next

=back

=cut

#############################################
sub PlaceAdvert {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::Admin::AdvertManager::PlaceAdvert"); 

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
                                     "AdvertAdSpaces.AdSpacesID" => $AdSpaceID,
                                     "AdvertAdSpaces.Status" => 1);
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

   return "$Lists::SETUP::ADMIN_DIR_PATH/advert_management.html";
}

=head2 getAdvert

Gets the code for the advert to be displayed in the Ad Space corresponding to
the AdSpaceID passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::AdvertManager object
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

   $self->{Debugger}->debug("in Lists::Admin::AdvertManager::getAdvert with $params");

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

   1. $self - Reference to a Lists::Admin::AdvertManager object
   2. $AdvertId - The advert ID

=back

=cut

#############################################
sub addAdImpression {
#############################################
   my $self = shift;
   my $AdvertID = shift;
   my $AdSpaceID = shift;

   $self->{Debugger}->debug("in Lists::Admin::AdvertManager->addAdImpression with Advert: $AdvertID, AdSpace: $AdSpaceID");

   my $AdImpressionsObj = $self->{DBManager}->getTableObj("AdImpressions");

   use Lists::Utilities::Date;
   my $todayAtMidnight = Lists::Utilities::Date::getTodayAtMidnight();

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
                          "AdImpressions.AdSpacesID" => $AdSpaceID,
                          "AdImpressions.Status" => 1);
      $AdImpressionsObj->store(\%AdImpression);
   }   
}

=head2 getAvailableAdverts

Gets the code for the advert to be displayed in the Ad Space corresponding to
the AdSpaceID passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::AdvertManager object
   2. $AdSpaceID

=item B<Prints :>

   1. $AdCode - The code for the advert requested

=back

=cut

#############################################
sub getAvailableAdverts {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::Admin::AdvertManager::getAvailableAdverts");

   my $AdvertObj = $self->{DBManager}->getTableObj("Advert");
   my $Adverts = $AdvertObj->get_all();
   my $advert_row_file = "$Lists::SETUP::ADMIN_DIR_PATH/Utilities/AdServer/advert_row.html";
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

   1. $self - Reference to a Lists::Admin::AdvertManager object
   2. $AdSpaceID

=item B<Prints :>

   1. $AdCode - The code for the advert requested

=back

=cut

#############################################
sub getAdvertSpaces {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::Admin::AdvertManager::getAdverSpaces");

   my $AdSpacesObj = $self->{DBManager}->getTableObj("AdSpaces");
   my $AdvertAdSpacesObj = $self->{DBManager}->getTableObj("AdvertAdSpaces");
   my $AdSpaces = $AdSpacesObj->get_all();
   my $adspace_row_file = "$Lists::SETUP::ADMIN_DIR_PATH/Utilities/AdServer/adspace_row.html";

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

   1. $self - Reference to a Lists::Admin::AdvertManager object
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

   $self->{Debugger}->debug("in Lists::Admin::AdvertManager::getAvailableAdvertsDropdown");

   my $AdSpacesObj = $self->{DBManager}->getTableObj("AdSpaces");
   my $AdSpace = $AdSpacesObj->get_by_ID($AdSpaceID);

   my $AdvertObj = $self->{DBManager}->getTableObj("Advert");
   my $Adverts = $AdvertObj->get_all();
   my $advert_row_file = "$Lists::SETUP::ADMIN_DIR_PATH/Utilities/AdServer/advert_row.html";
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

   1. $self - Reference to a Lists::Admin::AdvertManager object
   2. $AdvertID - Optional selected advert id

=item B<Prints :>

   1. $AdvertsSelect - The code for the adverts dropdown requested

=back

=cut

#############################################
sub getAdImpressionsReport {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::Admin::AdvertManager::getAdImpressionsReport");

   my $AdImpressionsObj = $self->{DBManager}->getTableObj("AdImpressions");
   my $AdvertObj = $self->{DBManager}->getTableObj("Advert");
   my $AdSpacesObj = $self->{DBManager}->getTableObj("AdSpaces");

   my %AdvertAdSpacePairs;
   my $todayAtMidnight = Lists::Utilities::Date::getTodayAtMidnight();
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

   my $SevenDaysAgo = Lists::Utilities::Date::getBriefHumanFriendlyDate($todayAtMidnight - (7 * 86400));
   my $SixDaysAgo = Lists::Utilities::Date::getBriefHumanFriendlyDate($todayAtMidnight - (6 * 86400));
   my $FiveDaysAgo = Lists::Utilities::Date::getBriefHumanFriendlyDate($todayAtMidnight - (5 * 86400));
   my $FourDaysAgo = Lists::Utilities::Date::getBriefHumanFriendlyDate($todayAtMidnight - (4 * 86400));
   my $ThreeDaysAgo = Lists::Utilities::Date::getBriefHumanFriendlyDate($todayAtMidnight - (3 * 86400));
   my $TwoDaysAgo = Lists::Utilities::Date::getBriefHumanFriendlyDate($todayAtMidnight - (2 * 86400));

   
   my $AdImpressionsReport;
   my $adimpresssions_row = "$Lists::SETUP::ADMIN_DIR_PATH/Utilities/AdServer/adimpressions_row.html";
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

   #$self->{Debugger}->debug("in Lists::ListsManager->getTableRows with page $page, $Data");

   if($self->{UserManager}->{ThisUser}->{ID}){
      $page =~ s/$Lists::SETUP::DIR_PATH\///;
      if(-e "$Lists::SETUP::DIR_PATH/loggedin/$page"){      
         $page = "$Lists::SETUP::DIR_PATH/loggedin/$page";
      }else{
         $page = "$Lists::SETUP::DIR_PATH/$page";
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
         return $self->getPage("$Lists::SETUP::DIR_PATH/error.html");
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
            $line =~ s/<!--SETUP\.$variable-->/$Lists::SETUP::CONSTANTS{$variable}/;
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

   Author:  Marilyn Burgess
   Last Updated: 13/03/2009

=head1 BUGS

   Not known

=cut



