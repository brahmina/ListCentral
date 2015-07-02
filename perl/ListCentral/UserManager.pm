package ListCentral::UserManager;
use strict;

use Apache2::Cookie;
use Crypt::Lite;
use HTML::Entities qw(:DEFAULT encode_entities_numeric);

use ListCentral::SETUP;
use ListCentral::Utilities::StringFormator;
use ListCentral::Utilities::Gravatar;
use ListCentral::Utilities::Date;

##########################################################
# ListCentral::UserManager
##########################################################

=head1 NAME

   ListCentral::UserManager.pm

=head1 SYNOPSIS

   $UserManager = new UserManager($cgi, $Debugger);

=head1 DESCRIPTION

Used to handle the printing of pages that are only to be shown to logged on admin peopls

=head2 ListCentral::UserManager Constructor

=over 4

=item B<Parameters :>

   1. $cgi
   2. $dbh
   3. $debug

=back

=cut

########################################################
sub new {
########################################################
   my $classname=shift; 
   my $self; 
   %$self=@_; 
   bless $self,ref($classname)||$classname;

   $self->{Debugger}->debug("in ListCentral::UserManager constructor");

   $self->{UserObj} = $self->{DBManager}->getTableObj("User");

   return ($self); 
}

=head2 addUser

Adds a new User, via the sign up process

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object

=item B<Returns :>

   1. $errorMessage - The error message, blank if successful

=back

=cut

