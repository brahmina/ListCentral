package Lists::Utilities::Gravatar;
use strict;

use Lists::SETUP;

use URI::Escape qw(uri_escape);
use Digest::MD5 qw(md5_hex);

##########################################################
# Lists::Gravatar 
##########################################################

=head1 NAME

   Lists::Utilities::Gravatar.pm

=head1 SYNOPSIS

   $Gravatar = new Lists::Utilities::Gravatar(Debugger);

=head1 DESCRIPTION

Used to communicate with Gravatar for getting and setting gravatars used on List Central

=head2 Lists::Utilities::Gravatar Constructor

=over 4

=item B<Parameters :>

   1. $Debugger
   2. $DBManager

=back

=cut

########################################################
sub new {
########################################################
   my $classname=shift; 
   my $self; 
   %$self=@_; 
   bless $self,ref($classname)||$classname;

   $self->{Debugger}->debug("in Lists::Utilities::Gravatar constructor");
   
   return ($self); 
}


=head2 setGravatarEmail

Sets and saves the email given with the user id passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Gravatar
   2. $email - the Gravatar Email
   3. UserID - the UserID

=back

=cut

#############################################
sub setGravatarEmail {
#############################################
   my $self = shift;
   my $email = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in Lists::Utilities::Gravatar::setGravatarEmail with $email, $UserID");

   my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings");
   my $UserSettings = $UserSettingsObj->get_with_restraints("UserID = $UserID");

   # There should be only one in here
   my $ID;
   foreach (keys %{$UserSettings}) {
      $ID = $_;
   }
   $UserSettingsObj->update("GravatarEmail", $email, $ID);
}

=head2 getGravatarURL

Gets the url for the Gravatar associated with the UserID passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object
   2. $UserID - The userID

=item B<Returns :>

   1. $URL - The Gravatar URL

=back

=cut

#############################################
sub getGravatarURL {
#############################################
   my $self = shift;
   my $UserID = shift;
   my $GravatarEmail = shift;

   $self->{Debugger}->debug("In Lists::Gravatar::getGravatarURL with $UserID and $GravatarEmail");

   if(! $GravatarEmail){
      my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings");
      my $UserSettings = $UserSettingsObj->get_with_restraints("UserID = $UserID");
   
      # There should be only one in here
      
      foreach my $ID(keys %{$UserSettings}) {
         $GravatarEmail = $UserSettings->{$ID}->{GravatarEmail};
      }
   }

   my $GravatarURL = "";
   if($GravatarEmail){
      my $default = $Lists::SETUP::GRAVATAR_DEFAULT_IMAGE;
      my $size = $Lists::SETUP::GRAVATAR_DEFAULT_SIZE;
   
      $GravatarURL = "http://www.gravatar.com/avatar.php?gravatar_id=".md5_hex(lc $GravatarEmail).
                           "&default=".uri_escape($default).
                           "&size=".$size; 
      return $GravatarURL;
   }else{
      $GravatarURL = $Lists::SETUP::GRAVATAR_DEFAULT_IMAGE;
   }

   return $GravatarURL;
   $self->{Debugger}->debug("$GravatarURL");
}

1;

=head1 AUTHOR INFORMATION

   Author:  With help from the ApplicationFramework
   Last Updated: 28/11/2008

=head1 BUGS

   Not known

=cut

