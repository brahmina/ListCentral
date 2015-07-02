package Lists::Utilities::Fail;
use strict;

use Lists::SETUP;


##########################################################
# Lists::Fail 
##########################################################

=head1 NAME

   Lists::Utilities::Fail.pm

=head1 SYNOPSIS

   $Fail = new Lists::Utilities::Fail(Debugger);

=head1 DESCRIPTION

Used to get resources from the web

=head2 Lists::Utilities::Fail Constructor

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

   $self->{Debugger}->debug("in Lists::Utilities::Fail constructor");
   
   return ($self); 
}

=head2 getFailImage

Gets a fail image for the error pages

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=back

=cut

#############################################
sub getFailImage {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListManager->getFailImage");

   my $FailDir = "$Lists::SETUP::DIR_PATH/images/fail/";
   if(! opendir(DIR, $FailDir)  ){
      my $error = "can't opendir $FailDir: $!";
      $self->{Debugger}->log($error);
      $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'MISC_ERROR'};
      return $self->getPage("$Lists::SETUP::DIR_PATH/error.html");
   }
   my @files = grep {-f "$FailDir/$_" } readdir(DIR);
   closedir DIR;

   my $random = int(rand(scalar(@files))); 
   my $failimage = @files[$random];

   my $pathToFailImage = "$FailDir$failimage";

   return $pathToFailImage;
}

1;

=head1 AUTHOR INFORMATION

   Author:  Marilyn Burgess
   Last Updated: 20/05/2009

=head1 BUGS

   Not known

=cut

