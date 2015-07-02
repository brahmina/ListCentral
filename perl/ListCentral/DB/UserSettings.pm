package ListCentral::DB::UserSettings;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::UserSettings 
##########################################################

=head1 NAME

   ListCentral::DB::UserSettings.pm

=head1 SYNOPSIS

   $UserSettings = new ListCentral::DB::UserSettings($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the UserSettings table in the 
Lists database.


=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::UserSettings::init");

   my @Fields = ("UserID", "Status", "Bio", "Gender", "RegionID", "ThemeID", "CountryID", "City", "Avatar", "GravatarEmail", 
                  "GravatarOrAvatar", "Websites", "PrivacyFullName", "PrivacyLocation", "PrivacyGender", "PrivacyAge", 
                  "ReceiveUpdateEmails", "ReceiveNotifications", "Modifier", "CanPostOnBoards", "BirthDay", "BirthMonth", 
                  "BirthYear", "Region");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ("Bio");
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ();
   $self->{DateFields} = \@DateFields;
}


=head2 getByUserID

Gets the UserSettings entry corresponding the the UserID passed and returns a reference to a hash containing
the UserSettings information 

=over 4

=item B<Parameters :>

   1. $self - Reference to a UserSettings object
   2. $UserID - The UserSettings id

=item B<Returns: >

   1. $UserSettings - Reference to a hash with the UserSettings data

=back

=cut

#############################################
sub getByUserID {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::DB::UserSettings::getByUserID with $UserID");

   my $UserSettings;
   my $sql_select = "SELECT * 
                     FROM $ListCentral::SETUP::DB_NAME.UserSettings 
                     WHERE UserID = $UserID
                           AND Status > 0";

   my $stm = $self->{dbh}->prepare($sql_select);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $UserSettings = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with UserSettings SELECT: $sql_select - $DBI::errstr");
   }
   $stm->finish;

   return $UserSettings;
}


=head2 getFieldByUserID

Get a UserSettings field entry corresponding the the UserID, and field name(s) passed and returns a reference to a 
hash containing the UserSettings information 

=over 4

=item B<Parameters :>

   1. $self - Reference to a UserSettings object
   2. $field - The field name(s), comma separated, to use
   3. $UserID - The UserSettings id

=item B<Returns: >

   1. $UserSettings - Reference to a hash with the UserSettings data

=back

=cut

#############################################
sub getFieldByUserID {
#############################################
   my $self = shift;
   my $field = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::DB::UserSettings::getFieldByUserID with $field, $UserID");

   my $result;
   my $sql = "SELECT $field FROM $ListCentral::SETUP::DB_NAME.UserSettings WHERE UserID = $UserID AND Status > 0";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $result = $hash->{$field};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with UserSettings SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   return $result;
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 27/9/2008

=head1 BUGS

   Not known

=cut


