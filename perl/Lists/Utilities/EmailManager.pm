package Lists::Utilities::EmailManager;
use strict;

use Lists::SETUP;
use Lists::Admin::PageGetter;
use Lists::Utilities::Mailer;

##########################################################
# Lists::EmailManager 
##########################################################

=head1 NAME

   Lists::Utilities::EmailManager.pm

=head1 SYNOPSIS

   $EmailManager = new Lists::Utilities::EmailManager(Debugger);

=head1 DESCRIPTION

Used to get resources from the web

=head2 Lists::Utilities::EmailManager Constructor

=over 4

=item B<Parameters :>

   1. $Debugger

=back

=cut

########################################################
sub new {
########################################################
   my $classname=shift; 
   my $self; 
   %$self=@_; 
   bless $self,ref($classname)||$classname;

   $self->{Debugger}->debug("in Lists::Utilities::EmailManager constructor");
   
   return ($self); 
}


=head2 AddNewEmail

Adds a new help page from the admin system

=over 4

=item B<Parameters :>

   1. $self - Reference to a EmailManager object

=item B<Returns :>

   1. 

=back

=cut

#############################################
sub AddNewEmail {
#############################################
   my $self = shift;

   my $EmailObj = $self->{DBManager}->getTableObj("Email");

   $self->{cgi}->{"Email.Status"} = 1;
   my $EmailID = $EmailObj->store($self->{cgi});

   return "$Lists::SETUP::ADMIN_DIR_PATH/email_management.html";
}

=head2 TestEmail

Sends the email to the test email

=back

=cut

#############################################
sub TestEmail {
#############################################
   my $self = shift;

   $self->{Debugger}->debugNow("in Lists::Utilities::Email->TestEmail");

   my $EmailID = $self->{cgi}->{"Email.ID"};
   if($EmailID){

      my $EmailObj = $self->{DBManager}->getTableObj("Email");
      my $Email = $EmailObj->get_by_ID($EmailID);

      if($Email->{ID}){
         my $EmailSentObj = $self->{DBManager}->getTableObj("EmailSent");
         my $Mailer = new Lists::Utilities::Mailer(Debugger=>$self->{Debugger});
         my $PageGetter = new Lists::Admin::PageGetter(Debugger => $self->{Debugger});
      
         foreach my $toEmail(@Lists::SETUP::TEST_EMAILS) {

            my %Data;
            $Data{"User"}->{Email} = $toEmail;
            if($toEmail =~ m/^(\w+)\@/){
               my $username = $1;
               $Data{"User"}->{Username} = $username;
            }
   
            my $Subject = $PageGetter->processBasicContent($Email->{Subject}, \%Data);
            my $HTML = $PageGetter->processBasicContent($Email->{HTML}, \%Data);
            my $Text = $PageGetter->processBasicContent($Email->{Text}, \%Data);

            $Data{"BodyHTML"} = $HTML;
            $Data{"BodyTXT"} = $Text;   
            my $EmailHTML = $PageGetter->getBasicPage("$Lists::SETUP::DIR_PATH/emails/email_template.html", \%Data);
            my $EmailText = $PageGetter->getBasicPage("$Lists::SETUP::DIR_PATH/emails/email_template.txt", \%Data);

            my $ip = $ENV{'REMOTE_ADDR'};
            $ip =~ s/\.//g;
            my $boundary = "mimepart_" . time() . "_" . $ip;
            $Mailer->sendEmail($toEmail, 
                               $Lists::SETUP::MAIL_FROM_LISTS, 
                               $Subject, $EmailHTML, $EmailText, $boundary);

            my %EmailSent = ("EmailSent.EmailID" => $EmailID,
                             "EmailSent.EmailAddress" => $toEmail,
                             "EmailSent.Status" => 1);
            $EmailSentObj->store(\%EmailSent);
         }
      }
   }

   return "$Lists::SETUP::ADMIN_DIR_PATH/email_management.html";
}

=head2 SendEmail

