package Lists::Utilities::Mailer;
use strict;

use Lists::SETUP;
use Email::Valid;
use Net::SMTP::SSL;
use Mail::Sendmail;

##########################################################
# Lists::Mailer 
##########################################################

=head1 NAME

   Lists::Utilities::Mailer.pm

=head1 SYNOPSIS

   $Mailer = new Lists::Utilities::Mailer(Debugger);

=head1 DESCRIPTION

Used to create, manage, and send emails for the Lists system.

=head2 Lists::Utilities::Mailer Constructor

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

   #$self->{Debugger}->debug("in Lists::Utilities::Mailer constructor");
   
   return ($self); 
}


=head2 sendEmail

Sends email to the email address passed with the body and subject line passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object
   2. $toEmail - the email address to send the email to
   2. $subject - the subject of the email to be sent
   3. $body - the body of the email 

=back

=cut

#############################################
sub sendEmail {
#############################################
   my $self = shift;
   my $toEmail = shift;
   my $fromEmail = shift;
   my $subject = shift;
   my $html = shift;
   my $text = shift;
   my $boundary = shift;

   $self->{Debugger}->debug("in Lists::Utilities::Mailer $toEmail from: $fromEmail");

   if(! $toEmail || ! $fromEmail){
      $self->{Debugger}->debug("Not sending!");
      return;
   }

   my $smtp;
   if (not $smtp = Net::SMTP::SSL->new($Lists::SETUP::MAIL_HOST,
                                     Port => $Lists::SETUP::MAIL_PORT,
                                     Debug => $self->{Debugger}->{debug})) { 
      die "Could not connect to mail server: $Lists::SETUP::MAIL_HOST\n";
   }
   
  $smtp->auth($fromEmail, $Lists::SETUP::MAIL_PASSWORD) || die "Authentication failed! $fromEmail, $Lists::SETUP::MAIL_PASSWORD\n";
   
   $smtp->mail($fromEmail . "\n");
   my @recepients = split(/,/, $toEmail);
   foreach my $recp (@recepients) {
       $smtp->to($recp . "\n");
   }

   $smtp->data();
   $smtp->datasend("From: " . $fromEmail . "\n");
   $smtp->datasend("To: " . $toEmail . "\n");
   $smtp->datasend("Subject: " . $subject . "\n");
   $smtp->datasend("Errors-To: $Lists::SETUP::TO_IT_EMAIL\n");

   $smtp->datasend("MIME-Version: 1.0\n");
   $smtp->datasend("Content-Type: multipart/alternative; boundary=\"$boundary\"\n");
   $smtp->datasend("\n--$boundary\n");
   $smtp->datasend("Content-Type: text/plain; charset=iso-8859-1\n");
   $smtp->datasend("Content-Transfer-Encoding: quoted-printable\n");
   $smtp->datasend($text . "\n\n");
   $smtp->datasend("\n--$boundary\n");
   $smtp->datasend("Content-Type: text/html; charset=utf-8\n");
   $smtp->datasend("Content-Transfer-Encoding: Quoted-printable\n");
   $smtp->datasend("Content-Disposition: inline\n");
   $smtp->datasend($html . "\n");
   #$smtp->datasend("\n--$boundary\n");
   $smtp->dataend();
   $smtp->quit;   
}

=head2 sendEmailToIT

Sends email to IT as per the email in Lists::SETUP::TO_IT_EMAIL

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists object
   2. $subject - the subject of the email to be sent
   3. $body - the body of the email 

=back

=cut

#############################################
sub sendEmailToIT {
#############################################
   my $self = shift;
   my $subject = shift;
   my $body = shift;

   $self->{Debugger}->debug("Lists::Utilities::Mailer::sendEmailToIT sending email to it with subject: $subject");

   my $smtp;
   if (not $smtp = Net::SMTP::SSL->new($Lists::SETUP::MAIL_HOST,
                                        Port => $Lists::SETUP::MAIL_PORT,
                                        Debug => 0)) { 
      $self->{Debugger}->debug("Could not connect to mail server $Lists::SETUP::MAIL_HOST on $Lists::SETUP::MAIL_PORT");
      return;
   }

   $self->{Debugger}->debug("banner: " . $smtp->banner() . ", message before: " . $smtp->message());
   my $authcode = $smtp->auth($Lists::SETUP::FROM_IT_EMAIL, $Lists::SETUP::MAIL_PASSWORD);
   $self->{Debugger}->debug("authcode: $authcode, message after: " . $smtp->message());
   if(! $authcode){
       $self->{Debugger}->debug("Authentication failed! $Lists::SETUP::FROM_IT_EMAIL, $Lists::SETUP::MAIL_PASSWORD");
       return;
   }

   
   $smtp->mail($Lists::SETUP::FROM_IT_EMAIL . "\n");
   my @recepients = split(/,/, $Lists::SETUP::TO_IT_EMAIL);
   foreach my $recp (@recepients) {
       $smtp->to($recp . "\n");
   }

   $smtp->data();
   $smtp->datasend("From: " . $Lists::SETUP::FROM_IT_EMAIL . "\n");
   $smtp->datasend("To: " . $Lists::SETUP::TO_IT_EMAIL . "\n");
   $smtp->datasend("Subject: " . $subject . "\n");
   $smtp->datasend("MIME-Version: 1.0\n");
   $smtp->datasend("Content-Type: text/plain; charset=iso-8859-1\n");
   $smtp->datasend("Content-Transfer-Encoding: quoted-printable\n");
   $smtp->datasend($body . "\n");
   $smtp->dataend();
   $smtp->quit;   

}

=head2 emailValid

Tests if an email address is valid

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists object
   2. $emailAddress

=back

=cut

#############################################
sub emailValid {
#############################################
   my $self = shift;
   my $email = shift;

   my $valid = (Email::Valid->address( -address => $email,
                                       -mxcheck => 1 ) ? 'yes' : 'no');

   if($valid eq "yes"){
      return 1;
   }else{
      return 0;
   }
}



1;

=head1 AUTHOR INFORMATION

   Author:  With help from the ApplicationFramework
   Last Updated: 22/10/2007

=head1 BUGS

   Not known

=cut


