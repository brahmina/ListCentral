package Lists::Utilities::ReCaptcha;
use strict;

use Lists::SETUP;
use Captcha::reCAPTCHA;

##########################################################
# Lists::Utilities::ReCaptcha 
##########################################################

=head1 NAME

   Lists::ReCaptcha.pm

=head1 SYNOPSIS

   $Mailer = new Lists::Utilities::ReCaptcha(Debugger);

=head1 DESCRIPTION

Used to create, manage, and send emails for the Lists system.

=head2 Lists::Utilities::ReCaptcha Constructor

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

   $self->{Debugger}->debug("in Lists::Mailer constructor");
   
   return ($self); 
}

=head2 getReCaptchaHTML

Gets the HTML for the ReCaptcha human checker

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object

=item B<Returns :>

   1. $HTML - The HTML for the ReCaptcha

=back

=cut

#############################################
sub getReCaptchaHTML {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::Utilities::ReCaptcha->getReCaptchaHTML");

   my $c = Captcha::reCAPTCHA->new;

   # Output form       Public Key

   # listcentral.me
   my $html = $c->get_html( '6Lc_dgMAAAAAAOeMCNjEefx2EUZcQP6-JWKfemJq ' );
print STDERR "reCAPTCHA: $html\n";
   # go-list-yourself.com
   #my $html = $c->get_html( '6LdopAMAAAAAAHV0LjaEnfNDByLsbnhPB-DyMVX_  ' );

   return $html;
}

=head2 checkReCaptchaResponse

Checks the reCaptcha response

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object
   2. $challenge
   3. $response

=item B<Returns :>

   1. $HTML - The HTML for the ReCaptcha

=back

=cut

#############################################
sub checkReCaptchaResponse {
#############################################
   my $self = shift;
   my $challenge = shift;
   my $response = shift;

   $self->{Debugger}->debug("in Lists::Utilities::ReCaptcha->checkReCaptchaResponse");

   my $c = Captcha::reCAPTCHA->new;

   # Verify submission
   my $result = $c->check_answer(
       # Private Key
       # listcentral.com 
       '6Lc_dgMAAAAAAAzVlqPTK1BJYNqAMsTbKwczn5ZR', $ENV{'REMOTE_ADDR'},
       # go-list-yourself.com
       #'6LdopAMAAAAAAIpV-CbyzjVrRJlkQusj83D88Y8F', $ENV{'REMOTE_ADDR'},
       $challenge, $response
   );

   my $error = "";
   my $isValid = 0;
   if($result->{is_valid}){
      $isValid = 1; 
   }else{
       # Error
       $error = $result->{error};
   }
   return $isValid, $error;
}


1;

=head1 AUTHOR INFORMATION

   Author:  Marilyn Burgess
   Last Updated: 10/10/2008

=head1 BUGS

   Not known

=cut
