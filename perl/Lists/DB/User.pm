package Lists::DB::User;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::User 
##########################################################

=head1 NAME

   Lists::DB::User.pm

=head1 SYNOPSIS

   $User = new Lists::DB::User($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the User table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::User::init");

   my @Fields = ("Username", "Password", "Status", "CreateDate", "Email", "Name", "ActivityScore", 
                 "PopularityScore", "LastLogin", "InviteCode");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;
}

=head2 getActiveUsers

Get User entries resulting from the select performed using the where clause pased

=over 4

=item B<Parameters :>

   1. $self - Reference to a User object

=item B<Returns :>

   1. $ActiveUsers - Reference to a hash with the most active users

=back

=cut

#############################################
sub getActiveUsers {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::User::getActiveUsers");

   my %ActiveUsers;
   my $sql = "SELECT * 
              FROM User 
              WHERE Status > 0 
              ORDER BY ActivityScore 
              LIMIT $Lists::SETUP::ACTIVE_USER_REPORT_ROWS";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $ActiveUsers{$hash->{ID}} = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with ActiveUsers: $sql\n");
   }
   $stm->finish;

   return \%ActiveUsers;
}

=head2 getTopUsers

Get User entries resulting from the select performed using the where clause pased

Same as getActiveUsers right now

=over 4

=item B<Parameters :>

   1. $self - Reference to a User object

=item B<Returns :>

   1. $ActiveUsers - Reference to a hash with the most active users

=back

=cut

#############################################
sub getTopUsers {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::User::getTopUsers");

   my %ActiveUsers;
   my $sql = "SELECT * 
              FROM User 
              WHERE Status > 0 AND ID != $Lists::SETUP::ABOUT_USER_ACCOUNT
              ORDER BY LastLogin DESC 
              LIMIT $Lists::SETUP::ACTIVE_USER_REPORT_ROWS";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $ActiveUsers{$hash->{ID}} = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with ActiveUsers: $sql\n");
   }
   $stm->finish;

   return \%ActiveUsers;
}

=head2 getPopularUser

Gets the most popular users

=over 4

=item B<Parameters :>

   1. $self - Reference to a User object

=item B<Returns: >

   1. $PopularUser - Reference to a hash with the User data

=back

=cut

#############################################
sub getPopularUsers {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::User::getPopularUsers");

   my %PopularUsers;
   my $sql = "SELECT * FROM User WHERE Status > 0 ORDER BY PopularityScore LIMIT $Lists::SETUP::POPULAR_USER_REPORT_ROWS";
   
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $PopularUsers{$hash->{ID}} = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with PopularUsers: $sql\n");
   }
   $stm->finish;

   return \%PopularUsers;
}

=head2 getTroublesomeUser

Gets the most Troublesome users

=over 4

=item B<Parameters :>

   1. $self - Reference to a User object

=item B<Returns: >

   1. $TroublesomeUser - Reference to a hash with the User data

=back

=cut

#############################################
sub getTroublesomeUsers {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::User::getTroublesomeUers");

   my %TroublesomeUsers;

   my $sql = "SELECT COUNT(DISTINCT UserID) AS Count, User.*
              FROM ComplaintsAgainstUser INNER JOIN $Lists::SETUP::DB_NAME.User ON User.ID = ComplaintsAgainstUser.UserID
              WHERE User.Status > 0 AND ComplaintsAgainstUser.Status > 0
              GROUP BY UserID
              ORDER BY Count
              LIMIT $Lists::SETUP::TROUBLESOME_USER_REPORT_ROWS";
              
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $TroublesomeUsers{$hash->{ID}} = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with TroublesomeUsers: $sql\n");
   }
   $stm->finish;

   return \%TroublesomeUsers;
}

=head2 getUserByEmail

Given an email address, returns the corresponding account, or 0 if there isn't one

=over 4

=item B<Parameters :>

   1. $self - Reference to a User object
   2. $email - the email address

=item B<Returns: >

   1. $User - Reference to a hash with the User data

=back

=cut

#############################################
sub getUserByEmail {
#############################################
   my $self = shift;
   my $Email = shift;

   $self->{Debugger}->debug("in Lists::DB::User::getUserByEmail $Email");

   my $ID;
   my %User;
   my $sql = "SELECT *
              FROM User
              WHERE Email = \"$Email\" AND Status > 0";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $User{$hash->{ID}} = $hash;
         $ID = $hash->{ID}; 
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with TroublesomeUsers: $sql\n");
   }
   $stm->finish;

   return $User{$ID};
}

=head2 getUserByUsername

Gets the User entry corresponding the the username passed Returns a user even if their status is 0

=over 4

=item B<Parameters :>

   1. $self - Reference to a User object
   2. $Username - The Username

=item B<Returns: >

   1. $User - Reference to a hash with the User data

=back

=cut

#############################################
sub getUserByUsername {
#############################################
   my $self = shift;
   my $Username = shift;

   $self->{Debugger}->debug("in Lists::DB::User::getUserByUsername with $Username");

   my $User;
   my $sql_select = "SELECT * 
                     FROM $Lists::SETUP::DB_NAME.User 
                     WHERE Username = \"$Username\"";

   my $stm = $self->{dbh}->prepare($sql_select);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $User = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with User SELECT: $sql_select - $DBI::errstr");
   }
   $stm->finish;

   return $User;
}

=head2 getUserModifiers

Gets all of the user modifiers and user ids of all of the valid users

=over 4

=item B<Parameters :>

   1. $self - Reference to a User object

=item B<Returns: >

   1. $UserModifiers - Reference to a hash with the UserID -> Modifier

=back

=cut

#############################################
sub getUserModifiers {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::User::getUserModifiers");

   my %UserModifiers;
   my $sql_select = "SELECT User.ID, UserSettings.Modifier
                     FROM $Lists::SETUP::DB_NAME.User, $Lists::SETUP::DB_NAME.UserSettings
                     WHERE User.ID = UserSettings.UserID and User.Status > 0";

   my $stm = $self->{dbh}->prepare($sql_select);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $UserModifiers{$hash->{ID}} = $hash->{Modifier};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with User SELECT: $sql_select - $DBI::errstr");
   }
   $stm->finish;

   return \%UserModifiers;
}

=head2 getSubscribedUsers

Gets all of the user modifiers and user ids of all of the valid users

=over 4

=item B<Parameters :>

   1. $self - Reference to a User object

=item B<Returns: >

   1. $UserModifiers - Reference to a hash with the UserID -> Modifier

=back

=cut

#############################################
sub getSubscribedUsers {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::User::getSubscribedUsers");

   my %UserEmails;
   my $sql_select = "SELECT User.ID, User.Email, User.Username, User.Name
                     FROM $Lists::SETUP::DB_NAME.User, $Lists::SETUP::DB_NAME.UserSettings
                     WHERE User.ID = UserSettings.UserID and User.Status > 0 AND UserSettings.ReceiveUpdateEmails = 1";

   my $stm = $self->{dbh}->prepare($sql_select);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $UserEmails{$hash->{ID}} = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with User SELECT: $sql_select - $DBI::errstr");
   }
   $stm->finish;

   return \%UserEmails;
}


1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 21/1/2008

=head1 BUGS

   Not known

=cut