#############################################
sub addUser {
#############################################
   my $self = shift;
   my $Mailer = shift;

   $self->{Debugger}->debug("in ListCentral::ListsManager::UserManager->addUser");

   my $Email = $self->{cgi}->{"User.Email"};
   $self->{UserObj} = $self->{DBManager}->getTableObj("User"); 

   my $ErrorMessage = "";
   if(!$Mailer->emailValid($Email)){
      $ErrorMessage .= $ListCentral::SETUP::MESSAGES{'INVALID_EMAIL'} . "<br />";
   }
   if($self->{cgi}->{"User.Email"} eq ""){
      $ErrorMessage .= $ListCentral::SETUP::MESSAGES{'BLANK_EMAIL'} . "<br />"; 
   }
   if($self->{cgi}->{"User.Username"} eq ""){   
      $ErrorMessage .= $ListCentral::SETUP::MESSAGES{'BLANK_USERNAME'} . "<br />"; 
   }
   if($self->{cgi}->{"User.Password"} eq ""){
      $ErrorMessage .= $ListCentral::SETUP::MESSAGES{'BLANK_PASSWORD'} . "<br />"; 
   }
   if($self->{cgi}->{"User.Name"} eq ""){
      $ErrorMessage .= $ListCentral::SETUP::MESSAGES{'BLANK_NAME'} . "<br />"; 
   }
   if($self->{cgi}->{"User.Password"} ne $self->{cgi}->{"User.PasswordConfirm"}){
      $ErrorMessage .= $ListCentral::SETUP::MESSAGES{'PASSWORD_NONMATCH'} . "<br />"; 
   }
   if($self->{cgi}->{"UserSettings.BirthDay"} eq ""){
      $ErrorMessage .= $ListCentral::SETUP::MESSAGES{'BLANK_BIRTHDAY'} . "<br />"; 
   }elsif($self->{cgi}->{"UserSettings.BirthMonth"} eq ""){
      $ErrorMessage .= $ListCentral::SETUP::MESSAGES{'BLANK_BIRTHDAY'} . "<br />"; 
   }elsif($self->{cgi}->{"UserSettings.BirthYear"} eq ""){
      $ErrorMessage .= $ListCentral::SETUP::MESSAGES{'BLANK_BIRTHDAY'} . "<br />"; 
   }

   if(! ListCentral::Utilities::Date::olderThan12($self->{cgi}->{"UserSettings.BirthDay"}, $self->{cgi}->{"UserSettings.BirthMonth"}, $self->{cgi}->{"UserSettings.BirthYear"})){
      $ErrorMessage .= $ListCentral::SETUP::MESSAGES{'TOO_YOUNG'} . "<br />"; 
   }

   # Check the ReCaptcha Response
   use ListCentral::Utilities::ReCaptcha;
   my $reCaptchaObj = new ListCentral::Utilities::ReCaptcha("Debugger" => $self->{Debugger});
   my ($valid,$error) = $reCaptchaObj->checkReCaptchaResponse($self->{cgi}->{'recaptcha_challenge_field'}, 
                                                              $self->{cgi}->{'recaptcha_response_field'});
   if(!$valid){
      $ErrorMessage .= $ListCentral::SETUP::MESSAGES{'FAIL_RECAPTCHA'} . "<br /><br />"; 
   }

   my $Users = $self->{UserObj}->get_with_restraints("Email = \"$Email\"");
   if($ErrorMessage eq ""){
      foreach (keys %{$Users}) {
         if($Users->{$_}){
            $ErrorMessage .= $ListCentral::SETUP::MESSAGES{'DUPLICATE_EMAIL'} . "<br />";
         }  
      }
   }

   if($ListCentral::SETUP::BETA_INVITE_ONLY && ! $self->checkBetaInvite($Email)){
      return "BETA";
   }

   my $User = $self->{UserObj}->getUserByUsername($self->{cgi}->{'User.Username'});
   if($ErrorMessage eq ""){
      if($User->{ID}){
         $ErrorMessage .= $ListCentral::SETUP::MESSAGES{'DUPLICATE_USERNAME'} . "<br />"; 
      }  
   }

   if($ErrorMessage eq ""){
      my $Password = $self->{cgi}->{"User.Password"};
      if(length($Password) < $ListCentral::SETUP::PASSWORD_MIN_LENGTH || ! $Password =~ m/^(?=.*(\d|[^a-zA-Z]))(?!.*\s).{6,15}$/){
         $ErrorMessage .= $ListCentral::SETUP::MESSAGES{'INVALID_PASSWORD'} . "<br />"; 
      }
   }

   # Only alphanumeric
   if($self->{cgi}->{"User.Username"} =~ m/\@/){
      $ErrorMessage .= $ListCentral::SETUP::MESSAGES{'NO_AT_IN_USERNAME'} . "<br />"; 
   }
   #if($self->{cgi}->{"User.Name"} =~ m/[^a-zA-Z0-9,\s_-]/){
   #   $ErrorMessage .= $ListCentral::SETUP::MESSAGES{'ONLY_ALPHANUMERIC_NAME'} . "<br />"; 
   #}

   if($ErrorMessage eq ""){
      $self->{cgi}->{"User.Status"} = 1;

      $self->{cgi}->{"User.LastLogin"} = time();
      my $passwordSave = $self->{cgi}->{"User.Password"};
      $self->{cgi}->{"User.Password"} = $self->encryptPassword($self->{cgi}->{"User.Password"});
      my $UserID = $self->{UserObj}->store($self->{cgi});
      if(!$UserID){
         $ErrorMessage = $ListCentral::SETUP::MESSAGES{'MISC_ERROR'};
      }else{
         # All good, set cookie
         $self->setNormalCookie($UserID);

         $self->{cgi}->{"User.Password"} = $passwordSave;

         my $User = $self->{UserObj}->get_by_ID($UserID);
         $self->{ThisUser} = $User;
         $self->{cgi}->{UserID} = $UserID;
   
         $self->setDefaultSettings($UserID);
         $self->createUsersDirectory($UserID);
   
         $self->{ThisUser} = $self->{UserObj}->get_by_ID($UserID);
      }
   }

   return $ErrorMessage;
}


=head2 doLogin

Handles the process of logging in and admin person

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object

=item B<Prints :>

   1. $UID - The User ID if logged in, 0 otherwise

=back

=cut

#############################################
sub doLogin {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::doLogin");

   my $LoginValue = $self->{cgi}->{"Users.Username"};
   my $UserPassword = $self->{cgi}->{"Users.Password"};
   $UserPassword = $self->encryptPassword($UserPassword);

   $self->{Debugger}->debug("UserPassword: $UserPassword");

   my $User;
   if($LoginValue =~ m/\@/){
      $User = $self->{UserObj}->getUserByEmail($LoginValue);
   }else{
      $User = $self->{UserObj}->getUserByUsername($LoginValue);
   }
   
   if($User->{ID}){
      if($User->{Status} == 1){
         if($User->{Password} eq $UserPassword){
            # All good, set cookie
            $self->setNormalCookie($User->{ID});
            
            $self->{ThisUser} = $User;
            $self->getThisUserInfo();

            # Log the Login in UserLogins
            my %UserLogin = ("UserLogins.UserID" => $User->{ID}, 
                             "UserLogins.Status" => 1);
            my $UserLoginObj = $self->{DBManager}->getTableObj("UserLogins");
            my $ID = $UserLoginObj->store(\%UserLogin);

            # Set Persistent cookie
            if($self->{cgi}->{"RememberMe"}){
               $self->setPersistentCookie($User->{ID});
            }

            # Updata last login
            $self->{UserObj}->update("LastLogin", time(), $User->{ID});

            return ($User->{ID}, "");
         }else{
            # Incorrect password
            return 0, $ListCentral::SETUP::MESSAGES{'INCORRECT_PASSWORD'};
         }
      }else{
         # Deatctivated Account
         return -1, $ListCentral::SETUP::MESSAGES{'DEACTIVATED_ACCOUNT'};
      }
   }else{
      # No sure user name
      return 0, $ListCentral::SETUP::MESSAGES{'INCORRECT_USERNAME'};
   }
}


