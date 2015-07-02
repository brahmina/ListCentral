package Lists::DB::ListRatings;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::ListRatings 
##########################################################

=head1 NAME

   Lists::DB::ListRatings.pm

=head1 SYNOPSIS

   $ListRatings = new Lists::DB::ListRatings($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the ListRatings table in the 
Lists database.


=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::ListRatings::init");

   my @Fields = ("CreateDate", "IP", "ListID", "Rating", "UserID");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;
}

=head2 getListRatingsHTML

Calculates the photograph rating for the photgraph specified and returns the 
corresponding HTML

=over 4

=item B<Parameters :>

   1. $self - Reference to a MarilynBurgess::PhotographRating object
   2. $ID - The List id

=item B<Prints :>

   1. $html - the requested html

=back

=cut

#############################################
sub getListRatingsHTML {
#############################################
   my $self = shift;
   my $ListID = shift;
   my $Clickable = shift;

   $self->{Debugger}->debug("in Lists::DB::ListRatings::getListRatingsHTML with ListID: $ListID");
   my $rating_sum = 0;
   my $sql_rating_sum = "SELECT SUM(Rating) AS RatingSum FROM ListRatings WHERE ListID = $ListID";
   my $stm = $self->{dbh}->prepare($sql_rating_sum);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $rating_sum = $hash->{RatingSum};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("Error with Sum SELECT: $sql_rating_sum");
   }
   $stm->finish;

   my $rating_count = 0;
   my $sql_rating_count = "SELECT COUNT(Rating) AS RatingCount FROM ListRatings WHERE ListID = $ListID";
   $stm = $self->{dbh}->prepare($sql_rating_count);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $rating_count = $hash->{RatingCount};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("Error with Count SELECT: $sql_rating_count");
   }
   $stm->finish;

   my $rating = 0;
   if($rating_count){
      $rating = $rating_sum / $rating_count;
   }

   $rating = sprintf("%.2f", $rating);

   my $width = int($rating) * $Lists::SETUP::LIST_RATINGS_WIDTH;
   $width = "width:" . $width . "px;";
   my $votes = "votes";
   if($rating_count == 1){
      $votes = "vote";
   }

   my $html; my $text;
   if($Clickable){
      $html = qq~
                  <ul class="unit-rating">
                    <li class='current-rating' style="$width">&nbsp;</li>
                    <li><a href="javascript:doListRating('1','$ListID')" title="1 out of 5" class="r1-unit" >&nbsp;</a></li>
                    <li><a href="javascript:doListRating('2','$ListID')" title="2 out of 5" class="r2-unit" >&nbsp;</a></li>
                    <li><a href="javascript:doListRating('3','$ListID')" title="3 out of 5" class="r3-unit" >&nbsp;</a></li>
                    <li><a href="javascript:doListRating('4','$ListID')" title="4 out of 5" class="r4-unit" >&nbsp;</a></li>
                    <li><a href="javascript:doListRating('5','$ListID')" title="5 out of 5" class="r5-unit" >&nbsp;</a></li>
                   </ul>
               ~;
      $text = qq~ <span class="RatingsText"><strong>$rating</strong> from $rating_count $votes</span>~;
   }else{
      $html = qq~                   
                  <ul class="unit-rating">
                    <li class='current-rating' style="$width">&nbsp;</li>
                    <li><a href="javascript:alert('$Lists::SETUP::MESSAGES{NO_PERMISSION_RATE_LIST}')" title="1 out of 5" class="r1-unit" >&nbsp;</a></li>
                    <li><a href="javascript:alert('$Lists::SETUP::MESSAGES{NO_PERMISSION_RATE_LIST}')" title="2 out of 5" class="r2-unit" >&nbsp;</a></li>
                    <li><a href="javascript:alert('$Lists::SETUP::MESSAGES{NO_PERMISSION_RATE_LIST}')" title="3 out of 5" class="r3-unit" >&nbsp;</a></li>
                    <li><a href="javascript:alert('$Lists::SETUP::MESSAGES{NO_PERMISSION_RATE_LIST}')" title="4 out of 5" class="r4-unit" >&nbsp;</a></li>
                    <li><a href="javascript:alert('$Lists::SETUP::MESSAGES{NO_PERMISSION_RATE_LIST}')" title="5 out of 5" class="r5-unit" >&nbsp;</a></li>
                   </ul>
                  ~;
      $text = qq~<span class="RatingsText"><strong>$rating</strong> from $rating_count $votes</span> ~;
   }

   return $html, $text;
}

=head2 doRating

Handles the Photograph rating AJAX call

=over 4

=item B<Parameters :>

   1. $self - Reference to a MarilynBurgess::PhotographRating object
   2. $PID - The Photograph id
   3. $Rating - The rating(int between 1 and 5)

=item B<Prints :>

   1. $html - the html to be printed in the div

=back

=cut

#############################################
sub doRating {
#############################################
   my $self = shift;
   my $ListID = shift;
   my $Rating = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in Lists::DB::ListRatings::doRating with ListID: $ListID, Rating: $Rating, UserID: $UserID");

   # Check if there is a rating for this user
   my $alreadyRated = 0;
   my $Ratings = $self->get_with_restraints("ListID = $ListID AND UserID = $UserID");
   foreach my $ID(keys %{$Ratings}) {
      if($Ratings->{$ID}){
         $self->{Debugger}->debug("... this user has updated this list alredy, update it, not insert");
         # One is there, lets change this rating
         $self->update("Rating", $Rating, $ID);
         $alreadyRated = 1;
      }
   }

   if(! $alreadyRated){
      $self->{Debugger}->debug("... this is a new rating, insert it");
      my %ListRatings;
      $ListRatings{"ListRatings.ListID"} = $ListID;
      $ListRatings{"ListRatings.Rating"} = $Rating;
      $ListRatings{"ListRatings.UserID"} = $UserID;
   
      $self->store(\%ListRatings);
   }

   my ($html, $text) = $self->getListRatingsHTML($ListID, 1);

   return ($html, $text);
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 21/1/2008

=head1 BUGS

   Not known

=cut


