package ListCentral::Utilities::3DTagCloud;
use strict;

use ListCentral::SETUP;

use URI::Escape;
use List::Util qw[min max];

##########################################################
# ListCentral::3DTagCloud 
##########################################################

=head1 NAME

   ListCentral::Utilities::3DTagCloud.pm

=head1 SYNOPSIS

   $3DTagCloud = new ListCentral::Utilities::3DTagCloud(Debugger);

=head1 DESCRIPTION

Used to get resources from the web

=head2 ListCentral::Utilities::3DTagCloud Constructor

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

   $self->{Debugger}->debug("in ListCentral::Utilities::3DTagCloud constructor");
   
   return ($self); 
}


=head2 round

Returns the round of the number passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object
   2. $number

=item B<Returns :>

   1. $rounded_number

=back

=cut

#############################################
sub round {
#############################################
   my $self = shift;
   my($number) = shift;


   my $rounded = int($number + .5 * ($number <=> 0));
   $self->{Debugger}->debug("in ListCentral::Utilitites::3DTagCloud::round with $number -> $rounded"); 

   return $rounded;
}

=head2 get3DTagCloudHash

Gets the 3D Tag Cloud adapted from Cumulus

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the tag cloud

=back

=cut

#############################################
sub get3DTagCloudHash {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::ListsManager::get3DTagCloud"); 

   my $TagObj = $self->{DBManager}->getTableObj("Tag");

   my $Tags = $TagObj->getPublicTags();

   my %TagsHash;
   foreach  my $ID(keys %{$Tags}) {
      my $TagURL = $TagObj->getTagURL($Tags->{$ID});
      $TagsHash{$Tags->{$ID}->{Name}}->{Count} = $Tags->{$ID}->{TagCount};
      $TagsHash{$Tags->{$ID}->{Name}}->{TagURL} = $TagURL;
   }

   return \%TagsHash;

}

=head2 generateTagCloudTags

Returns the tag cloud links for the tags passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object
   2. $number

=item B<Returns :>

   1. $rounded_number

=back

=cut

#############################################
sub generateTagCloudTags {
#############################################
   my $self = shift;
   my $tag_cloud_tags = shift;

   $self->{Debugger}->debug("in ListCentral::Utilitites::3DTagCloud::generateTagCloudTags"); 

   my $number_of_tags = $ListCentral::SETUP::TAG_CLOUD_NUMBER_OF_TAGS;
   my $min_size = $ListCentral::SETUP::TAG_CLOUD_MIN_SIZE;
   my $max_size = $ListCentral::SETUP::TAG_CLOUD_MAX_SIZE;

   my @counts;
   for my $tag (keys %{$tag_cloud_tags}) {
          push(@counts, $tag_cloud_tags->{$tag}->{Count});
   }
   my $max_qty = 300;
   my $min_qty = 1;

   # find the range of values
   my $spread = $max_qty - $min_qty;
   if ($spread == 0) { 
          $spread = 1;
   }
   # set the font-size increment
   my $step = ($max_size - $min_size) / ($spread);

   my $tags;
   foreach my $tag (keys %{$tag_cloud_tags}) {
      my $thing = $min_size + (($tag_cloud_tags->{$tag}->{Count} - $min_qty) * $step);
      my $size = $self->round($thing);
      $tags .= "<a href=\"" . $tag_cloud_tags->{$tag}->{TagURL} . "\" class=\"tag-link\" title=\"" . $tag . 
                "\" rel=\"tag\" style=\"font-size: " . $size . "pt;\">" . $tag . "</a>\n";
   }

   return "<tags>$tags</tags>";
}

=head2 generateTagCloudXML

Returns the tag cloud links for the tags passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object
   2. $number

=item B<Returns :>

   1. $rounded_number

=back

=cut

#############################################
sub generateTagCloudXML {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Utilitites::3DTagCloud::generateTagCloudXML"); 

   my $tagcloudXMLfile = $ListCentral::SETUP::DIR_PATH . "/media/tagcloud.xml";
   my $thing = -M $tagcloudXMLfile;

   if( -M $tagcloudXMLfile > 0.00005 ){
      # More than an hour old
      unlink($tagcloudXMLfile);
   }
   if(! -e $tagcloudXMLfile){ 
      my $TagCloudHash = $self->get3DTagCloudHash();
      my $tagXML = $self->generateTagCloudTags($TagCloudHash);
      open FILE, ">>$tagcloudXMLfile" || die "Cannot write file $_";
      print FILE $tagXML;
      close FILE;
   }
}

=head2 get3DTagCloud

Returns the html for the 3dTagCloudBox

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object

=item B<Returns :>

   1. $html

=back

=cut

#############################################
sub get3DTagCloud {
#############################################
   my $self = shift;
   my $staticUrl = shift;
   my $Tags = shift;

   $self->{Debugger}->debug("in ListCentral::Utilitites::3DTagCloud::get3DTagCloud"); 

   # Check the age of the xml file, if it's older than an hour, regenerate it
   $self->generateTagCloudXML();

   my $Cumulus = qq~<div id="3DTagCloud">tag cloud</div>
                    <script type="text/javascript" src="/js/swfobject.js"></script>
                    <script type="text/javascript">
                     var so = new SWFObject("/media/tagcloudtest.swf", "tagcloud", "300", "280", "7", "#ffffff");
                     so. addVariable("distr", "true");
                     so.addVariable("tcolor", "0x1d687a");
                     so.addVariable("tcolor2", "0x121d52");
                     so.addVariable("hicolor", "0x121d52");
                     so.write("3DTagCloud");
                     </script>~;
   return $Cumulus;
}


1;

=head1 AUTHOR INFORMATION

   Author:  Brahmina Burgess
   Last Updated: 13/05/2009

=head1 BUGS

   Not known

=cut

