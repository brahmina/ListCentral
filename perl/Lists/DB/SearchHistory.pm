package Lists::DB::SearchHistory;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;

use Lists::SETUP;

##########################################################
# Lists::DB::SearchHistory 
##########################################################

=head1 NAME

   Lists::DB::SearchHistory.pm

=head1 SYNOPSIS

   $SearchHistory = new Lists::DB::SearchHistory($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the SearchHistory table in the 
Lists database.


=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::AdImpressions::init");

   my @Fields = ("Query", "Date", "UserID", "Status", "IP", "ResultsCount");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("Date");
   $self->{DateFields} = \@DateFields;
}

=head2 getRecentSearches

Gets the data for the recent searches

=over 4

=item B<Parameters :>

   1. $self - Reference to a SearchHistory object

=item B<Returns: >

   1. $Searches - Reference to a hash with the recent searhces

=back

=cut

#############################################
sub getRecentSearches {
#############################################
   my $self = shift;
   my $limit = shift;

   $self->{Debugger}->debug("in Lists::DB::SearchHistory::getRecentSearches");

   if(! $limit){
      $limit = $Lists::SETUP::CONSTANTS{'RECENT_SEARCHES_LIMIT'};
   }

   my $Order = 1;
   my %RecentSearches;
   my $sql = "SELECT Count(Query) AS Count, Query, MAX(from_unixtime(Date)) AS FormattedDate, Date, 
                     ID, ResultsCount
              FROM $Lists::SETUP::DB_NAME.SearchHistory
              WHERE Status > 0
              GROUP BY Date
              ORDER BY Date DESC
              LIMIT $limit";

   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $RecentSearches{$hash->{ID}} = $hash;
         $RecentSearches{$hash->{ID}}->{"SortOrder"} = $Order;
         $Order++;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with recent SearchHistory select: $sql\n");
   }
   $stm->finish;

   return \%RecentSearches;
}

=head2 getTopReferrers

Gets the top referrers to be displayed to the admin people

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::Manager object

=item B<Returns :>

   1. $TopReferrers

=back

=cut

#############################################
sub getTopSearches {
#############################################
   my $self = shift;
   my $limit = shift;

   $self->{Debugger}->debug("in Lists::DB::SearchHistory:: getTopSearches");

   my $count = 0;
   my %Searches;
   my $sql = "SELECT DISTINCT Query, COUNT(Query) AS Count, ResultsCount
              FROM SearchHistory 
              GROUP BY Query
              ORDER BY Count DESC 
              LIMIT $limit";

   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $Searches{$hash->{Query}} = $hash;
         $count++;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with SearchHistory SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;


   return \%Searches;
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


