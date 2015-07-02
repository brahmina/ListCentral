package Lists::Utilities::WebResourceGetter;
use strict;

use Lists::SETUP;

##########################################################
# Lists::WebResourceGetter 
##########################################################

=head1 NAME

   Lists::Utilities::WebResourceGetter.pm

=head1 SYNOPSIS

   $WebResourceGetter = new Lists::Utilities::WebResourceGetter(Debugger);

=head1 DESCRIPTION

Used to get resources from the web

=head2 Lists::Utilities::WebResourceGetter Constructor

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

   $self->{Debugger}->debug("in Lists::Utilities::WebResourceGetter constructor");
   
   return ($self); 
}


=head2 getWebResource

Gets and saves a web resource as specified

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object
   2. $resource - the email address to send the email to
   3. $saveLocation - the subject of the email to be sent

=item B<Returns :>

   1. $results - 1 if successful, 0 otherwise

=back

=cut

#############################################
sub getWebResource {
#############################################
   my $self = shift;
   my $resource = shift;
   my $saveLocation = shift;

   $self->{Debugger}->debug("in Lists::Utilities::Amazon::getWebResource with $resource, $saveLocation");

   use LWP::Simple;
   my $content = get($resource);

   open FILE, "+>$saveLocation" || die "Cannot open file $saveLocation $!\n";
   print FILE $content;
   close FILE;
}


1;

=head1 AUTHOR INFORMATION

   Author:  Marilyn Burgess
   Last Updated: 13/03/2009

=head1 BUGS

   Not known

=cut

