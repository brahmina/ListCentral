package ListCentral::DB::Comment;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::Comment 
##########################################################

=head1 NAME

   ListCentral::DB::Comment.pm

=head1 SYNOPSIS

   $Comment = new ListCentral::DB::Comment($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the Comment table in the 
Lists database.


=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::AdImpressions::init");

   my @Fields = ("CreateDate", "Commenter", "CommenterID", "Status", "Comment", "ListID");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ("Comment");
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;
}


=head2 getListComments

Gets the list comments for the given list, returns hash and total comments on list

Ensures only comments by valid users are pulled

Does pagenation

=over 4

=item B<Parameters :>

   1. $self - Reference to a Comment object
   2. $List - Reference to a hash with the List info
   3. $page - What page it's on

=item B<Returns: >

   1. $ListComments - Reference to a hash with the list comments for the page
   2. $ListCommentCount - The total number of comments on the list

=back

=cut

#############################################
sub getListComments {
#############################################
   my $self = shift;
   my $List = shift;
   my $page = shift;

   $self->{Debugger}->debug("in ListCentral::DB::Comment::getListComments");

   my $ListID = $List ->{ID};
   my $CommentCount = $self->getListCommentCount($List->{ID});

   my $pageCount = int($CommentCount / $ListCentral::SETUP::CONSTANTS{'COMMENT_LIMIT_PER_PAGE'});
   if($CommentCount % $ListCentral::SETUP::CONSTANTS{'COMMENT_LIMIT_PER_PAGE'}){
      $pageCount++;
   }

   my $start = ($page - 1) * $ListCentral::SETUP::CONSTANTS{'COMMENT_LIMIT_PER_PAGE'}; 
   my $limit = $start . ", " . $ListCentral::SETUP::CONSTANTS{'COMMENT_LIMIT_PER_PAGE'};

   my %ListComments;
   my $sql = "SELECT Comment.* 
              FROM $ListCentral::SETUP::DB_NAME.Comment, $ListCentral::SETUP::DB_NAME.User
              WHERE Comment.CommenterID = User.ID AND
                    ListID = $ListID AND
                    User.Status > 0 AND Comment.Status > 0
              ORDER BY CreateDate DESC
              LIMIT $limit";
   $self->{Debugger}->debug("sql: $sql");
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $ListComments{$hash->{ID}} = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with Comment COUNT: $sql\n");
   }
   $stm->finish;

   return (\%ListComments, $pageCount);
}


=head2 getListCommentCount

Gets the list comments for the given list, returns hash and total comments on list

=over 4

=item B<Parameters :>

   1. $self - Reference to a Comment object
   2. $List - Reference to a hash with the List info
   3. $page - What page it's on

=item B<Returns: >

   1. $ListComments - Reference to a hash with the list comments for the page
   2. $ListCommentCount - The total number of comments on the list

=back

=cut

#############################################
sub getListCommentCount {
#############################################
   my $self = shift;
   my $ListID = shift;

   $self->{Debugger}->debug("in ListCentral::DB::Comment::getListCommentCount");

   my $CommentCount;
   my $sql = "SELECT COUNT(Comment.ID) AS Count 
              FROM $ListCentral::SETUP::DB_NAME.Comment, $ListCentral::SETUP::DB_NAME.User
              WHERE Comment.CommenterID = User.ID AND
                    ListID = $ListID AND
                    User.Status > 0 AND Comment.Status > 0";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $CommentCount = $hash->{Count};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with Comment COUNT: $sql\n");
   }
   $stm->finish;

   return $CommentCount;
}

=head2 getRecentComments

Get recent comments for the side bar widget

Same as getActiveUsers right now

=over 4

=item B<Parameters :>

   1. $self - Reference to a User object

=item B<Returns :>

   1. $RecentComment - Reference to a hash with the recent comments

=back

=cut

#############################################
sub getRecentComments {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::User::getRecentComments");

   my %RecentComments;
   my $sql = "SELECT Comment.ID, Comment, Commenter, CommenterID, Comment.ListID, ListGroup.Name AS ListGroup, 
                     List.Name AS ListName, Comment.CreateDate
              FROM $ListCentral::SETUP::DB_NAME.Comment, $ListCentral::SETUP::DB_NAME.List, $ListCentral::SETUP::DB_NAME.User, $
                   ListCentral::SETUP::DB_NAME.ListGroup
              WHERE Comment.Status > 0 AND List.Status > 0 AND User.Status > 0 AND
                    Comment.ListID = List.ID AND Comment.CommenterID = User.ID AND 
                    List.ListGroupID = ListGroup.ID AND List.Public = 1
              ORDER BY Comment.CreateDate DESC 
              LIMIT $ListCentral::SETUP::CONSTANTS{RECENT_COMMENTS_WIDGET_LIMIT}";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $RecentComments{$hash->{ID}} = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with RecentComments: $sql\n");
   }
   $stm->finish;

   return \%RecentComments;
}


1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


