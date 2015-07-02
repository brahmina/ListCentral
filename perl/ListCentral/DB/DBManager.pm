package ListCentral::DB::DBManager;

use strict;

use ListCentral::SETUP;

use ListCentral::DB::AdImpressions;
use ListCentral::DB::AdSpaces;
use ListCentral::DB::AdminUsers;
use ListCentral::DB::Advert;
use ListCentral::DB::AdvertAdSpaces;
use ListCentral::DB::AlphaNotify;
use ListCentral::DB::AmazonLinks;
use ListCentral::DB::AmazonModes;
use ListCentral::DB::BetaInvite;
use ListCentral::DB::Board;
use ListCentral::DB::CCImage;
use ListCentral::DB::ComplaintsAgainstUser;
use ListCentral::DB::Comment;
use ListCentral::DB::Country;
use ListCentral::DB::Date;
use ListCentral::DB::Email;
use ListCentral::DB::EmailSent;
use ListCentral::DB::Embed;
use ListCentral::DB::Feedback;
use ListCentral::DB::FeedbackReply;
use ListCentral::DB::FeedbackStatus;
use ListCentral::DB::FeedbackType;
use ListCentral::DB::Gender;
use ListCentral::DB::Help;
use ListCentral::DB::Hitlog;
use ListCentral::DB::Image;
use ListCentral::DB::Infraction;
use ListCentral::DB::Link;
use ListCentral::DB::List;
use ListCentral::DB::ListGroup;
use ListCentral::DB::ListHits;
use ListCentral::DB::ListItem;
use ListCentral::DB::ListItemStatus;
use ListCentral::DB::ListPoints;
use ListCentral::DB::ListRatings;
use ListCentral::DB::ListTag;
use ListCentral::DB::ListType;
use ListCentral::DB::Messages;
use ListCentral::DB::MessageActions;
use ListCentral::DB::PersistentCookies;
use ListCentral::DB::Referrers;
use ListCentral::DB::Region;
use ListCentral::DB::SearchHistory;
use ListCentral::DB::Tag;
use ListCentral::DB::Theme;
use ListCentral::DB::ThemeColours;
use ListCentral::DB::User;
use ListCentral::DB::UserLogins;
use ListCentral::DB::UsernameHistory;
use ListCentral::DB::UserPoints;
use ListCentral::DB::UserSettings;

##########################################################
# ListCentral::DB::UserStats 
##########################################################

=head1 NAME

   ListCentral::DB::DBManager.pm

=head1 SYNOPSIS

   $DBManager = new ListCentral::DB::DBManager($dbh, $Debugger);

=head1 DESCRIPTION

Used to manage, and maintain the Database modules

=head2 ListCentral::DB::DBManager Constructor

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

   $self->{Debugger}->debug("in ListCentral::DB::DBManager's constructor");

   if(!$self->{dbh}){
      die $self->{Debugger}->log("Where is ListCentral::DB::DBManager's dbh??");
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

   1. $self - Reference to a ListCentral::DB::DBManager object
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

   #$self->{Debugger}->debug("in ListCentral::DB::DBManager::getTableObj with $TableName");

   if($self->{ModuleHash}->{$TableName}){
      return $self->{ModuleHash}->{$TableName};
   }else{
      my $tableObj;
      if($TableName eq "AdImpressions"){
          $tableObj = new ListCentral::DB::AdImpressions(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "AdSpaces"){
          $tableObj = new ListCentral::DB::AdSpaces(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "AdminUser"){
          $tableObj = new ListCentral::DB::AdminUser(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Advert"){
          $tableObj = new ListCentral::DB::Advert(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "AdvertAdSpaces"){
          $tableObj = new ListCentral::DB::AdvertAdSpaces(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "AlphaNotify"){
          $tableObj = new ListCentral::DB::AlphaNotify(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "AmazonLinks"){
          $tableObj = new ListCentral::DB::AmazonLinks(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "AmazonModes"){
          $tableObj = new ListCentral::DB::AmazonModes(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "BetaInvite"){
          $tableObj = new ListCentral::DB::BetaInvite(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Board"){
          $tableObj = new ListCentral::DB::Board(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "CCImage"){
          $tableObj = new ListCentral::DB::CCImage(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Comment"){
          $tableObj = new ListCentral::DB::Comment(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ComplaintsAgainstUser"){
          $tableObj = new ListCentral::DB::ComplaintsAgainstUser(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Country"){
          $tableObj = new ListCentral::DB::Country(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Date"){
          $tableObj = new ListCentral::DB::Date(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Email"){
          $tableObj = new ListCentral::DB::Email(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "EmailSent"){
          $tableObj = new ListCentral::DB::EmailSent(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Embed"){
          $tableObj = new ListCentral::DB::Embed(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Feedback"){
          $tableObj = new ListCentral::DB::Feedback(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "FeedbackReply"){
          $tableObj = new ListCentral::DB::FeedbackReply(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "FeedbackStatus"){
          $tableObj = new ListCentral::DB::FeedbackStatus(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "FeedbackType"){
          $tableObj = new ListCentral::DB::FeedbackType(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Gender"){
          $tableObj = new ListCentral::DB::Gender(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Help"){
          $tableObj = new ListCentral::DB::Help(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Hitlog"){
          $tableObj = new ListCentral::DB::Hitlog(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Image"){
          $tableObj = new ListCentral::DB::Image(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Infraction"){
          $tableObj = new ListCentral::DB::Infraction(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Link"){
          $tableObj = new ListCentral::DB::Link(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "List"){
          $tableObj = new ListCentral::DB::List(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ListGroup"){
          $tableObj = new ListCentral::DB::ListGroup(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ListHits"){
          $tableObj = new ListCentral::DB::ListHits(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ListItem"){
          $tableObj = new ListCentral::DB::ListItem(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ListItemStatus"){
          $tableObj = new ListCentral::DB::ListItemStatus(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ListPoints"){
          $tableObj = new ListCentral::DB::ListPoints(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ListRatings"){
          $tableObj = new ListCentral::DB::ListRatings(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ListTag"){
          $tableObj = new ListCentral::DB::ListTag(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ListType"){
          $tableObj = new ListCentral::DB::ListType(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Messages"){
          $tableObj = new ListCentral::DB::Messages(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "MessageActions"){
          $tableObj = new ListCentral::DB::MessageActions(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "PersistentCookies"){
          $tableObj = new ListCentral::DB::PersistentCookies(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Referrers"){
          $tableObj = new ListCentral::DB::Referrers(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Region"){
          $tableObj = new ListCentral::DB::Region(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "SearchHistory"){
          $tableObj = new ListCentral::DB::SearchHistory(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Tag"){
          $tableObj = new ListCentral::DB::Tag(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "Theme"){
          $tableObj = new ListCentral::DB::Theme(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "ThemeColours"){
          $tableObj = new ListCentral::DB::ThemeColours(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "User"){
          $tableObj = new ListCentral::DB::User(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "UserLogins"){
          $tableObj = new ListCentral::DB::UserLogins(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "UsernameHistory"){
          $tableObj = new ListCentral::DB::UsernameHistory(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "UserPoints"){
          $tableObj = new ListCentral::DB::UserPoints(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
      }elsif($TableName eq "UserSettings"){
          $tableObj = new ListCentral::DB::UserSettings(dbh=>$self->{dbh}, Debugger=>$self->{Debugger}, DBManager=>$self);
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

