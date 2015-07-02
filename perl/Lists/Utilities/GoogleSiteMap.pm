package Lists::Utilities::GoogleSiteMap;
use strict;

use Lists::SETUP;
use WWW::Google::SiteMap;


##########################################################
# Lists::GoogleSiteMap 
##########################################################

=head1 NAME

   Lists::Utilities::GoogleSiteMap.pm

=head1 SYNOPSIS

   $GoogleSiteMap = new Lists::Utilities::GoogleSiteMap(Debugger);

=head1 DESCRIPTION

Used to place google analytic tracting information on the site pages

=head2 Lists::Utilities::GoogleSiteMap Constructor

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

   $self->{Debugger}->debug("in Lists::Utilities::GoogleSiteMap constructor");
   
   return ($self); 
}

=head2 generateSiteMap

Generates and writes the Google Site Map

=back

=cut

#############################################
sub generateSiteMap {
#############################################
   my $self = shift;
   my $query = shift;
   my $limit = shift;

   # First we have to delete the old site maps
   my $command = "rm $Lists::SETUP::DIR_PATH/*.gz";
   my $output = `$command`;

   my $mapCount = 1;
   my $sitemap = $Lists::SETUP::GOOGLE_SITE_MAP . $mapCount . ".gz";
   $mapCount++;
   my $map = WWW::Google::SiteMap->new(file => $sitemap);
   $map->pretty("nice");

   # Main page, changes a lot because of the blog
   $map->add(WWW::Google::SiteMap::URL->new(
    loc        => $Lists::SETUP::URL,
    changefreq => 'always',
    priority   => 1.0,
   ));
   
   # Top level directories, don't change as much, and have a lower priority
   $map->add({
    loc        => "$Lists::SETUP::URL/$_.html",
    changefreq => 'weekly',
    priority   => 0.9, # lower priority than the home page
   }) for qw(
    about contact privacy terms tagcloud
   );

   my $count = 6;
   my $ListObj = $self->{DBManager}->getTableObj("List");
   my $Lists = $ListObj->get_with_restraints("Public = 1");

   my $ListGroupObj = $self->{DBManager}->getTableObj("ListGroup");
   
   # Lists - get all public lists
   foreach my $ID(sort keys %{$Lists}) {
      if($count >= 50000){
         $map->write;

         $sitemap = $Lists::SETUP::GOOGLE_SITE_MAP . $mapCount . ".gz";
         $map = WWW::Google::SiteMap->new(file => "$Lists::SETUP::GOOGLE_SITE_MAP");
         $mapCount++;
         $count = 1;
      }
   
      my $ListGroup = $ListGroupObj->get_field_by_ID("Name", $Lists->{$ID}->{ListGroupID});

      my $url = $Lists::SETUP::URL . $ListObj->getListURL($Lists->{$ID}, $ListGroup);
      $map->add({
          loc        => $url,
          changefreq => 'daily',
          priority   => 0.8, 
         });
      $count++; 
   }
   
   $map->write;
}
1;

=head1 AUTHOR INFORMATION

   Author:  With help from the ApplicationFramework
   Last Updated: 22/10/2007

=head1 BUGS

   Not known

=cut

