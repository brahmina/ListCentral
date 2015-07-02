package Lists::Admin::PageGetter;
use strict;

use Lists::SETUP;
use Lists::Utilities::Date;
use Lists::Utilities::Search;

##########################################################
# Lists::Admin::PageGetter 
##########################################################

=head1 NAME

   Lists::Admin::PageGetter.pm

=head1 SYNOPSIS

   $ListPageGetter = new Lists::Admin::PageGetter($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the List application

=head2 Lists::List Constructor

=over 4

=item B<Parameters :>

   1. $dbh
   3. $debug

=back

=cut

########################################################
sub new {
########################################################
   my $classname = shift; 
   my $self; 
   %$self = @_; 
   bless $self, ref($classname)||$classname;

   $self->{Debugger}->debug("in Lists::Admin::PageGetter constructor");

   if(!$self->{Debugger}){
      print STDERR "No debugger? $self->{Debugger}\n";
   }


   $self->{ErrorMessages} = "";

   return ($self); 
}

=head2 getBasicPage

A more basic version of getPage 

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $page - the page to print
   3. $Data - Up to 2 level hash with corresponding data

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub getBasicPage {
#############################################
   my $self = shift;
   my $page = shift;
   my $Data = shift;

   $self->{Debugger}->debug("in getBasicPage with page $page, $Data");

   # File Cache
   my @lines;
   if($self->{BasicFileCache}->{$page}){
      @lines = @{$self->{BasicFileCache}->{$page}};
   }else{     
      my $template = $page;
      if(! open (PAGE, $template)){
         my $error = "Cannot open file: $template $!";
         $self->{Debugger}->throwNotifyingError($error);
         $self->{ErrorMessages} = $error;
         return $self->getPage("$Lists::SETUP::DIR_PATH/error.html");
      }
      @lines = <PAGE>;
      close PAGE;

      my @linesSave = @lines;
      $self->{BasicFileCache}->{$page} = \@linesSave;
   }

   my $content = $self->getBasicPageContent(\@lines, $Data);

   return $content;
}

=head2 processBasicContent

A more basic version of getPage 

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $page - the page to print
   3. $Data - Up to 2 level hash with corresponding data

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub processBasicContent {
#############################################
   my $self = shift;
   my $content = shift;
   my $Data = shift;

   my @lines = split("\n", $content);

   my $content = $self->getBasicPageContent(\@lines, $Data);

   return $content;
}

=head2 getBasicPageContent

A more basic version of getPage 

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $lines - Ref to an array with the lines
   3. $Data - Up to 2 level hash with corresponding data

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub getBasicPageContent {
#############################################
   my $self = shift;
   my $lines = shift;
   my $Data = shift;

   my $content = "";
   foreach my $line (@{$lines}) {
      if($line =~ m/<!--(.+)-->/){
         #$self->{Debugger}->debug("getPage tag: $1");
         if($line =~ m/<!--URL-->/){
            my $url = "http://$ENV{HTTP_HOST}";
            $line =~ s/<!--URL-->/$url/;
         }elsif($line =~ m/<!--SETUP\.([\w_]+)-->/){
            my $variable = $1;
            $line =~ s/<!--SETUP\.$variable-->/$Lists::SETUP::CONSTANTS{$variable}/;
         }elsif($line =~ m/<!--CGI\.([\w\.]+)-->/){
            my $field = $1;
            my $value = $self->{cgi}->{$field};
            $line =~ s/<!--CGI\.$field-->/$value/;
         }elsif($line =~ m/<!--GetOutputFromFunc\.(\w+)-->/){
            my $func = $1;
            my $output = $self->$func();
            $line =~ s/<!--GetOutputFromFunc\.$func-->/$output/;
         }elsif($line =~ m/<!--Data\.([\w_]+)-->/){
            my $field = $1;
            if($field =~ m/(\w+)_(\w+)/){
               my $hashName = $1;
               my $hashValue = $2;
               $line =~ s/<!--Data\.$field-->/$Data->{$hashName}->{$hashValue}/;
            }else{
               $line =~ s/<!--Data\.$field-->/$Data->{$field}/;
            }
         }else{
            if($line =~ m/<!--(.+)-->/){
               my $tag = $1;
               #$self->{Debugger}->log("ERROR: Unknown Tag: $tag");
            }else{
               #$self->{Debugger}->log("ERROR: Unknown Tag, Line: <textarea>$line</textarea>");
            }            
         }
      }
      $content .= $line;
   }
   return $content;
}

1;

=head1 AUTHOR INFORMATION

   Author: Marilyn Burgess with help from the ApplicationFramework
   Created: 1/11/2007

=head1 BUGS

   Not known

=cut