Sends the email to all List Central users who indicated they would like 
to receive emails

=back

=cut

#############################################
sub SendEmail {
#############################################
   my $self = shift;

   $self->{Debugger}->debugNow("in Lists::Utilities::Email->SendEmail");

   my $EmailID = $self->{cgi}->{"Email.ID"};
   if($EmailID){

      my $EmailObj = $self->{DBManager}->getTableObj("Email");
      my $Email = $EmailObj->get_by_ID($EmailID);

      if($Email->{ID}){
         my $EmailSentObj = $self->{DBManager}->getTableObj("EmailSent");
         my $Mailer = new Lists::Utilities::Mailer(Debugger=>$self->{Debugger});
         my $PageGetter = new Lists::Admin::PageGetter(Debugger => $self->{Debugger});
         my $UserObj = $self->{DBManager}->getTableObj("User");
         my $Users = $UserObj->getSubscribedUsers();

         foreach my $ID(keys %{$Users}) {
            my $toEmail = $Users->{$ID}->{Email};

            $self->{Debugger}->debugNow("Would be sending to: $toEmail");

            my %Data;
            $Data{"User"} = $Users->{$ID};
            
            my $Subject = $PageGetter->processBasicContent($Email->{Subject}, \%Data);
            my $HTML = $PageGetter->processBasicContent($Email->{HTML}, \%Data);
            my $Text = $PageGetter->processBasicContent($Email->{Text}, \%Data);
            
            $Data{"BodyHTML"} = $HTML;
            $Data{"BodyTXT"} = $Text;   
            my $EmailHTML = $PageGetter->getBasicPage("$Lists::SETUP::DIR_PATH/emails/email_template.html", \%Data);
            my $EmailText = $PageGetter->getBasicPage("$Lists::SETUP::DIR_PATH/emails/email_template.txt", \%Data);
            
            my $ip = $ENV{'REMOTE_ADDR'};
            $ip =~ s/\.//g;
            my $boundary = "mimepart_" . time() . "_" . $ip;
            $Mailer->sendEmail($toEmail, 
                               $Lists::SETUP::MAIL_FROM_LISTS, 
                               $Subject, $EmailHTML, $EmailText, $boundary);
            
            my %EmailSent = ("EmailSent.EmailID" => $EmailID,
                             "EmailSent.EmailAddress" => $toEmail,
                             "EmailSent.Status" => 1);
            $EmailSentObj->store(\%EmailSent);
         }
      }
   }

   return "$Lists::SETUP::ADMIN_DIR_PATH/email_management.html";
}

=head2 SendEmailToList

Sends the email to a list of emails passed

=back

=cut

#############################################
sub SendEmailToList {
#############################################
   my $self = shift;

   $self->{Debugger}->debugNow("in Lists::Utilities::Email->SendEmailToList");

   my $EmailID = $self->{cgi}->{"Email.ID"};
   if($EmailID){

      my $EmailObj = $self->{DBManager}->getTableObj("Email");
      my $Email = $EmailObj->get_by_ID($EmailID);

      if($Email->{ID}){
         my $EmailSentObj = $self->{DBManager}->getTableObj("EmailSent");
         my $Mailer = new Lists::Utilities::Mailer(Debugger=>$self->{Debugger});
         my $PageGetter = new Lists::Admin::PageGetter(Debugger => $self->{Debugger});
         
         my @Emails = split(",", $self->{cgi}->{"Email.To"});
         foreach my $email(@{Emails}) {

            my %Data;
            my ($toEmail, $Name) = split("->",$email); 
            $Data{"User"}->{Email} = $toEmail;
            $Data{"User"}->{Username} = $Name;

            if($Mailer->emailValid($Data{"User"}->{Email})){

               $self->{Debugger}->debugNow("sending to $toEmail, $Name");
   
               my $Subject = $PageGetter->processBasicContent($Email->{Subject}, \%Data);
               my $HTML = $PageGetter->processBasicContent($Email->{HTML}, \%Data);
               my $Text = $PageGetter->processBasicContent($Email->{Text}, \%Data);
   
               $Data{"BodyHTML"} = $HTML;
               $Data{"BodyTXT"} = $Text;   
               my $EmailHTML = $PageGetter->getBasicPage("$Lists::SETUP::DIR_PATH/emails/email_template.html", \%Data);
               my $EmailText = $PageGetter->getBasicPage("$Lists::SETUP::DIR_PATH/emails/email_template.txt", \%Data);
   
               my $ip = $ENV{'REMOTE_ADDR'};
               $ip =~ s/\.//g;
               my $boundary = "mimepart_" . time() . "_" . $ip;
               $Mailer->sendEmail($toEmail, 
                                  $Lists::SETUP::MAIL_FROM_LISTS, 
                                  $Subject, $EmailHTML, $EmailText, $boundary);

               my %EmailSent = ("EmailSent.EmailID" => $EmailID,
                                "EmailSent.EmailAddress" => $toEmail,
                                "EmailSent.Status" => 1);
               $EmailSentObj->store(\%EmailSent);

            }
         }
      }
   }

   return "$Lists::SETUP::ADMIN_DIR_PATH/email_management.html";
}


