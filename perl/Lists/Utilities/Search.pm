package Lists::Utilities::Search;
use strict;

use Lists::SETUP;

##########################################################
# Lists::Utilities::Search 
##########################################################

=head1 NAME

   Lists::Mailer.pm

=head1 SYNOPSIS

   $Mailer = new Lists::Utilities::Search(Debugger);

=head1 DESCRIPTION

Used to create, manage, and send emails for the Lists system.

=head2 Lists::Utilities::Search Constructor

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

   $self->{Debugger}->debug("in Lists::Mailer constructor");
   
   return ($self); 
}

=head2 doBasicListSearch

Builds and executes a seach on an SQL table and returns the results in a hash

1. Full list name match
2. Partial list name match
3. Full list item match
4. Partial list item match

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager::Utilities::Search object
   2. $Query - the query
   3. $Page
   4. $IncludeUsersPrivateLists

=item B<Returns :>

   1. $ResultsHash - Reference to the results hash

=back

=cut

#############################################
sub doBasicListSearch {
#############################################
   my $self = shift;
   my $Query = shift;
   my $Page = shift;
   my $IncludeUsersPrivateLists = shift;

   #  Need a number of items per page variable
   my $Limit = $Lists::SETUP::CONSTANTS{'DEFAULT_LIST_SEARCH_RESULTS_PER_PAGE'};

   $self->{Debugger}->debug("in Lists::Utilities::Search::doBasicSearch with $Query, $Page, $IncludeUsersPrivateLists");

   my $QuerySave = $Query;

   # Trim surrounding white space
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

   my $AndWhereClauseList = "";
   my $OrWhereClauseList = "";
   my $AndWhereClauseListItem = "";
   my $OrWhereClauseListItem = "";
   foreach my $term (@search_terms) {
      $AndWhereClauseList .= "(List.Name LIKE \"$term%\" OR List.Name LIKE \"% $term%\") AND";
      $OrWhereClauseList .= "(List.Name LIKE \"$term%\" OR List.Name LIKE \"% $term%\") OR";
      $AndWhereClauseListItem .= "(ListItem.Name LIKE \"$term%\" OR ListItem.Name LIKE \"% $term%\") AND";
      $OrWhereClauseListItem .= "(ListItem.Name LIKE \"$term%\" OR ListItem.Name LIKE \"% $term%\") OR";
   }
   $AndWhereClauseList =~ s/ AND$//;
   $OrWhereClauseList =~ s/ OR$//;
   $AndWhereClauseListItem =~ s/ AND$//;
   $OrWhereClauseListItem =~ s/ OR$//;

   my $LoggedInUserClause = "";
   if($self->{UserManager}->{ThisUser}->{ID} && $IncludeUsersPrivateLists){
      $LoggedInUserClause = "OR UserID = $self->{UserManager}->{ThisUser}->{ID}";
   }

   my %results;
   my $count = 0;
   my $sql = "SELECT List.*
              FROM $Lists::SETUP::DB_NAME.List, $Lists::SETUP::DB_NAME.ListPoints, $Lists::SETUP::DB_NAME.User
              WHERE (List.Name LIKE \"$Query%\" OR List.Name LIKE \"% $Query%\") AND List.Status = 1 AND (Public = 1 $LoggedInUserClause)
                     AND List.ID = ListPoints.ListID 
                     AND List.UserID = User.ID AND User.Status > 0
              ORDER BY RankingReddit DESC, CreateDate DESC
              LIMIT $Limit";
   $count += $self->runSQLSelect($sql, $count, \%results);

   if($AndWhereClauseList ne "" && $count < $Lists::SETUP::CONSTANTS{'DEFAULT_LIST_SEARCH_RESULTS_PER_PAGE'}){
      # Full list name match
      my $sql = "SELECT List.*
                 FROM $Lists::SETUP::DB_NAME.List, $Lists::SETUP::DB_NAME.ListPoints, $Lists::SETUP::DB_NAME.User
                 WHERE ($AndWhereClauseList) AND List.Status = 1 AND (Public = 1 $LoggedInUserClause)
                        AND List.ID = ListPoints.ListID
                        AND List.UserID = User.ID AND User.Status > 0
                 ORDER BY RankingReddit DESC, CreateDate DESC
                 LIMIT $Limit";
      $count += $self->runSQLSelect($sql, $count, \%results);
   }else{
      die "No where clause?!?!";
   }

   if($count < $Lists::SETUP::CONSTANTS{'DEFAULT_LIST_SEARCH_RESULTS_PER_PAGE'} && !$OneWordQuery){
      # Partial list name match
      my $sql = "SELECT List.*
                 FROM $Lists::SETUP::DB_NAME.List, $Lists::SETUP::DB_NAME.ListPoints, $Lists::SETUP::DB_NAME.User
                 WHERE ($OrWhereClauseList) AND List.Status = 1 AND (Public = 1 $LoggedInUserClause)
                        AND List.ID = ListPoints.ListID
                        AND List.UserID = User.ID AND User.Status > 0
                 ORDER BY RankingReddit DESC, CreateDate DESC
                 LIMIT $Limit";
      $count += $self->runSQLSelect($sql, $count, \%results);
   }

   if($count < $Lists::SETUP::CONSTANTS{'DEFAULT_LIST_SEARCH_RESULTS_PER_PAGE'}){
      # Full list item match
      my $sql = "SELECT List.*
                 FROM $Lists::SETUP::DB_NAME.ListItem, $Lists::SETUP::DB_NAME.List, $Lists::SETUP::DB_NAME.ListPoints, $Lists::SETUP::DB_NAME.User
                 WHERE ($AndWhereClauseListItem) AND ListItemStatusID != 0 AND (Public = 1 $LoggedInUserClause) 
                        AND List.Status = 1 AND $Lists::SETUP::DB_NAME.ListItem.ListID = $Lists::SETUP::DB_NAME.List.ID AND $Lists::SETUP::DB_NAME.List.ID = $Lists::SETUP::DB_NAME.ListPoints.ListID
                        AND List.UserID = User.ID AND User.Status > 0
                 ORDER BY RankingReddit DESC, CreateDate DESC
                 LIMIT $Limit";
      $count += $self->runSQLSelect($sql, $count, \%results);
   }

   $count = scalar keys %results; 
   if($count < $Lists::SETUP::CONSTANTS{'DEFAULT_LIST_SEARCH_RESULTS_PER_PAGE'} && !$OneWordQuery){
      # Partial list item match
      my $sql = "SELECT List.*
                 FROM $Lists::SETUP::DB_NAME.ListItem, $Lists::SETUP::DB_NAME.List, $Lists::SETUP::DB_NAME.ListPoints, $Lists::SETUP::DB_NAME.User
                 WHERE ($OrWhereClauseListItem) AND ListItemStatusID != 0 AND (Public = 1 $LoggedInUserClause)
                        AND List.Status = 1 AND $Lists::SETUP::DB_NAME.ListItem.ListID = $Lists::SETUP::DB_NAME.List.ID AND $Lists::SETUP::DB_NAME.List.ID = $Lists::SETUP::DB_NAME.ListPoints.ListID
                        AND List.UserID = User.ID AND User.Status > 0
                 ORDER BY RankingReddit DESC, CreateDate DESC
                 LIMIT $Limit";
      $count += $self->runSQLSelect($sql, $count, \%results);
   }

   # Record the search
   my $SearchHistoryObj = $self->{DBManager}->getTableObj("SearchHistory");
   my %SearchHistory = ("SearchHistory.Query" => $QuerySave, 
                        "SearchHistory.UserID" => $self->{UserManager}->{ThisUser}->{ID},
                        "SearchHistory.ResultsCount" => $count,
                        "SearchHistory.Status" => 1,
                        );
   $SearchHistoryObj->store(\%SearchHistory);

   return ($count, \%results);
}

=head2 doBasicUserSearch

Builds and executes a seach on an SQL table and returns the results in a hash

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager::Utilities::Search object
   2. $Query - the query

=item B<Returns :>

   1. $ResultsHash - Reference to the results hash

=back

=cut

#############################################
sub doBasicUserSearch {
#############################################
   my $self = shift;
   my $Query = shift;

   #  Need a number of items per page variable
   my $Limit = $Lists::SETUP::CONTSTANTS{'DEFAULT_USER_SEARCH_RESULTS_PER_PAGE'};

   $self->{Debugger}->debug("in Lists::Utilities::Search::doBasicSearch with $Query");

   # Trim surrounding white space
   $Query =~ s/^\s+//;
   $Query =~ s/\s+$//;
   my @search_terms = split (/\s/, $Query);

   my %results;
   my $count = 0;
   my $sql = "SELECT *
              FROM $Lists::SETUP::DB_NAME.User 
              WHERE (Name LIKE \"$Query%\" OR Name LIKE \"%$Query%\") OR 
                    (Username LIKE \"$Query%\" OR Username LIKE \"%$Query%\") AND Status = 1
              ORDER BY Name
              LIMIT $Limit";
   $count = $self->runSQLSelect($sql, $count, \%results);

   foreach my $ID(keys %results) {
      $results{$ID}->{FormattedCreateDate} = Lists::Utilities::Date::getHumanFriendlyDate{$results{$ID}->{CreateDate}};
   }

   return \%results;
}

=head2 doAdminUserSearch

Builds and executes a seach on the Users SQL table and returns the results in a hash for the admin system

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager::Utilities::Search object
   2. $Query - the query

=item B<Returns :>

   1. $ResultsHash - Reference to the results hash

=back

=cut

#############################################
sub doAdminUserSearch {
#############################################
   my $self = shift;
   my $Query = shift;

   $self->{Debugger}->debug("in Lists::Utilities::Search::doBasicSearch with $Query");

   # Trim surrounding white space
   $Query =~ s/^\s+//;
   $Query =~ s/\s+$//;
   my @search_terms = split (/\s/, $Query);

   my %results;
   my $count = 0;
   my $sql = "SELECT *
              FROM $Lists::SETUP::DB_NAME.User 
              WHERE Name LIKE \"$Query%\" OR Username LIKE \"$Query%\" 
                    OR Name LIKE \"$Query\" OR Username LIKE \"$Query\" 
                    AND Status = 1
              ORDER BY Name";
   $count = $self->runSQLSelect($sql, $count, \%results);

   foreach my $ID(keys %results) {
      $results{$ID}->{FormattedCreateDate} = Lists::Utilities::Date::getHumanFriendlyDate{$results{$ID}->{CreateDate}};
   }

   return \%results;
}

=head2 runSQLSelect

Runs a selete statement

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager::Utilities::Search object
   2. $Query - the query

=item B<Returns :>

   1. $ResultsHash - Reference to the results hash

=back

=cut

#############################################
sub runSQLSelect {
#############################################
   my $self = shift;
   my $sql = shift;
   my $count = shift;
   my $results = shift;

   $self->{Debugger}->debug("in Lists::Utilities::Search::runSQLSelect with $sql");

   my $stm = $self->{DBManager}->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         if(!$results->{$hash->{ID}}){
            $results->{$hash->{ID}} = $hash;
            $results->{$hash->{ID}}->{SearchOrder} = $count;
            $count++;
         }
      }
   }else{
     $self->{Debugger}->throwNotifyingError("ERROR with SEARCH SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   return $count;
}

=head2 processSearchResults

Processes a set of search results given a hash ref and template, and returns html

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager::Utilities::Search object
   2. $TemplateRows - the search results template for one row of results
   2. $ResultsHash - Reference to the hash of the results being process
   3. $Limit - the max number of results to return

=item B<Returns :>

   1. $Results - The results in html

=back

=cut

#############################################
sub processSearchResults {
#############################################
   my $self = shift;
   my $TemplateRows = shift;
   my $ResultsHash = shift;
   my $Limit = shift;

   $self->{Debugger}->debug("in Lists::Utilities::Search::processSearchResults with $TemplateRows, $Limit");

   my $Template;
   open(ROW, $TemplateRows) || $self->{Debugger}->log("cannot open file: $TemplateRows - $!");
   my @RowLinesSave = <ROW>;
   close ROW;

   my $Rows = "";
   my $count = 0;
   foreach my $id(sort{$ResultsHash->{$a}->{SearchOrder} <=> $ResultsHash->{$b}->{SearchOrder}}keys %{$ResultsHash}) {
      my $html = "";
      my @RowLines = @RowLinesSave;
      foreach my $line(@RowLines) {
         if($line =~ m/<!--(\w+)-->/){
            my $field = $1;
            if($field eq "Which"){  
               my $which = "A";
               if($count % 2 == 0){
                  $which = "B";
               }
               $count++;
               $line =~ s/<!--$field-->/$which/;
            }else{
               if($field eq "Tags" && $ResultsHash->{$id}->{$field}){
                  $ResultsHash->{$id}->{$field} = "Tags: $ResultsHash->{$id}->{$field}";
               }
               $line =~ s/<!--$field-->/$ResultsHash->{$id}->{$field}/;
            }
         }
         $html .= $line;
      }
      $Rows .= $html;
   }
   if($Rows eq ""){
      if($self->{cgi}->{IncludeUsersPrivateLists}){
         $Rows = "<center><br />Your request did not match any lists :(</center>";
      }else{
         $Rows = "<center><br />Your request did not match any public lists :(</center>";
      }      
   }
   return $Rows;
}

=head2 getPagenation

Given a page and a page count, returns the pagenation to be dispalyed at the bottom of the page

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager::Utilities::Search object
   2. $Page - the search results template for one row of results
   3. $PageCount - The number of pages 

=item B<Returns :>

   1. $Results - The results in html

=back

=cut

#############################################
sub getPagenation {
#############################################
   my $self = shift;
   my $page = shift;
   my $pageCount = shift;
   my $link = shift;
   my $pagename = shift;
   my $pageparam = shift;

   $self->{Debugger}->debug("in Lists::Utilities::Search::getPagenation with $page, $pageCount");

   my $Pagenation = "";

   my $first = $page - 2;
   if($first <= 0){
      $first = 1;
   }
   my $last = $page + 2;
   if($last > $pageCount){
      $last = $pageCount;
   }

   my $firstBunch = "";
   if($first > 2){
      my $linkhere1 = $link . $pagename . "1.html" . $pageparam;
      my $linkhere2 = $link . $pagename . "2.html" . $pageparam;
      $firstBunch = qq~<a href="$linkhere1">1</a>
                       <a href="$linkhere1">2</a>
                       ~;
      if($first > 3){
         $firstBunch .= qq~<span class="dots">...</span>~;
      }         
   }elsif($first == 2){
      my $linkhere = $link . $pagename . "1.html" . $pageparam;
      $firstBunch = qq~<a href="$linkhere">1</a>~;
   }

   my $lastBunch = "";
   if($last < $pageCount){
      my $secondLast = $pageCount - 1;
      if($last < ($pageCount - 2)){
         $lastBunch .= qq~<span class="dots">...</span>~;
      }
      my $linkhere1 = $link . $pagename . "$secondLast.html" . $pageparam;
      if($last < ($pageCount - 1)){
         $lastBunch .= qq~<a href="$linkhere1">$secondLast</a>~;
      }      
      my $linkhere2 = $link . $pagename . "$pageCount.html" . $pageparam;
      $lastBunch .= qq~<a href="$linkhere2">$pageCount</a>~;
   }

   my $middle = "";
   my $count = $first;

   while ($count <= $last) {
      if($count == $page){
         # the current page
         $middle .= qq~<span class="current">$count</span>~;
      }else{
         my $linkhere = $link . $pagename . "$count.html" . $pageparam;
         $middle .= qq~<a href="$linkhere">$count</a>~;
      }
      $count++;
   }

   my $nextPage = "";
   if($page != $pageCount){
      my $np = $page + 1;
      my $linkhere = $link . $pagename . "$np.html" . $pageparam;
      $nextPage = qq~<a href="$linkhere" class="nextprev">Next >></a>~;
   }
   my $previousPage = "";
   if($page != 1){
      my $pp = $page - 1;
      my $linkhere = $link . $pagename . "$pp.html" . $pageparam;
      $previousPage = qq~<a href="$linkhere" class="nextprev"><< Previous</a>~;
   }

   $Pagenation = qq~<div class="Pagination">
                     $previousPage $firstBunch $middle $lastBunch $nextPage
                  </div>~; 

   return $Pagenation;
}


1;

=head1 AUTHOR INFORMATION

   Author:  With help from the ApplicationFramework
   Last Updated: 22/10/2007

=head1 BUGS

   Not known

=cut



