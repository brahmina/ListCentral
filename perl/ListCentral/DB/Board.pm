package ListCentral::DB::Board;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::Board 
##########################################################

=head1 NAME

   ListCentral::DB::Board.pm

=head1 SYNOPSIS

   $Board = new ListCentral::DB::Board($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the Board table in the 
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

   my @Fields = ("CreateDate", "UserID", "PosterUserID", "Status", "Message");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ("Message");
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;
}

=head2 getBoardMessages

Gets the board messages for user given, returns hash and total board posts.

Ensures that only messages by valid users are pulled

=over 4

=item B<Parameters :>

   1. $self - Reference to a Board object
   2. $UserID - The userID of the board owner
   3. $page - What page it's on

=item B<Returns: >

   1. $BoardMessages - Reference to a hash with the list comments for the page
   2. $BoardPageCount - The total number of board pages

=back

=cut

#############################################
sub getBoardMessages {
#############################################
   my $self = shift;
   my $UserID = shift;
   my $page = shift;

   $self->{Debugger}->debug("in ListCentral::DB::Board::getBoardMessages");

   my $BoardMessageCount;
   my $sql = "SELECT COUNT(Board.ID) AS Count 
              FROM $ListCentral::SETUP::DB_NAME.Board, $ListCentral::SETUP::DB_NAME.User
              WHERE Board.PosterUserID = User.ID AND
                    UserID = $UserID AND
                    User.Status > 0 AND Board.Status > 0";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $BoardMessageCount = $hash->{Count};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with Board COUNT: $sql\n");
   }
   $stm->finish;

   my $pageCount = int($BoardMessageCount / $ListCentral::SETUP::CONSTANTS{'BOARD_POSTS_PER_PAGE'});
   if($BoardMessageCount % $ListCentral::SETUP::CONSTANTS{'BOARD_POSTS_PER_PAGE'}){
      $pageCount++;
   }

   my $start = ($page - 1) * $ListCentral::SETUP::CONSTANTS{'BOARD_POSTS_PER_PAGE'}; 
   my $limit = $start . ", " . $ListCentral::SETUP::CONSTANTS{'BOARD_POSTS_PER_PAGE'};

   my %BoardPosts;
   my $sql = "SELECT Board.* 
              FROM $ListCentral::SETUP::DB_NAME.Board, $ListCentral::SETUP::DB_NAME.User
              WHERE Board.PosterUserID = User.ID AND
                    UserID = $UserID AND
                    User.Status > 0 AND Board.Status > 0
              ORDER BY CreateDate DESC
              LIMIT $limit";
   $self->{Debugger}->debug("sql: $sql");
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $BoardPosts{$hash->{ID}} = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with Board COUNT: $sql\n");
   }
   $stm->finish;

   return (\%BoardPosts, $pageCount);
}


1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


