package ListCentral::Printer;
use strict;

use ListCentral::SETUP;

##########################################################
# ListCentral::Printer
##########################################################

=head1 NAME

   ListCentral::Printer.pm

=head1 SYNOPSIS

   $Printer = new Printer($dbh, $Debugger);

=head1 DESCRIPTION

Used to handle the page requests to the Lists web application

=head2 ListCentral::Printer Constructor

=over 4

=item B<Parameters :>

   1. $dbh
   2. $Debugger

=back

=cut

########################################################
sub new {
########################################################
   my $classname=shift; 
   my $self; 
   %$self=@_; 
   bless $self,ref($classname)||$classname;

   if(!$self->{dbh}){
      $self->{Debugger}->log("Where's ListCentral::Printer's dbh?");
   }

   return ($self); 
}

=head2 print_template

Prints the Lists main templates and determines what is to go inside

=over 4

=item B<Parameters :>

   1. $self - Reference to a Printer object
   2. $main_content - the main content to go into the template

=item B<Returns :>

   1. $todo - "do_nothing" the next thing to do.

=back

=cut

#############################################
sub print_template {
#############################################
   my $self = shift;
   my $main_content = shift;
   my $file_requested = shift;

   $self->{Debugger}->debug("in ListCentral::Printer->print_template with $file_requested");

   # Temporary block IE
   if($ENV{HTTP_USER_AGENT} =~ m/MSIE/ && $ListCentral::SETUP::BLOCK_IE){
      print "IE is currently not supported. Please use firefox:<br /><br/><a href='http://www.mozilla.com/en-US/firefox/'>Get Firefox!</a>";
      return "do_mothing";
   }

   my $template = "";
   
   # Under construction
   my $IP = $ENV{'REMOTE_ADDR'};
   my $IPisPermitted = 0;
   foreach my $permittedIP(@ListCentral::SETUP::PERMITTED_IPS){
      if($IP eq $permittedIP){
         $IPisPermitted = 1;
      }
   }
   # Permitted IPs
   if (!$IPisPermitted && $ListCentral::SETUP::UNDER_CONSTUCTION) {
      $template = $ListCentral::SETUP::HIDING;
      $main_content = $self->{ListManager}->getPage("$ListCentral::SETUP::DIR_PATH/under_construction.html");
   }else{
      if($ListCentral::SETUP::SMALL_TEMPLATES{$file_requested}){
         $template = $ListCentral::SETUP::SMALL_TEMPLATE;
      }elsif($file_requested =~ m/image\.html/){
         $template = $ListCentral::SETUP::IMAGE_TEMPLATE;
      }else{
         $template = $ListCentral::SETUP::MAIN_TEMPLATE;
      }
   }
   $self->{Debugger}->debug("Template? $file_requested -> $template");

   my $UserID = $self->{UserManager}->{ThisUser}->{ID};

   my $buffer = $self->{ListManager}->processPage($template);

   $buffer =~ s/<!--MainContent-->/$main_content/;

   print $buffer;

   return "do_nothing";
}

1;

=head1 AUTHOR INFORMATION

   Author: 
   Last Updated: 30/11/2007

=head1 BUGS

   Not known

=head1 SEE ALSO


=cut

=over

=cut

