package Lists::Utilities::BlogInteraction;
use strict;

use Lists::SETUP;
use Lists::UserManager;

##########################################################
# Lists::BlogInteraction 
##########################################################

=head1 NAME

   Lists::Utilities::BlogInteraction.pm

=head1 SYNOPSIS

   Lists::Utilities::BlogInteraction::function(Debugger);

=head1 DESCRIPTION

Used to interact with the List Central Blog

=head2 writeAboutBlogTeaser

Supposed to be called froma cron, writes the content of /about_blog_teaser.html for the about page

=over 4

=item B<Parameters :>

   1. $Debugger - Reference to a BlogInteraction

=back

=cut

#############################################
sub writeAboutBlogTeaser {
#############################################
   my $DBManager = shift;
   my $UserManager = shift;

   #print STDERR "in Lists::Utilitites::BlogInteraction::writeAboutBlogTeaser\n"; 

   my $aboutTeaserFile = "$Lists::SETUP::DIR_PATH/about/about_blog_teaser.html";
   my $blogTeaser = getBlogTeaser($Lists::SETUP::BLOG_TEASER_NUMBER_OF_POSTS, $DBManager, $UserManager);
   if(! open FILE, "+>$aboutTeaserFile"){
      print STDERR "Cannot write file $aboutTeaserFile -> $! .";
      die;
   }
   print FILE $blogTeaser;
   close FILE;
}

=head2 getBlogTeaser

Returns the html for the about page blog teaser bit

=over 4

=item B<Parameters :>

   1. $numberOfPostsToGet - Number of posts to write
   2. $Debugger
   3. $DBManager

=item B<Returns :>

   1. $html

=back

=cut

#############################################
sub getBlogTeaser {
#############################################
   my $numberOfPostsToGet = shift;
   my $DBManager = shift;
   my $UserManager = shift;

   #print SDTERR "in Lists::Utilities::BlogInteraction::getBlogTeaser with $numberOfPostsToGet\n";

   use XML::Simple;
   use LWP::Simple;
        
   my $xml = get($Lists::SETUP::BLOG_RSS_URL);

   my $xmlsimple = XML::Simple->new();
   my $response = $xmlsimple->XMLin($xml);

   my $count = 0;
   my $rssContent = "<ul class='BlogTeaser'>";
   foreach my $item_hash(@{$response->{channel}->{item}}){
       if($count < $numberOfPostsToGet){
          my $param = "";
          if($item_hash->{'dc:creator'} eq "marilyn"){
             $param = "77BlogTeaserAvatar";
          }elsif($item_hash->{'dc:creator'} eq "juan"){
             $param = "74BlogTeaserAvatar";
          }
          my $avatar = getAvatar($param, $DBManager, $UserManager);
          $rssContent .=  qq~<li>$avatar
    			       <a href="$item_hash->{'feedburner:origLink'}">$item_hash->{'title'}</a> by $item_hash->{'dc:creator'}
			       <p>$item_hash->{'description'}</p></li>~;
	   $count++;
       }
   }
   $rssContent .= "</ul>";

   #print STDERR "rssContent: $rssContent";
   return $rssContent;
}


=head2 getAvatar

Given a UserID returns the users avatar

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists object
   2. $User - Reference to a hash with the new user to send the welcome email to

=back

=cut

#############################################
sub getAvatar {
#############################################
   my $param = shift;
   my $DBManager = shift;
   my $UserManager = shift;

   #print STDERR "in Lists::ListManager::getAvatar with param: $param\n";

   my $UserID = ""; 
   my $class = "";
   if($param =~ m/^(\d+)(\D+)/){
      $UserID = $1;
      $class = $2;
   }

   my $UserObj = $DBManager->getTableObj("User");
   my $User = $UserObj->get_by_ID($UserID);
   $UserManager->getUserAvatar($User);

   my %Data;
   $Data{"AvatarDisplay"} = $User->{"AvatarDisplay"};
   $Data{"UserURL"} = $UserManager->getUserURL($User);
   $Data{"Class"} = $class;

   my $template = "$Lists::SETUP::DIR_PATH/widgets/avatar.html";
   open (PAGE, $template) || print "Cannot open file: $template $!";
   my @lines = <PAGE>;

   my $avatar = "";
   foreach my $line(@lines) {
      if($line =~ m/<!--Data\.([\w_]+)-->/){
         my $field = $1;
         if($field =~ m/(\w+)_(\w+)/){
            my $hashName = $1;
            my $hashValue = $2;
            $line =~ s/<!--Data\.$field-->/$Data{$hashName}->{$hashValue}/;
         }else{
            $line =~ s/<!--Data\.$field-->/$Data{$field}/;
         }
      }
      $avatar .= $line;
   }

   return $avatar;
}

1;

=head1 AUTHOR INFORMATION

   Author:  Marilyn Burgess
   Last Updated: 13/05/2009

=head1 BUGS

   Not known

=cut