=head2 setDefaultSettings

Sets the user settings to the defults or, if there exists no entry in
UserSettings for the UserID passed, adds a default entry

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object
   2. $UserID - The User to give default settings to

=back

=cut

#############################################
sub setDefaultSettings {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::setDefaultSettings,  $UserID");

   my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings");
   my $Settings = $UserSettingsObj->getByUserID($UserID);

   if($Settings->{ID}){
      $UserSettingsObj->update('ThemeID', 1, $Settings->{ID});
   }else{
      my %DefaultSettings;
      $DefaultSettings{'UserSettings.UserID'} = $UserID;
      $DefaultSettings{'UserSettings.ThemeID'} = 1;
      $DefaultSettings{'UserSettings.Status'} = 1;

      $DefaultSettings{'UserSettings.ReceiveUpdateEmails'} = 1;
      $DefaultSettings{'UserSettings.ReceiveNotifications'} = 1;
      $DefaultSettings{'UserSettings.PrivacyFullName'} = 1;
      $DefaultSettings{'UserSettings.PrivacyLocation'} = 1;
      $DefaultSettings{'UserSettings.PrivacyGender'} = 1;
      $DefaultSettings{'UserSettings.PrivacyAge'} = 0;
      $DefaultSettings{'UserSettings.CanPostOnBoards'} = 1;
      $DefaultSettings{'UserSettings.Modifier'} = 0.5;

      foreach my $field(keys %{$self->{cgi}}) {
         if($field =~ m/UserSettings/){
            $DefaultSettings{$field} = $self->{cgi}->{$field};
         }
      }

      $UserSettingsObj->store(\%DefaultSettings);
   }
}

=head2 createUsersDirectory

Given a UserId, creates and returns the corresponding user's directory

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object
   2. $UserID - The User to return the directory for

=back

=cut

#############################################
sub createUsersDirectory {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::createUsersDirectory with UserID: $UserID ");
   
   my $directory = "";
   my $UserIDTemp = $UserID;
   while($UserIDTemp =~ m/^(\d)/){
      my $digit = $1;
      $directory .= "$digit/";
      my $dir = "$ListCentral::SETUP::USER_CONTENT_DIRECTORY/$directory";
      if(! -e $dir){
         my $output = `mkdir $dir`;
         if($output){
            $self->{Debugger}->log("Error: ListCentral::UserManager->createUsersDirectory, couldn't make directory $dir - $output");
         }
      }

      $UserIDTemp =~ s/^$digit//;
   }

   my $usersname = $self->getUsersUsername($UserID);
   $directory = "$directory$usersname";

   my $dir = "$ListCentral::SETUP::USER_CONTENT_DIRECTORY/$directory";
   if(! -e $dir){
      my $output = `mkdir $dir`;
      if($output){
         $self->{Debugger}->log("Error: ListCentral::UserManager->createUsersDirectory, couldn't make directory $dir - $output");
      }
   }

   return $directory;
}

=head2 getUsersDirectory

Given a UserId, returns the corresponding user's directory


=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object
   2. $UserID - The User to return the directory for

=back

=cut

#############################################
sub getUsersDirectory {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::getUsersDirectory with UserID: $UserID"); 

   # requires that the sign up process creates the users directory
   my $directory = "";
   my $UserIDTemp = $UserID;
   while($UserIDTemp =~ m/^(\d)/){
      my $digit = $1;
      $directory .= "$digit/";
      $UserIDTemp =~ s/^$digit//;
   }

   my $usersname = $self->getUsersUsername($UserID);
   $directory = "$directory$usersname";

   return $directory;
}

=head2 changeUsersDirectory

Given a UserId, returns the corresponding user's directory


=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object
   2. $UserID - The User to return the directory for
   3. $oldUsername
   4. $newUsername

=back

=cut

