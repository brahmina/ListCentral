package ListCentral::Utilities::GoogleImageGetter;
use strict;

use ListCentral::SETUP;

use WWW::Google::Images;

##########################################################
# ListCentral::GoogleImageGetter 
##########################################################

=head1 NAME

   ListCentral::Utilities::GoogleImageGetter.pm

=head1 SYNOPSIS

   $GoogleImageGetter = new ListCentral::Utilities::GoogleImageGetter(Debugger);

=head1 DESCRIPTION

Used to get images from the internet

=head2 ListCentral::Utilities::GoogleImageGetter Constructor

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

   $self->{Debugger}->debug("in ListCentral::Utilities::GoogleImageGetter constructor");
   
   return ($self); 
}

=head2 getImageURLs

Given a query, this module returns 

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object
   2. $query - the email address to send the email to

=item B<Return :>

   1. $imageURLS - Reference to an array of image urls

=back

=cut

#############################################
sub getImageURLs {
#############################################
   my $self = shift;
   my $query = shift;
   my $limit = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::GoogleImageGetter::getImageURLs");

   if(!$limit){
      $limit = $<--PackageName-->::SETUP::GOOGLE_IMAGE_GETTER_LIMIT;
      if(!$limit){
         $limit = 10;
      }
   }
   my $agent = WWW::Google::Images->new(
      server => 'images.google.com',
      #proxy  => 'my.proxy.server:port',
   );
   my @imageURLs;
   while (my $image = $result->next()) {
      my $image = $image->content_url();
      push(@imageURLs, $image);
      $images .= "$image<br /><image src=\"$image\"><br>";
      #print $image->content_url()."<br />";
      #print $image->context_url()."<br />";
      #print $image->save_content(base => 'image' . $count)."<br />";
      #print $image->save_context(base => 'page' . $count)."<br />";
   }

   return \@imageURLs;
}

=head2 getImageURLs

Given a query, this module returns 

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object
   2. $query - the email address to send the email to

=item B<Return :>

   1. $imageURLS - Reference to an array of image urls

=back

=cut

#############################################
sub getImagesHTML {
#############################################
   my $self = shift;
   my $query = shift;
   my $limit = shift;
   my $template = shift;
   my $subtemplate = shift;
   my $width = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::GoogleImageGetter::getImageURLs");

   if(!$limit){
      $limit = $<--PackageName-->::SETUP::GOOGLE_IMAGE_GETTER_LIMIT;
      if(!$limit){
         $limit = 10;
      }
   }
   my $imageURLs = $self->getImageURLs($query, $limit);

   if(!$template){
      ($template, $subtemplate) = @<--PackageName-->::SETUP::GOOGLE_IMAGE_GETTER_SUB_TEMPLATES;
      if(!$limit){
         $limit = 10;
      }
   }
   if(!$width){
      $width = @<--PackageName-->::SETUP::GOOGLE_IMAGE_WIDTH;
      if(!$width){
         $limit = 200;
      }
   }

   my $images = "";
   foreach my $url(@{$imageURLs}) {
      open(TEMPLATE, $subtemplate) or die "cannot open file: $subtemplate : $!";
      while (<TEMPLATE>) {
         my $line = $_;
         if($line =~ m//){
            $line =~ s//$url/;
         }
         if($line =~ m//){
            $line =~ s//$width/;
         }
         $images .= $line;
      }
      close TEMPLATE;
   }

   my $html = "";
   open(TEMPLATE, $template) or die "cannot open file: $template : $!";
   while (<TEMPLATE>) {
      my $line = $_;
      if($line =~ m//){
         $line =~ s//$images/;
      }
      $html .= $line;
   }
   close TEMPLATE;

   return $html;
}

1;

=head1 AUTHOR INFORMATION

   Author:  With help from the ApplicationFramework
   Last Updated: 22/10/2007

=head1 BUGS

   Not known

=cut

