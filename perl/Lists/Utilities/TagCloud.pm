package Lists::Utilities::TagCloud;
use strict;

use Lists::SETUP;

use URI::Escape;
use List::Util qw[min max];

##########################################################
# Lists::TagCloud 
##########################################################

=head1 NAME

   Lists::Utilities::TagCloud.pm

=head1 SYNOPSIS

   $3DTagCloud = new Lists::Utilities::TagCloud(Debugger);

=head1 DESCRIPTION

Used to get resources from the web

=head2 Lists::Utilities::TagCloud Constructor

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

   $self->{Debugger}->debug("in Lists::Utilities::TagCloud constructor");
   
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
   $self->{Debugger}->debug("in Lists::Utilitites::TagCloud::round with $number -> $rounded"); 

   return $rounded;
}

=head2 getTagCloudHash

Gets the 3D Tag Cloud adapted from Cumulus

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the tag cloud

=back

=cut

#############################################
sub getTagCloudHash {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::get3DTagCloud"); 

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

   $self->{Debugger}->debug("in Lists::Utilitites::TagCloud::generateTagCloudTags"); 

   my $number_of_tags = $Lists::SETUP::TAG_CLOUD_NUMBER_OF_TAGS;
   my $min_size = $Lists::SETUP::TAG_CLOUD_MIN_SIZE;
   my $max_size = $Lists::SETUP::TAG_CLOUD_MAX_SIZE;

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

   $self->{Debugger}->debug("in Lists::Utilitites::TagCloud::generateTagCloudXML"); 

   my $tagcloudXMLfile = $Lists::SETUP::DIR_PATH . "/media/tagcloud.xml";
   my $thing = -M $tagcloudXMLfile;

   if( -M $tagcloudXMLfile > 0.00005 ){
      # More than an hour old
      unlink($tagcloudXMLfile);
   }
   if(! -e $tagcloudXMLfile){ 
      my $TagCloudHash = $self->getTagCloudHash();
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

   $self->{Debugger}->debug("in Lists::Utilitites::TagCloud::get3DTagCloud"); 

   # Check the age of the xml file, if it's older than an hour, regenerate it
   $self->generateTagCloudXML();

   my $Cumulus = qq~<div id="flashcontent">tag cloud</div>
                    <script type="text/javascript" src="/js/swfobject.js"></script>
                    <script type="text/javascript">
                     var so = new SWFObject("/media/tagcloudtest.swf", "tagcloud", "300", "280", "7", "#ffffff");
                     so. addVariable("distr", "true");
                     so.addVariable("tcolor", "0x1d687a");
                     so.addVariable("tcolor2", "0x121d52");
                     so.addVariable("hicolor", "0x121d52");
                     so.write("flashcontent");
                     </script>~;
   return $Cumulus;
}

=head2 writeHTMLTagCloud

Writes the html for the full tag cloud in html to the appropriate file

=over 4

=item B<Parameters :>

   1. $self - Reference to a TagCloud object

=back

=cut

#############################################
sub writeHTMLTagCloud {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::Utilitites::TagCloud::writeHTMLTagCloud"); 

   my $TagCloudHash = $self->getTagCloudHash();
   my $HTMLCloud = HTML::TagCloud->new;

   foreach my $tag(keys %{$TagCloudHash}) {
      $HTMLCloud->add($tag, $TagCloudHash->{$tag}->{TagURL}, $TagCloudHash->{$tag}->{Count});
   }
   my $html = $HTMLCloud->html();

   my $tagHTML = qq~ <link type="text/css" rel="stylesheet" href="/css/tagcloud.css">
                     <h3>List Central Tag Cloud</h3><br />
                     $html~;

   my $tagcloudHTMLFile = $Lists::SETUP::DIR_PATH . "/about/tagcloud.html";
   open FILE, "+>$tagcloudHTMLFile" || die "Cannot write file $_";
   print FILE $tagHTML;
   close FILE;
}

1;

=head1 AUTHOR INFORMATION

   Author:  Marilyn Burgess
   Last Updated: 13/05/2009

=head1 BUGS

   Not known

=cut