#############################################
sub changeUsersDirectory {
#############################################
   my $self = shift;
   my $UserID = shift;
   my $oldUsername = shift;
   my $newUsername = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::changeUsersDirectory with UserID: $UserID, $oldUsername, $newUsername"); 

   my $newUserDir = $ListCentral::SETUP::USER_CONTENT_DIRECTORY . "/" . $self->getUsersDirectory($UserID);
   my $oldUserDir = $newUserDir;
   $oldUserDir =~ s/$newUsername/$oldUsername/;

   my $command = "mv $oldUserDir $newUserDir";
   my $output = `$command`;

   

   $self->{Debugger}->debug("command: $command -> $output");
}

=head2 getUsersUsername

Given a UserId, returns the user's username


=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object
   2. $UserID - The User to return the directory for

=back

=cut

#############################################
sub getUsersUsername {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::getUsersUsername with UserID: $UserID"); 

   # requires that the sign up process creates the users directory
   my $User = $self->{UserObj}->get_by_ID($UserID);
   my $username = $User->{Username};

   return $username;
}

=head2 checkLogin

Checks the cookies for login info

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object

=item B<Prints :>

   1. $UID - The User ID if logged in, 0 otherwise

=back

=cut

#############################################
sub checkLogin {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::checkLogin ");

   my $ACookie = Apache2::Cookie::Jar->new($self->{Request});
   my $cookie_in = $ACookie->cookies("ListCentral");

   $self->{Debugger}->debug("cookie_in: $cookie_in");

   my $UserID = 0;
   if($cookie_in =~ m/ListCentral=(.+)/){
      my $encrypted = $1;

      # Decode from html encoding
      my $decoded = $self->hex_to_ascii($encrypted);

      # Decrypt it
      my $crypt = Crypt::Lite->new( debug => 0 );
      $UserID = $crypt->decrypt($decoded, $ListCentral::SETUP::ENCRYPT_KEY);

      if($UserID =~ m/\d+/){
         $self->{Debugger}->debug("Cookie: $encrypted -> UserID: $UserID");
   
         my $User = $self->{UserObj}->get_by_ID($UserID);
         $self->{ThisUser} = $User;
         $self->getThisUserInfo();
      }else{
         $self->{Debugger}->debug("Something is all garbled in our cookie! $UserID");
         return 0;
      }
   }else{
      $self->{Debugger}->debug("None of our cookies are here, not logged in - Cookie: $cookie_in");
   }

   $self->{Debugger}->debug("returning userID: $UserID");

   return $UserID;
}

=head2 doLogout

Clears the cookies on logout

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object

=item B<Prints :>

   1. $UID - The User ID if logged in, 0 otherwise

=back

=cut

#############################################
sub doLogout {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::doLogout ");

   # The Normal Cookie
   my $cookie_out = Apache2::Cookie->new($self->{Request}, -name  => "ListCentral", 
                                                           -value => "",
                                                           -expires =>  '-1h'  );
   $cookie_out->path("/"); 
   $cookie_out->bake($self->{Request});

   # The Persistent Cookie
   my $cookie_out = Apache2::Cookie->new($self->{Request}, -name  => "ListCentralPersist", 
                                                           -value => "",
                                                           -expires =>  '-1h' );
   $cookie_out->path("/"); 
   $cookie_out->bake($self->{Request});

   $self->{ThisUser} = undef;
}


=head2 setNormalCookie

Sets the Normal cookie on a successful login

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object
   2. $UserID - The User ID to set the cookie for

=back

=cut

#############################################
sub setNormalCookie {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::setNormalCookie"); 

   # Encrypt the userID before setting it
   my $crypt = Crypt::Lite->new( debug => 0 );
   my $encrypted = $self->encrypt($UserID, $ListCentral::SETUP::ENCRYPT_KEY);
   my $encoded = $self->ascii_to_hex($encrypted);

   my $cookie_out = Apache2::Cookie->new($self->{Request}, -name  => "ListCentral", -value => $encoded );
   $cookie_out->path("/"); 
   $cookie_out->bake($self->{Request});

   $self->{ThisUser} = $self->{UserObj}->get_by_ID($UserID);
}

=head2 setPersistentCookie

Sets the Persistent cookie on a successful login with Remember Me checked

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object
   2. $UserID - The User ID to set the cookie for

=back

=cut

