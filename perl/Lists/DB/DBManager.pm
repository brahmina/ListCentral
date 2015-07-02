package Lists::DB::DBManager;

use strict;

use Lists::SETUP;

use Lists::DB::AdImpressions;
use Lists::DB::AdSpaces;
use Lists::DB::AdminUsers;
use Lists::DB::Advert;
use Lists::DB::AdvertAdSpaces;
use Lists::DB::AlphaNotify;
use Lists::DB::AmazonLinks;
use Lists::DB::AmazonModes;
use Lists::DB::BetaInvite;
use Lists::DB::Board;
use Lists::DB::CCImage;
use Lists::DB::ComplaintsAgainstUser;
use Lists::DB::Comment;
use Lists::DB::Country;
use Lists::DB::Date;
use Lists::DB::Email;
use Lists::DB::EmailSent;
use Lists::DB::Embed;
use Lists::DB::Feedback;
use Lists::DB::FeedbackReply;
use Lists::DB::FeedbackStatus;
use Lists::DB::FeedbackType;
use Lists::DB::Gender;
use Lists::DB::Help;
use Lists::DB::Hitlog;
use Lists::DB::Image;
use Lists::DB::Infraction;
use Lists::DB::Link;
use Lists::DB::List;
use Lists::DB::ListGroup;
use Lists::DB::ListHits;
use Lists::DB::ListItem;
use Lists::DB::ListItemStatus;
use Lists::DB::ListPoints;
use Lists::DB::ListRatings;
use Lists::DB::ListTag;
use Lists::DB::ListType;
use Lists::DB::Messages;
use Lists::DB::MessageActions;
use Lists::DB::PersistentCookies;
use Lists::DB::Referrers;
use Lists::DB::Region;
use Lists::DB::SearchHistory;
use Lists::DB::Tag;
use Lists::DB::Theme;
use Lists::DB::ThemeColours;
use Lists::DB::User;
use Lists::DB::UserLogins;
use Lists::DB::UsernameHistory;
use Lists::DB::UserPoints;
use Lists::DB::UserSettings;

##########################################################
# Lists::DB::UserStats 
##########################################################

=head1 NAME

   Lists::DB::DBManager.pm

=head1 SYNOPSIS

   $DBManager = new Lists::DB::DBManager($dbh, $Debugger);

=head1 DESCRIPTION

Used to manage, and maintain the Database modules

=head2 Lists::DB::DBManager Constructor

=over 4

=item B<Parameters :>

   1. $dbh
   3. $Debugger

=back

=cut

########################################################
sub new {
########################################################
   my $classname = shift; 
   my $self; 
   %$self = @_; 
   bless $self, ref($classname)||$classname;

   $self->{Debugger}->debug("in Lists::DB::DBManager's constructor");

   if(!$self->{dbh}){
      die $self->{Debugger}->log("Where is Lists::DB::DBManager's dbh??");
   }

   my %ModuleHash = ();
   $self->{ModuleHash} = \%ModuleHash;

   return ($self); 
}

=head2 getTableObj

Gets an object representing a table in the DB and returns it. Keeps and maintains a hash of modules so as 
to only create each object requested once

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::DB::DBManager object
   2. $tableName - The name of the table for which to return the module for

=item B<Returns :>

   1. $obj - Reference to the table object requested

=back

=cut

