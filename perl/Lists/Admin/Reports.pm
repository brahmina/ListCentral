package Lists::Admin::Reports;
use strict;

use Lists::SETUP;
use Lists::Utilities::Date;
use Lists::Utilities::Search;
use Lists::Admin::Calculator;

##########################################################
# Lists::Admin::Reports 
##########################################################

=head1 NAME

   Lists::Admin::Reports.pm

=head1 SYNOPSIS

   $ListReports = new Lists::Admin::Reports($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the List application

=head2 Lists::List Constructor

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

   $self->{Debugger}->debug("in Lists::Admin::Reports constructor");

   if(!$self->{DBManager}){
      die $self->{Debugger}->log("Where is Lists::Admin::Reports's DBManager??");
   }
   if(!$self->{Debugger}){
      print STDERR "No debugger? $self->{Debugger}\n";
   }

   $self->{Calculator} = new Lists::Admin::Calculator("Debugger" => $self->{Debugger}, "DBManager" => $self->{DBManager},
						      "UserManager" => $self->{UserManager});

   $self->{ErrorMessages} = "";

   return ($self); 
}

=head2 getReport

Handles any request made to the Lists Utility

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $report - the report to print
         Options: SummaryStats, ActiveUsers, PopularUsers, PopularLists, TroublesomeUsers

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub getReport {
#############################################
   my $self = shift;
   my $report = shift;

   $self->{Debugger}->debug("in Lists::Admin::Reports->getReport with page $report");

   if($report eq "UserSettings"){
      return $self->getUserSettingsReport($self->{cgi}->{UserID});
   }
   my $page = "$Lists::SETUP::ADMIN_DIR_PATH/reports/$report.html";
   my $content = "";
   my $template = $page;
   open(PAGE, $template) || $self->{Debugger}->log("cannot open file: $template - $!");
   my @lines = <PAGE>;
   close PAGE;

   my $UserInfo;
   my $ActivityInfo;
   my $SummaryInfo;
   if($report eq "UserDetails"){
      my $UserObj = $self->{DBManager}->getTableObj("User");
      $UserInfo = $UserObj->get_by_ID($self->{cgi}->{UserID});
      $self->{UserManager}->getUserInfo($UserInfo);
      $ActivityInfo = $self->{Calculator}->getActivityScoreInfo($self->{cgi}->{UserID});

      $UserInfo->{ListPointsSum} = $self->{Calculator}->getUserListPointsSum($UserInfo->{ID}, "AllTime");
   }elsif($report eq "SummaryStats"){
      $SummaryInfo = $self->{Calculator}->getSummaryInfo();
   }

   foreach my $line (@lines) {
      if($line =~ m/<!--(.+)-->/){
         #$self->{Debugger}->debug("printPage tag: $1");
         if($line =~ m/<!--URL-->/){
            my $url = "http://$ENV{HTTP_HOST}";
            $line =~ s/<!--URL-->/$url/;
         }elsif($line =~ m/<!--RootPath-->/){
            my $RootPath = $Lists::SETUP::ROOT_PATH . "Lists/";
            $line =~ s/<!--RootPath-->/$RootPath/;
         }elsif($line =~ m/<!--SETUP\.([\w_]+)-->/){
            my $variable = $1;
            $line =~ s/<!--SETUP\.$variable-->/$Lists::SETUP::CONSTANTS{$variable}/;
         }elsif($line =~ m/<!--Self\.([\w\.]+)-->/){
            my $variable = $1;
            $line =~ s/<!--Self\.$variable-->/$self->{$variable}/;
         }elsif($line =~ m/<!--CGI\.([\w\.]+)-->/){
            my $field = $1;
            my $value = $self->{cgi}->{$field};
            $line =~ s/<!--CGI\.$field-->/$value/;
         }elsif($line =~ m/<!--SummaryInfo\.(\w+)\.(\d+)-->/){
            my $Stat = $1;
            my $days = $2;
            $line =~ s/<!--SummaryInfo\.$Stat\.$days-->/$SummaryInfo->{$Stat}->{$days}&nbsp;/;
         }elsif($line =~ m/<!--NewFeedbackRequestCount-->/){
            my $NewFeedbackRequestCount = $self->{Calculator}->getNewFeedbackRequestCount();
            $line =~ s/<!--NewFeedbackRequestCount-->/$NewFeedbackRequestCount/;
         }elsif($line =~ m/<!--PendingFeedbackRequestCount-->/){
            my $PendingFeedbackRequestCount = $self->{Calculator}->getPendingFeedbackRequestCount();
            $line =~ s/<!--PendingFeedbackRequestCount-->/$PendingFeedbackRequestCount/;
         }elsif($line =~ m/<!--TopReferrers-->/){
            my $TopReferrers = $self->{Calculator}->getTopReferrers();
            $line =~ s/<!--TopReferrers-->/$TopReferrers/;
         }elsif($line =~ m/<!--TopSearches-->/){
            my $TopSearches = $self->getTopSearches($Lists::SETUP::SEARCHES_REPORT_LIMIT);
            $line =~ s/<!--TopSearches-->/$TopSearches/;
         }elsif($line =~ m/<!--RecentSearches-->/){
            my $RecentSearches = $self->getRecentSearches($Lists::SETUP::SEARCHES_REPORT_LIMIT);
            $line =~ s/<!--RecentSearches-->/$RecentSearches/;
         }elsif($line =~ m/<!--ActiveUsersRows-->/){
            my $ActiveUsersRows = $self->getActiveUsersRows();
            $line =~ s/<!--ActiveUsersRows-->/$ActiveUsersRows/;
         }elsif($line =~ m/<!--TopReferrersRows-->/){
            my $TopReferrersRows = $self->getTopReferrersRows();
            $line =~ s/<!--TopReferrersRows-->/$TopReferrersRows/;
         }elsif($line =~ m/<!--TopSearchesRows-->/){
            my $TopSearchesRows = $self->getTopSearchesRows();
            $line =~ s/<!--TopSearchesRows-->/$TopSearchesRows/;
         }elsif($line =~ m/<!--RecentSearchesRows-->/){
            my $RecentSearchesRows = $self->getRecentSearchesRows();
            $line =~ s/<!--RecentSearchesRows-->/$RecentSearchesRows/;
         }elsif($line =~ m/<!--ComplaintsAgainstUserRows-->/){
            my $ComplaintsAgainstUserRows = $self->getComplaintsAgainstUserRows($self->{cgi}->{UserID});
            $line =~ s/<!--ComplaintsAgainstUserRows-->/$ComplaintsAgainstUserRows/;
         }elsif($line =~ m/<!--PopularUsersRows-->/){
            my $PopularUsersRows = $self->getPopularUsersRows();
            $line =~ s/<!--PopularUsersRows-->/$PopularUsersRows/;
         }elsif($line =~ m/<!--TroublesomeUsersRows-->/){
            my $TroublesomeUsersRows = $self->getTroublesomeUsersRows();
            $line =~ s/<!--TroublesomeUsersRows-->/$TroublesomeUsersRows/;
         }elsif($line =~ m/<!--PopularListRows-->/){
            my $PopularListRows = $self->getPopularListRows();
            $line =~ s/<!--PopularListRows-->/$PopularListRows/;
         }elsif($line =~ m/<!--PopularListBreakdownRows-->/){
            my $PopularListBreakdownRows = $self->getPopularListBreakdownRows($self->{cgi}->{UserID});
            $line =~ s/<!--PopularListBreakdownRows-->/$PopularListBreakdownRows/;
         }elsif($line =~ m/<!--ActivityInfo_(\w+)_(\w+)-->/){
            my $factor = $1;
            my $timeFrame = $2;
            my $replaceTag = "ActivityInfo_" . $factor . "_" . $timeFrame;
            $line =~ s/<!--$replaceTag-->/$ActivityInfo->{$factor}->{$timeFrame}/;
         }elsif($line =~ m/<!--UserInfo\.(\w+)-->/){
            my $field = $1;
            my $value = $UserInfo->{$field};
            $line =~ s/<!--UserInfo\.$field-->/$value/;
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


=head2 getActiveUsersRows

Gets the 

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::Manager object

=item B<Returns :>

   1. $TopReferrers

=back

=cut

#############################################
sub getActiveUsersRows {
#############################################
   my $self = shift;

   my $ActiveUsers = $self->{Calculator}->getActiveUserInfo();

   my $ActiveUsersRows = "";
   my $count = 1;
   foreach my $UserID(sort{$ActiveUsers->{$b}->{ActivityScore} <=> $ActiveUsers->{$a}->{ActivityScore}} keys %{$ActiveUsers}) {
      $ActiveUsersRows .= qq~<tr><td class="StatsTableData">$count</td>
                                <td class="StatsTableData">$UserID</td>
                                <td class="StatsTableData"><a href="/user.html?UserID=$UserID">$ActiveUsers->{$UserID}->{Username}</a></td> 
                                <td class="StatsTableData">$ActiveUsers->{$UserID}->{ActivityScore}</td>
                                <td class="StatsTableData">$ActiveUsers->{$UserID}->{PopularityScore}</td>
                                <td class="StatsTableData">$ActiveUsers->{$UserID}->{ListsCount}</td>
                                <td class="StatsTableData">$ActiveUsers->{$UserID}->{PublicListItemsCount}</td>
                                <td class="StatsTableData">$ActiveUsers->{$UserID}->{CommentCount}</td>
                                <td class="StatsTableData">$ActiveUsers->{$UserID}->{FeedbackSubmitted}</td>
                                <td class="StatsTableData">$ActiveUsers->{$UserID}->{Logins}</td></tr>
                           ~;
      $count++;
   }

   return $ActiveUsersRows;
}

=head2 getTopReferrersRows

Gets the 

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::Manager object

=item B<Returns :>

   1. $TopReferrers

=back

=cut

#############################################
sub getTopReferrersRows {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in List::Admin::Reports::getTopReferrersRows");

   my $ReferrerObj = $self->{DBManager}->getTableObj("Referrers");
   my $TopReferrers = $ReferrerObj->getTopReferrers($Lists::SETUP::TOP_REFERRERS_REPORT_LIMIT);

   my $TopReferrersRows = "";
   foreach my $ID(sort{$TopReferrers->{$b}->{Count} <=> $TopReferrers->{$a}->{Count}} keys %{$TopReferrers}) {
      $TopReferrersRows .= qq~<tr>
                              <td class="StatsTableData">$TopReferrers->{$ID}->{Name}</td>
                              <td class="StatsTableData">$TopReferrers->{$ID}->{Count}</td></tr>
                           ~;
   }

   return $TopReferrersRows;
}

=head2 getTopReferrersRows

Gets the 

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::Manager object

=item B<Returns :>

   1. $TopReferrers

=back

=cut

#############################################
sub getTopSearchesRows {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in List::Admin::Reports::getTopSearchesRows");

   my $SearchHistoryObj = $self->{DBManager}->getTableObj("SearchHistory");
   my $TopSearches = $SearchHistoryObj->getTopSearches($Lists::SETUP::SEARCHES_REPORT_LIMIT);

   my $TopSearchesRows = "";
   foreach my $Query(sort{$TopSearches->{$b}->{Count} <=> $TopSearches->{$a}->{Count}} keys %{$TopSearches}) {

      $TopSearchesRows .= qq~<tr>
                              <td class="StatsTableData">$TopSearches->{$Query}->{Query}</td>
                              <td class="StatsTableData">$TopSearches->{$Query}->{Count}</td>
                              <td class="StatsTableData">$TopSearches->{$Query}->{ResultsCount}</td></tr>
                           ~;
   }

   return $TopSearchesRows;
}

=head2 getRecentSearchesRows

Gets the 

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::Manager object

=item B<Returns :>

   1. $TopReferrers

=back

=cut

#############################################
sub getRecentSearchesRows {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in List::Admin::Reports::getRecentSearchesRows");

   my $SearchHistoryObj = $self->{DBManager}->getTableObj("SearchHistory");
   my $RecentSearches = $SearchHistoryObj->getRecentSearches($Lists::SETUP::SEARCHES_REPORT_LIMIT);

   my $Date;
   my $RecentSearchesRows = "";
   foreach my $ID(sort{$RecentSearches->{$b}->{Date} <=> $RecentSearches->{$a}->{Date}} keys %{$RecentSearches}) {
      $Date = Lists::Utilities::Date::getShortHumanFriendlyDate($RecentSearches->{$ID}->{Date});
      $RecentSearchesRows .= qq~<tr>
                              <td class="StatsTableData">$RecentSearches->{$ID}->{Query}</td>
                              <td class="StatsTableData">$RecentSearches->{$ID}->{Count}</td>
                              <td class="StatsTableData">$RecentSearches->{$ID}->{ResultsCount}</td>
                              <td class="StatsTableData">$Date</td></tr>
                           ~;
   }

   return $RecentSearchesRows;
}

=head2 getComplaintsAgainstUserRows

Gets the compaints against the user passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::Manager object

=item B<Returns :>

   1. $TopReferrers

=back

=cut

#############################################
sub getComplaintsAgainstUserRows {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in List::Admin::Reports::getComplaintsAgainstUserRows");

   my $ComplaintsObj = $self->{DBManager}->getTableObj("ComplaintsAgainstUser");
   my $Complaints = $ComplaintsObj->get_with_restraints("UserID = $UserID");

   my $InfractionObj = $self->{DBManager}->getTableObj("Infraction");
   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $AdminUserObj = $self->{DBManager}->getTableObj("AdminUser");

   my $ComplaintsRows = "";
   foreach my $ID(sort keys %{$Complaints}) {
      my $Infraction = $InfractionObj->get_field_by_ID("Name", $Complaints->{$ID}->{InfractionID});
      my $User = $UserObj->get_field_by_ID("Username", $Complaints->{$ID}->{UserID});
      my $ReportingUser = $UserObj->get_field_by_ID("Username", $Complaints->{$ID}->{ReportingUserID});
      my $AdminUser = $AdminUserObj->get_field_by_ID("Username", $Complaints->{$ID}->{AdminUser});
      my $Date = Lists::Utilities::Date::getHumanFriendlyDate($Complaints->{$ID}->{CreateDateFormatted});

      $ComplaintsRows .= qq~<tr><td class="StatsTableData">$Date</td>
                                 <td class="StatsTableData">$Infraction</td>
                                 <td class="StatsTableData"><a href="/user.html?UserID=$Complaints->{$ID}->{UserID}">
                                     $User</a></td>
                                 <td class="StatsTableData"><a href="/user.html?UserID=$Complaints->{$ID}->{ReportingUserID}">
                                     $ReportingUser</td>
                                 <td class="StatsTableData">$AdminUser</td>
                                 <td class="StatsTableData">$Complaints->{$ID}->{Note}</td>
                                 <td class="StatsTableData"><a href="/feedback.html?FeedbackID=$Complaints->{$ID}->{FeedbackID}">Feedback ID:
                                     $Complaints->{$ID}->{FeedbackID}</a></td></tr>
                           ~;
   }

   return $ComplaintsRows;
}

=head2 getPopularUsersRows

Gets the html for the rows of the popular users report

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::Manager object

=item B<Returns :>

   1. $PopularUsers

=back

=cut

#############################################
sub getPopularUsersRows {
#############################################
   my $self = shift;
   
   $self->{Debugger}->debug("in List::Admin::Reports::getPopularUserRows");

   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $PopularUsers = $UserObj->getPopularUsers();
   my $PopularUsersRows = ""; my $count = 1;
   foreach my $ID(sort{$PopularUsers->{$b}->{PopularityScore} <=> $PopularUsers->{$a}->{PopularityScore}} keys %{$PopularUsers}) {
      $self->{UserManager}->getUserInfo($PopularUsers->{$ID});

      $PopularUsersRows .= qq~<tr><td class="StatsTableData">$count</td>
                                 <td class="StatsTableData">$ID</td>
                                 <td class="StatsTableData"><a href="/user.html?UserID=$ID">
                                     $PopularUsers->{$ID}->{Username}</a></td>
                                 <td class="StatsTableData">$PopularUsers->{$ID}->{PopularityScore}</td>
                                 <td class="StatsTableData">$PopularUsers->{$ID}->{ActivityScore}</td>
                                 <td class="StatsTableData">$PopularUsers->{$ID}->{ListsCount}</td>
                                 <td class="StatsTableData">$PopularUsers->{$ID}->{PublicListItemsCount}</td>
                                 <td class="StatsTableData">$PopularUsers->{$ID}->{CommentCount}</td>
                                 <td class="StatsTableData">$PopularUsers->{$ID}->{FeedbackSubmitted}</td>
                                 <td class="StatsTableData">$PopularUsers->{$ID}->{Logins}</td></tr>
                                 ~;
   }

   return $PopularUsersRows;
}

=head2 getTroublesomeUsersRows

Gets the html for the rows of the Troublesome users report

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::Manager object

=item B<Returns :>

   1. $TroublesomeUsers

=back

=cut

#############################################
sub getTroublesomeUsersRows {
#############################################
   my $self = shift;
   
   $self->{Debugger}->debug("in List::Admin::Reports::getTroublesomeUserRows");

   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $TroublesomeUsers = $UserObj->getTroublesomeUsers();
   my $TroublesomeUsersRows = ""; my $count = 1;
   foreach my $ID(sort{$TroublesomeUsers->{$b}->{TroublesomeityScore} <=> $TroublesomeUsers->{$a}->{TroublesomeityScore}} keys %{$TroublesomeUsers}) {

      $TroublesomeUsersRows .= qq~<tr><td class="StatsTableData">$count</td>
                                 <td class="StatsTableData">$ID</td>
                                 <td class="StatsTableData"><a href="/user.html?UserID=$ID">
                                     $TroublesomeUsers->{$ID}->{Username}</a></td>
                                 <td class="StatsTableData">$TroublesomeUsers->{$ID}->{Count}</td>
                                 <td class="StatsTableData">n/a</td>
                                 ~;
   }

   return $TroublesomeUsersRows;
}

=head2 getPopularListRows

Gets the html for data rows the popular lists report

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::Manager object

=item B<Returns :>

   1. $PopularListRows

=back

=cut

#############################################
sub getPopularListRows {
#############################################
   my $self = shift;
   
   $self->{Debugger}->debug("in List::Admin::Reports::getPopularListRows");
   
   my $ListObj = $self->{DBManager}->getTableObj("List");
   my $PopularLists = $ListObj->getPopularLists();
   my $PopularListRows = ""; my $count = 1;
   foreach my $ID(sort{$PopularLists->{$b}->{'24Hours'} <=> $PopularLists->{$a}->{'24Hours'}} keys %{$PopularLists}) {
      $self->{Calculator}->getListInfo($PopularLists->{$ID});

      $PopularLists->{$ID}->{ListRating} =~ s/<\/td><td valign="bottom">/<\/td><\/tr><tr><td valign="bottom">/;

      $PopularListRows .= qq~<tr><td class="StatsTableData">$count</td>
                                 <td class="StatsTableData">$ID</td>
                                 <td class="StatsTableData"><a href="$Lists::SETUP::URL$PopularLists->{$ID}->{ListURL}">
                                     $PopularLists->{$ID}->{Name}</a></td>
                                 <td class="StatsTableData"><a href="/user.html?UserID=$PopularLists->{$ID}->{UserID}">
                                     $PopularLists->{$ID}->{Username}</a></td>
                  		 <td class="StatsTableData">$PopularLists->{$ID}->{'24Hours'}</td>
                                 <td class="StatsTableData">$PopularLists->{$ID}->{'AllTime'}</td>
                                 <td class="StatsTableData">$PopularLists->{$ID}->{ListItemCount}</td>
                                 <td class="StatsTableData">$PopularLists->{$ID}->{ListHits}->{OnSite}</td>
                                 <td class="StatsTableData">$PopularLists->{$ID}->{ListHits}->{OffSite}</td>
                                 <td class="StatsTableData">$PopularLists->{$ID}->{ListEmails}</td>
                                 <td class="StatsTableData">$PopularLists->{$ID}->{ListRating}</td>
                                 <td class="StatsTableData">$PopularLists->{$ID}->{ListComments}</td>
                                 ~;
      $count++;
   }

   return $PopularListRows;
}

=head2 getUserSettingsReport

Returns the full html for the user settings report for the userid passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Printer object
   2. $UserID - The UserID

=item B<Returns :>

   1. $UserSettings - The HTML for the User Settings report

=back

=cut

#############################################
sub getUserSettingsReport {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in List::Admin::Reports::getUserSettingsReport");

   my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings");
   my $Settings = $UserSettingsObj->get_with_restraints("UserID = $UserID");

   my $UserSettings;
   foreach my $ID(keys %{$Settings}) {
      if($Settings->{$ID}->{UserID} == $UserID ){
         $UserSettings = $Settings->{$ID};
      }
   }

   my $birthDayDone = 0;
   my $html = qq~<table class="StatsTable">~;
   foreach my $field (sort keys %{$UserSettings}) {
      my $value; my $niceField;
      if($field eq "UserID" || $field eq "Status"){
         next;
      }
      
      if($field =~ m/(\w+)ID$/){
         my $table = $1;
         $niceField = $table;
         if($UserSettings->{$field}){
            my $tableObj = $self->{DBManager}->getTableObj($table);
            $value = $tableObj->get_field_by_ID("Name", $UserSettings->{$field});
         }
      }elsif($field =~ m/Birth/){
         if(!$birthDayDone){
            $niceField = "Birth day";
            $value = "$UserSettings->{'BirthDay'}/$UserSettings->{'BirthMonth'}/$UserSettings->{'BirthYear'}";
            $birthDayDone = 1;
         }else{
            $value = "null";
         }
         
      }elsif($field eq "Avatar"){
         $niceField = $field;
         $value = "<img src='$Lists::SETUP::URL/$Lists::SETUP::USER_CONTENT_PATH/$UserSettings->{$field}' />";
      }elsif($UserSettings->{$field} eq "0" || $UserSettings->{$field} eq "1"){
         $niceField = $field;
         if($UserSettings->{$field} == 0){
            $value = "Yes";
         }else{
            $value = "No";
         }
      }else{
         $niceField = $field;
         $value = $UserSettings->{$field};
      }

      if($value ne "null"){
         $html .= qq~ <tr><td class="StatsTableHeader">$niceField</td><td class="StatsTableData">$value</td></tr>~;
      }      
   }
   $html .= "</table>";

   return $html;
}

=head2 getPopularListBreakdownRows

Returns the HTML for the breakdown of the given users most popular lists

=over 4

=item B<Parameters :>

   1. $self - Reference to a Printer object
   2. $UserID - The UserID

=item B<Returns :>

   1. $PopularListBreakdown - The html for the report

=back

=cut

#############################################
sub getPopularListBreakdownRows {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in List::Admin::Reports::getPopularListBreakdownRows");

   my $ListObj = $self->{DBManager}->getTableObj("List");
   my $PopularLists = $ListObj->getPopularLists($UserID);
   my $PopularListRows = ""; my $count = 1;
   foreach my $ID(sort{$PopularLists->{$b}->{PopularityScore} <=> $PopularLists->{$a}->{PopularityScore}} keys %{$PopularLists}) {
      $self->{Calculator}->getListInfo($PopularLists->{$ID});

      $PopularLists->{$ID}->{ListRating} =~ s/<\/td><td valign="bottom">/<\/td><\/tr><tr><td valign="bottom">/;

      $PopularListRows .= qq~<tr><td class="StatsTableData">$count</td>
                                 <td class="StatsTableData">$ID</td>
                                 <td class="StatsTableData"><a href="$Lists::SETUP::URL/lists.html?ListID=$ID">
                                     $PopularLists->{$ID}->{Name}</a></td>
                                 <td class="StatsTableData">$PopularLists->{$ID}->{PopularityScore}</td>
                                 <td class="StatsTableData">$PopularLists->{$ID}->{ListItemCount}</td>
                                 <td class="StatsTableData">$PopularLists->{$ID}->{TotalListHits}</td>
                                 <td class="StatsTableData">$PopularLists->{$ID}->{ListEmails}</td>
                                 <td class="StatsTableData">$PopularLists->{$ID}->{ListRating}</td>
                                 <td class="StatsTableData">$PopularLists->{$ID}->{ListComments}</td>
                                 ~;
      $count++;
   }

   return $PopularListRows;
}

1;

=head1 AUTHOR INFORMATION

   Author: Marilyn Burgess with help from the ApplicationFramework
   Created: 1/11/2007

=head1 BUGS

   Not known

=cut