#############################################
sub setPersistentCookie {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::setPersistentCookie with UserID: $UserID"); 

   my $RandomString = ListCentral::Utilities::StringFormator::randomString($ListCentral::SETUP::LENGTH_OF_PERSISTENT_COOKIE_RANDOM_STRING);

   my $value = $UserID . $RandomString;
   my $cookie_out = Apache2::Cookie->new($self->{Request}, -name  => "ListCentralPersist", 
                                                           -value => $value,
                                                           -expires =>  '+1M' );
   $cookie_out->path("/"); 
   $cookie_out->bake($self->{Request});

   # Store the entry in PersistentCookies
   my %PersistentCookie;
   $PersistentCookie{"PersistentCookies.UserID"} = $UserID;
   $PersistentCookie{"PersistentCookies.RandomString"} = $RandomString;
   $PersistentCookie{"PersistentCookies.Status"} = 1;

   my $PersistentCookiesObj = $self->{DBManager}->getTableObj("PersistentCookies");
   $PersistentCookiesObj->store(\%PersistentCookie);

}

=head2 checkPersistentCookie

Checks the persistent cookie

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object

=item B<Prints :>

   1. $UID - The User ID if logged in, 0 otherwise

=back

=cut

#############################################
sub checkPersistentCookie {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::checkPersistentCookie ");

   my $CookieJar = Apache2::Cookie::Jar->new($self->{Request});
   my $Cookie = $CookieJar->cookies("ListCentralPersist");

   $self->{Debugger}->debug("persistent cookie_in: $Cookie");

   if($Cookie =~ m/ListCentralPersist=(\d+)(\w+)/){

      my $UserID = $1;
      my $RandomString = $2;
      $self->{Debugger}->debug("UserID: $UserID, RandomString: $RandomString");
      my $PersistentCookieObj = $self->{DBManager}->getTableObj("PersistentCookies");
      my $PersistentCookie = $PersistentCookieObj->get_with_restraints("RandomString = \"$RandomString\"");

      foreach my $ID(keys %{$PersistentCookie}) {
         if($PersistentCookie->{$ID}->{UserID} == $UserID){
            # Change the value of this cookie
            $self->setPersistentCookie($UserID);
            $PersistentCookieObj->update("Used", 1, $ID);
            return $UserID;
         }
      }
   }
   return 0;
}

=head2 getThisUserInfo

Takes the info in $self->{ThisUser} and adds the corresponding info from the UserSettings table

=back

=cut

#############################################
sub getThisUserInfo {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::getThisUserInfo ");

   $self->getUserInfo($self->{ThisUser});
}

=head2 getUserInfo

Givin a hash of User info, fills the hash with extra user info

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object
   2. $User - Reference to a user hash

=back

=cut