=head2 EditEmail

Edits an email from the admin section

=over 4

=item B<Parameters :>

   1. $self - Reference to a EmailManager object

=back

=cut

#############################################
sub EditEmail {
#############################################
   my $self = shift;

   my $EmailObj = $self->{DBManager}->getTableObj("Email");
   my $Email = $EmailObj->get_by_ID($self->{cgi}->{"Email.ID"});
   foreach my $key (keys %{$Email}) {
      if($Email->{$key} ne $self->{cgi}->{"Email.".$key} && $key ne "Status" && $key ne "ID"){
         $EmailObj->update($key, $self->{cgi}->{"Email.".$key}, $self->{cgi}->{"Email.ID"});
      }
   }

   return "$Lists::SETUP::ADMIN_DIR_PATH/email_management.html";
}

=head2 DeleteHelpPage

Adds a new help page from the admin system

=over 4

=item B<Parameters :>

   1. $self - Reference to a HelpManager object

=item B<Returns :>

   1. 

=back

=cut

#############################################
sub DeleteEmail {
#############################################
   my $self = shift;

   my $EmailObj = $self->{DBManager}->getTableObj("Email");
   my $Email = $EmailObj->update("Status", 0, $self->{cgi}->{"Email.ID"});

   return "$Lists::SETUP::ADMIN_DIR_PATH/email_management.html";
}


=head2 GetEmailListingsAdmin

Gets the email listings for the admin

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the help listing

=back

=cut

#############################################
sub GetEmailListingsAdmin {
#############################################
   my $self = shift;

   $self->{Debugger}->debugNow("in Lists::EmailManager::GetEmailListingsAdmin"); 

   my $EmailObj = $self->{DBManager}->getTableObj("Email");
   my $Emails = $EmailObj->get_all();

   my $PageGetter = new Lists::Admin::PageGetter(Debugger => $self->{Debugger});

   my $Listings = "";
   foreach my $ID(sort{$Emails->{$a}->{Ordering} <=> $Emails->{$b}->{Ordering}} keys %{$Emails}) {
      $self->{Debugger}->debugNow("Email ID - $ID"); 

      my %Data;
      $Data{"EmailID"} = $ID;
      $Data{"Subject"} = $Emails->{$ID}->{Subject};
      $Data{"HTML"} = $Emails->{$ID}->{HTML};
      $Data{"Text"} = $Emails->{$ID}->{Text};

      $Listings .= $PageGetter->getBasicPage("$Lists::SETUP::ADMIN_DIR_PATH/edit_email.html", \%Data);

   }
   return $Listings;
}

1;

=head1 AUTHOR INFORMATION

   Author:  Marilyn Burgess
   Last Updated: 13/05/2009

=head1 BUGS

   Not known

=cut