#############################################
sub getTableObj {
#############################################
   my $self = shift;
   my $TableName = shift;

   #$self->{Debugger}->debug("in Lists::DB::DBManager::getTableObj with $TableName");

   if($self->{ModuleHash}->{$TableName}){
      return $self->{ModuleHash}->{$TableName};
   }else{
      my $tableObj;
      if($TableName eq "AdImpressions"){
          $tableObj = new Lists::DB::AdImpressions(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "AdSpaces"){
          $tableObj = new Lists::DB::AdSpaces(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "AdminUser"){
          $tableObj = new Lists::DB::AdminUser(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Advert"){
          $tableObj = new Lists::DB::Advert(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "AdvertAdSpaces"){
          $tableObj = new Lists::DB::AdvertAdSpaces(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "AlphaNotify"){
          $tableObj = new Lists::DB::AlphaNotify(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "AmazonLinks"){
          $tableObj = new Lists::DB::AmazonLinks(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "AmazonModes"){
          $tableObj = new Lists::DB::AmazonModes(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "BetaInvite"){
          $tableObj = new Lists::DB::BetaInvite(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Board"){
          $tableObj = new Lists::DB::Board(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "CCImage"){
          $tableObj = new Lists::DB::CCImage(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Comment"){
          $tableObj = new Lists::DB::Comment(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ComplaintsAgainstUser"){
          $tableObj = new Lists::DB::ComplaintsAgainstUser(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Country"){
          $tableObj = new Lists::DB::Country(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Date"){
          $tableObj = new Lists::DB::Date(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Email"){
          $tableObj = new Lists::DB::Email(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "EmailSent"){
          $tableObj = new Lists::DB::EmailSent(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Embed"){
          $tableObj = new Lists::DB::Embed(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Feedback"){
          $tableObj = new Lists::DB::Feedback(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "FeedbackReply"){
          $tableObj = new Lists::DB::FeedbackReply(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "FeedbackStatus"){
          $tableObj = new Lists::DB::FeedbackStatus(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "FeedbackType"){
          $tableObj = new Lists::DB::FeedbackType(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Gender"){
          $tableObj = new Lists::DB::Gender(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Help"){
          $tableObj = new Lists::DB::Help(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Hitlog"){
          $tableObj = new Lists::DB::Hitlog(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Image"){
          $tableObj = new Lists::DB::Image(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Infraction"){
          $tableObj = new Lists::DB::Infraction(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Link"){
          $tableObj = new Lists::DB::Link(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "List"){
          $tableObj = new Lists::DB::List(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ListGroup"){
          $tableObj = new Lists::DB::ListGroup(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ListHits"){
          $tableObj = new Lists::DB::ListHits(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ListItem"){
          $tableObj = new Lists::DB::ListItem(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ListItemStatus"){
          $tableObj = new Lists::DB::ListItemStatus(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ListPoints"){
          $tableObj = new Lists::DB::ListPoints(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ListRatings"){
          $tableObj = new Lists::DB::ListRatings(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ListTag"){
          $tableObj = new Lists::DB::ListTag(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ListType"){
          $tableObj = new Lists::DB::ListType(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Messages"){
          $tableObj = new Lists::DB::Messages(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "MessageActions"){
          $tableObj = new Lists::DB::MessageActions(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "PersistentCookies"){
          $tableObj = new Lists::DB::PersistentCookies(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Referrers"){
          $tableObj = new Lists::DB::Referrers(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Region"){
          $tableObj = new Lists::DB::Region(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "SearchHistory"){
          $tableObj = new Lists::DB::SearchHistory(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Tag"){
          $tableObj = new Lists::DB::Tag(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Theme"){
          $tableObj = new Lists::DB::Theme(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ThemeColours"){
          $tableObj = new Lists::DB::ThemeColours(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "User"){
          $tableObj = new Lists::DB::User(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "UserLogins"){
          $tableObj = new Lists::DB::UserLogins(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "UsernameHistory"){
          $tableObj = new Lists::DB::UsernameHistory(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "UserPoints"){
          $tableObj = new Lists::DB::UserPoints(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "UserSettings"){
          $tableObj = new Lists::DB::UserSettings(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }else{
         $self->{Debugger}->debug("DBManager doesn't know what table you want... $TableName");
      }

      $self->{ModuleHash}->{$TableName} = $tableObj;
      return $self->{ModuleHash}->{$TableName};
   }
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 21/1/2008

=head1 BUGS

   Not known

=cut