#############################################
sub getUserInfo {
#############################################
   my $self = shift;
   my $User = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::getUserInfo User: $User->{ID}, UserSettings: $self->{UserSettings}, ClearCache: $self->{ClearCache}");

   if(! $User->{ID}){
      return;
   }

   if($self->{UserCache}->{$User->{ID}} && !$self->{ClearCache}){
      foreach my $field (keys %{$self->{UserCache}->{$User->{ID}}}) {
         $User->{$field} = $self->{UserCache}->{$User->{ID}}->{$field};
      }
   }else{
      my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings");
      my $UserSettings = $UserSettingsObj->getByUserID($User->{ID});
      my $UserInfo = $self->{UserObj}->get_by_ID($User->{ID});

      foreach my $field(keys %{$UserSettings}) {
         if($field ne "ID"){
            $User->{$field} = $UserSettings->{$field};
         }
      }
      
      # refresh the basic info in the user hash
      foreach my $field(keys %{$UserInfo}) {
         $User->{$field} = $UserInfo->{$field};
      }   
      
      # Enforce the Privacy Settings 
      if(! $UserSettings->{PrivacyFullName} && !$self->{UserSettings}){
         $User->{"Name"} = "";
      }

      if(! $UserSettings->{PrivacyLocation} && !$self->{UserSettings}){
         $self->{Debugger}->debug("No");
         $User->{"Location"} = "";
         $User->{"Country"} = "";
         $User->{"Region"} = "";
         $User->{"City"} = "";
      }else{
         $self->{Debugger}->debug("Yes");
         if($User->{"CountryID"}){
            my $CountryObj = $self->{DBManager}->getTableObj("Country");
            $User->{"Country"} = $CountryObj->get_field_by_ID("Name", $User->{"CountryID"});
         }
         if($User->{"RegionID"}){
            my $RegionObj = $self->{DBManager}->getTableObj("Region");

            $self->{Debugger}->debug("post region - > $User->{'RegionID'}");
            $User->{"Region"} = $RegionObj->get_field_by_ID("Name", $User->{"RegionID"});
         }
   
         if($User->{"Country"} || $User->{"Region"} || $User->{"City"}){
            $User->{"Location"} = qq~ <b>From</b>: ~;
            if($User->{"City"}){
               $User->{"Location"} .= "$User->{'City'}, ";
            }
            if($User->{"Region"}){
               $User->{"Location"} .= "$User->{'Region'}, ";
            }
            if($User->{"Country"}){
               $User->{"Location"} .= "$User->{'Country'}";
            }
      
            $User->{"Location"} .= "<br />";
         }
      }

      if(! $UserSettings->{PrivacyAge} && !$self->{UserSettings}){
         $User->{"Age"} = "";
      }else{
         $User->{"Age"} = ListCentral::Utilities::Date::getAge($User->{"BirthDay"}, $User->{"BirthMont"}, $User->{"BirthYear"});
      }

      if(! $UserSettings->{PrivacyGender} && !$self->{UserSettings}){
         $User->{"Gender"} = "";
      }else{
         if($User->{"Gender"} eq "F"){
            $User->{"Gender"} = "Female";
         }elsif($User->{"Gender"} eq "M"){
            $User->{"Gender"} = "Male";
         }else{
            $User->{"Gender"} = "unknown";
         }
      }

      $User->{WebsitesLinks} = "";
      if($User->{Websites} ne ""){
         my $sites = $User->{Websites};
         my @websites = split("\n", $sites);
         foreach my $url(@websites) {
            my $href = $url;
            if($href !~ m/^http/){
               $href = "http://$url";
            }
            $User->{WebsitesLinks} .= "<li><a href='$href'>$url</a><br /></li>";
         }
      }
      if($User->{WebsitesLinks} ne ""){
         $User->{WebsitesWithLinks} = qq~<b>Web Presence</b><br />
              <ul class="UserWebPresence">
                  $User->{WebsitesLinks}
              </ul>~;
      }

      $User->{"UserURL"} = $self->getUserURL($User);
      $User->{"UserDir"} = $self->getUsersDirectory($User->{ID});
      $self->getUserAvatar($User);

      if($User->{"Name"}){
         $User->{"NameDisplay"} = $User->{"Name"};
      }else{
         $User->{"NameDisplay"} = $User->{"Username"};
      }
   
      $User->{"MemberSince"} = ListCentral::Utilities::Date::getHumanFriendlyDate($User->{"CreateDate"});

      my $ListObj = $self->{DBManager}->getTableObj("List");
      $User->{"ListCount"} = $ListObj->get_count_with_restraints("UserID = $User->{ID} AND Public = 1");
      if($User->{"ListCount"} == 1){
         $User->{"ListCountText"} = "list";
      }else{
         $User->{"ListCountText"} = "lists";
      }

      my $MessagesObj = $self->{DBManager}->getTableObj("Messages");
      $User->{MessagesCount} = $MessagesObj->get_count_with_restraints("UserID = $User->{ID} AND Seen = 0");

      $User->{"Password"} = "";
      # User Cache
      foreach my $field(keys %{$User}) {
         $self->{UserCache}->{$User->{ID}}->{$field} = $User->{$field};
      }      
   }
}

=head2 getUserAvatar

Given a hash with user info returns the url for the users main page

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object
   2. $User - Reference to a user hash

=item B<Returns :>

   1. $Avatar - Link to the user's avatar
=back

=cut

