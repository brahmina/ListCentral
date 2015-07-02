package Lists::DB::Tag;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::Tag 
##########################################################

=head1 NAME

   Lists::DB::Tag.pm

=head1 SYNOPSIS

   $Tag = new Lists::DB::Tag($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the Tag table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::Tag::init");

   my @Fields = ("CreateDate", "CreatedByUserID", "Status", "TagCount", "Name");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;
}   

=head2 getListsByTag

Gets a reference to a hash of lists that are tagged with the tag id passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Tag object
   2. $TagID - The TagID

=item B<Returns: >

   1. $ListsByTag - Reference to a hash with the Lists by tag data

=back

=cut

#############################################
sub getListsByTag {
#############################################
   my $self = shift;
   my $TagID = shift;
   my $page = shift;

   $self->{Debugger}->debug("in Lists::DB::Tag::getListsByTag with TagID : $TagID");

   my $limit = $Lists::SETUP::CONSTANTS{'LISTING_ROWS_LIMIT'};
   my $start = 0;
   if($page > 1){
      $start = ($limit * $page) - $limit;
   }

   my %ListsByTag;
   # Main query
   my $sql = "SELECT List.*, ListTag.*
              FROM $Lists::SETUP::DB_NAME.ListTag,  $Lists::SETUP::DB_NAME.List, $Lists::SETUP::DB_NAME.User 
              WHERE ListTag.TagID = $TagID AND ListTag.Status = 1 AND
                    List.ID = ListTag.ListID AND 
                    List.UserID = User.ID AND User.Status > 0 AND
                    List.Status = 1 AND List.Public = 1
              ORDER BY List.CreateDate DESC
              LIMIT $start, $limit";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $ListsByTag{$hash->{"ListID"}} = $hash;
         $ListsByTag{$hash->{"ListID"}}->{ID} = $hash->{ListID};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with Tag SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   # Count query
   my $ListsByTagCount;
   my $sql = "SELECT COUNT(ListID) AS Count
              FROM $Lists::SETUP::DB_NAME.ListTag, $Lists::SETUP::DB_NAME.List, $Lists::SETUP::DB_NAME.User 
              WHERE ListTag.TagID = $TagID AND ListTag.Status = 1 AND
                    List.ID = ListTag.ListID AND
                    List.UserID = User.ID AND User.Status > 0 AND 
                    List.Status = 1 AND List.Public = 1";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $ListsByTagCount = $hash->{Count};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with Tag SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   return ($ListsByTagCount, \%ListsByTag);
}

=head2 getTagURL

Gets the url for a particular tag

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $Tag - Reference to a hash with Tag info in it

=item B<Returns :>

   1. $url - The url for the requested tag

=back

=cut

#############################################
sub getTagURL {
#############################################
   my $self = shift;
   my $Tag = shift;

   $self->{Debugger}->debug("in Lists::DB::Tag->getTagURL with $Tag->{ID}");

   my $TagName = $Tag->{Name};
   $TagName =~ s/\s/_/g;
   my $TagURL .= "/tagged/$TagName/$Tag->{ID}/tag.html";

   return $TagURL;
}

=head2 getPublicTags

Joins Tag, ListTag and List to get all tags that are from only
public lists

=over 4

=item B<Parameters :>

   1. $self - Reference to a Tag object

=item B<Returns: >

   1. $Tag - Reference to a hash with the Tag data

=back

=cut

#############################################
sub getPublicTags {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::Tag::getPublicTags");

   my %Tag;
   my $sql = "SELECT distinct(Tag.Name), Tag.*
              FROM $Lists::SETUP::DB_NAME.Tag, $Lists::SETUP::DB_NAME.ListTag, $Lists::SETUP::DB_NAME.List, $Lists::SETUP::DB_NAME.User
              WHERE List.Public = 1 
                    AND List.Status > 0 AND Tag.Status > 0
                    AND Tag.ID = ListTag.TagID AND List.ID = ListTag.ListID
                    AND List.UserID = User.ID AND User.Status > 0
              ORDER BY TagCount DESC
              LIMIT $Lists::SETUP::CONSTANTS{'THREE_D_TAG_CLOUD_LIMIT'}";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $Tag{$hash->{ID}} = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with Tag SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   return \%Tag;
}

=head2 getListTags

Gets the tags of a certain list

=over 4

=item B<Parameters :>

   1. $self - Reference to a Tag object

=item B<Returns :>

   1. $html - The html of the list tags

=back

=cut

#############################################
sub getListTags {
#############################################
   my $self = shift;
   my $ListID = shift;
   my $DBManager = shift;
   my $ajax = shift;

   $self->{Debugger}->debug("in Lists::DB::Tag->getListTags with $ListID");

   my $ListTagObj = $DBManager->getTableObj("ListTag");
   my $ListTags = $ListTagObj->get_with_restraints("ListID = $ListID");

   my $TagHTML = ""; my $TagCount = 0; my $Tags = "";
   if(scalar keys %{$ListTags}){
      foreach  my $ID(keys %{$ListTags}) {
         my $Tag = $self->get_by_ID($ListTags->{$ID}->{TagID});
         my $TagURL = $self->getTagURL($Tag);
         $TagHTML .= "<a href='$TagURL'>$Tag->{Name}</a>, ";
         $Tags .= "Tag->{Name},";
         $TagCount++;
      }
      $TagHTML =~ s/,\s$//;
      $Tags =~ s/,\s$//;
   }

   if($TagHTML){
       $TagHTML = "$TagHTML";
   }
   #else{
   #    $TagHTML = "No tags";
   #}

   return ($TagHTML, $TagCount);
}

=head2 getListTagCloud

Gets the tags of a certain list in cloud format

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list tags

=back

=cut

#############################################
sub getListTagCloud {
#############################################
   my $self = shift;
   my $ListID = shift;
   my $DBManager = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->getListTagCloud with $ListID");

   my $ListTagObj = $DBManager->getTableObj("ListTag");
   my $ListTags = $ListTagObj->get_with_restraints("ListID = $ListID");

   my $TagCloudHTML = "";
   if(scalar keys %{$ListTags}){
      use HTML::TagCloud;
      my $cloud = HTML::TagCloud->new(levels=>10);
      foreach  my $ID(keys %{$ListTags}) {
         my $Tag = $self->get_by_ID($ListTags->{$ID}->{TagID});
         my $TagURL = $self->getTagURL($Tag);
         $cloud->add($Tag->{Name}, $TagURL, $Tag->{TagCount});
      }

      $TagCloudHTML = $cloud->html_and_css(10);
   }

   if(! $TagCloudHTML){
      $TagCloudHTML = "<p class='NoTags'>No tags</p>";
   }

   return $TagCloudHTML;
}

=head2 reduceTagCount

Reduces the tagCount by 1

=over 4

=item B<Parameters :>

   1. $self - Reference to a Tag object
   2. $

=back

=cut

#############################################
sub reduceTagCount {
#############################################
   my $self = shift;
   my $TagID = shift;

   $self->{Debugger}->debug("in Lists::DB::Tag::reduceTagCount with $TagID");

   my $sql = "UPDATE $Lists::SETUP::DB_NAME.Tag SET TagCount = TagCount - 1 WHERE ID = $TagID";
   my $stm = $self->{dbh}->prepare($sql);
   if ($self->{dbh}->do($sql)) {
      # Good Stuff
   }else {
      $self->{Debugger}->throwNotifyingError("ERROR: with Tag UPDATE::: $sql\n");
   }
}


1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