#############################################
sub getUserAvatar {
#############################################
   my $self = shift;
   my $User = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::getUserAvatar ");

   if(! $User->{"UserID"}){
      # The info from the UserSettings table isn't here
      my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings");
      my $UserSettings = $UserSettingsObj->getByUserID($User->{ID});

      foreach my $field (keys %{$UserSettings}) {
         if($field ne "ID"){
            $User->{$field} = $UserSettings->{$field};
         }
      }
   }

   if($User->{"GravatarEmail"}){
      my $Gravatar = new ListCentral::Utilities::Gravatar(Debugger=>$self->{Debugger}, DBManager=>$self->{DBManager});
      $User->{"Gravatar"} = $Gravatar->getGravatarURL($User->{ID}, $User->{"GravatarEmail"});
   }else{
      $User->{"Gravatar"} = $ListCentral::SETUP::AVATAR_DEFAULT_IMAGE;
   }

   if($User->{"Avatar"}){
      if(!$User->{"UserDir"}){
         $User->{"UserDir"} = $self->getUsersDirectory($User->{ID}); 
      }
      my $path = $ListCentral::SETUP::USER_CONTENT_PATH . '/' . $User->{"UserDir"};
      $User->{"AvatarLink"} = $path . "/" . $User->{"Avatar"};
   }else{
      $User->{"AvatarLink"} = $ListCentral::SETUP::AVATAR_DEFAULT_IMAGE;
   }

   if($User->{"GravatarOrAvatar"} eq "G"){
      $self->{Debugger}->debug("GravatarOrAvatar is G");
      if($User->{"GravatarEmail"}){
         $User->{"AvatarDisplay"} = $User->{"Gravatar"}
      }else{
         $User->{"AvatarDisplay"} = $ListCentral::SETUP::AVATAR_DEFAULT_IMAGE;
      }
      $User->{"GravatarSelected"} = "checked";
      $User->{"AvatarSelected"} = "";
   }else{
      if($User->{"Avatar"}){
         $User->{"AvatarDisplay"} = $User->{"AvatarLink"};#$ListCentral::SETUP::USER_CONTENT_PATH . "/" . $User->{"Avatar"};
      }else{
         $User->{"AvatarDisplay"} = $ListCentral::SETUP::AVATAR_DEFAULT_IMAGE;
      }
      $User->{"GravatarSelected"} = "";
      $User->{"AvatarSelected"} = "checked";
   } 
}


=head2 getUserURL

Given a hash with user info returns the url for the users main page

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object
   2. $User - Reference to a user hash

=back

=cut

#############################################
sub getUserURL {
#############################################
   my $self = shift;
   my $User = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::getUserURL with ID $User->{ID} ");

   my $url = "/user/$User->{Username}/$User->{ID}/lists.html";
   return $url;
}


=head2 encrypt

Encrypts a string and returns the result

$PopDataBC::SETUP::ENCRYPT_KEY is the key used

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object
   2. $string - The string to encrypt

=item B<Returns :>

   1. $encrypted - The encrypt result 

=back

=cut

#############################################   
sub encrypt {
#############################################
   my $self = shift;
   my $string = shift;

   $self->{Debugger}->debug("in PopDataBC::Auth::Cookies->encrypt with $string");

   my $crypt = Crypt::Lite->new( debug => 0 );
   my $encrypted = $crypt->encrypt($string, $ListCentral::SETUP::ENCRYPT_KEY);

   return $encrypted;
}

=head2 decrypt

Given a string encrypted via the function encrypt in this module, decrypts it 
and returns the result

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object
   2. $string - The string to decrypt

=item B<Returns :>

   1. $plaintext - The decrypted result 

=back

=cut

#############################################   
sub decrypt {
#############################################
   my $self = shift;
   my $string = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager->decrypt with $string");

   my $crypt = Crypt::Lite->new( debug => 0 );
   my $decrypted = $crypt->decrypt($string, $ListCentral::SETUP::ENCRYPT_KEY);

   return $decrypted;
}

=head2 checkBetaInvite

Given a string encrypted via the function encrypt in this module, decrypts it 
and returns the result

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object
   2. $string - The string to decrypt

=item B<Returns :>

   1. $plaintext - The decrypted result 

=back

=cut

#############################################   
sub checkBetaInvite {
#############################################
   my $self = shift;
   my $Email = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager:checkBetaInvite with $Email");

   my $BetaInviteObj = $self->{DBManager}->getTableObj("BetaInvite");
   my $BetaInvites = $BetaInviteObj->get_with_restraints("Email = \"$Email\"");

   my $isInvited = 0;
   foreach my $ID(keys %{$BetaInvites}) {
      if($BetaInvites->{$ID}->{ID}){
         $isInvited = 1;
      }
   }

   return $isInvited;
}

=head2 ascii_to_hex

Given a string encrypted via the function encrypt in this module, decrypts it 
and returns the result

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object
   2. $string - The string to decrypt

=item B<Returns :>

   1. $plaintext - The decrypted result 

=back

=cut

#############################################   
sub ascii_to_hex {
#############################################
   my $self = shift;

  ## Convert each ASCII character to a two-digit hex number.
  (my $hex = shift) =~ s/(.|\n)/sprintf("%02lx", ord $1)/eg;

  return $hex;
}

=head2 hex_to_ascii

Given a string encrypted via the function encrypt in this module, decrypts it 
and returns the result

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::UserManager object
   2. $string - The string to decrypt

=item B<Returns :>

   1. $plaintext - The decrypted result 

=back

=cut

#############################################   
sub hex_to_ascii {
#############################################
   my $self = shift;

   ## Convert each two-digit hex number back to an ASCII character.
  (my $ascii = shift) =~ s/([a-fA-F0-9]{2})/chr(hex $1)/eg;

   return $ascii;
}


=head2 encryptPassword

Encrypts the passed pasword and returns the result, so that we do not store plain text passwords

Greater security could be attained here by doing one-way hashing, but retrieving passwords would not
be possible in that way, only password resets. This may be changed down the road

=over 4

=item B<Parameters :>

   1. $self - Reference to a UserManager
   2. $password - the password to be encrypted

=item B<Returns :>

   1. $passwdency - The password encrypted

=back

=cut

#############################################
sub encryptPassword {
#############################################
   my $self = shift;
   my $password = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::encryptPassword");

   use Digest::SHA1;
   use MIME::Base64;
   my $ctx = Digest::SHA1->new;
   $ctx->add($password);
   $ctx->add($ListCentral::SETUP::SALT);
   my $hashedPasswd = encode_base64($ctx->digest . $ListCentral::SETUP::SALT ,'');

   return $hashedPasswd;
}


=head2 generateAndSetNewPassword

Generates a new temporary password for the forgot password feature

=over 4

=item B<Parameters :>

   1. $self - Reference to a UserManager

=item B<Returns :>

   1. $passwdency - The password encrypted

=back

=cut

#############################################
sub generateAndSetNewPassword {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::encryptPassword");

   if($UserID){
      my $password = $self->generatePassword(8);

      my $encryptedPassword = $self->encryptPassword($password);
      
      my $UserObj = $self->{DBManager}->getTableObj("User");
      $UserObj->update("Password", $encryptedPassword, $UserID);
   
      return $password;
   }else{
      return "";
   }
}

=head2 generatePassword

Generates a new temporary password for the forgot password feature

=over 4

=item B<Parameters :>

   1. $self - Reference to a UserManager

=item B<Returns :>

   1. $passwdency - The password encrypted

=back

=cut

#############################################
sub generatePassword {
#############################################
   my $self = shift;
   my $length = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::generatePassword");

   my $password = "";
   my $possible = 'abcdefghijkmnpqrstuvwxyz0123456789ABCDEFGHJKLMNPQRSTUVWXYZ';
   while (length($password) < $length) {
      $password .= substr($possible, (int(rand(length($possible)))), 1);
   }
   return $password
}

=head2 getUsersEncryptedPassword

Gets the User's encrypted password from the database, and returns it

=over 4

=item B<Parameters :>

   1. $self - Reference to a UserManager

=item B<Returns :>

   1. $passwdency - The password encrypted

=back

=cut

#############################################
sub getUsersEncryptedPassword {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::getUsersEncryptedPassword $UserID");

   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $Password = $UserObj->get_field_by_ID("Password", $UserID);

   $self->{Debugger}->debug("Password: $Password");

   return $Password;
}

=head2 userHasLists

Returns the number of lists a user has, public or private

=over 4

=item B<Parameters :>

   1. $self - Reference to a UserManager

=item B<Returns :>

   1. $userHasLists - 0 or 1

=back

=cut

#############################################
sub userListCount {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::userListCount $UserID");

   my $ListObj = $self->{DBManager}->getTableObj("List");
   my $usersListCount = $ListObj->get_count_with_restraints("UserID = $UserID");

   return $usersListCount;
}


=head2 userHasLists

Returns the number of lists a user has, public or private

=over 4

=item B<Parameters :>

   1. $self - Reference to a UserManager

=item B<Returns :>

   1. $userHasLists - 0 or 1

=back

=cut

#############################################
sub getUsersAmazonCountry {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::UserManager::getUsersAmazonCountry");

   my $country;
   if($self->{ThisUser}->{ID}){
      my $CountryID;
      if($self->{ThisUser}->{CountryID}){
         $CountryID = $self->{ThisUser}->{CountryID};
      }else{
         my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings");
         my $UserSettings = $UserSettingsObj->getByUserID($self->{ThisUser}->{ID});
         $CountryID = $UserSettings->{CountryID};
      }

      if($CountryID == 2){
         $country = "CA";
      }elsif($CountryID == 4){
         $country = "US";
      }elsif($CountryID == 3){
         $country = "UK";
      }
   }
   return $country;
}

1;

