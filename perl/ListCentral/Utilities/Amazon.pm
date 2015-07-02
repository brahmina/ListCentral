package ListCentral::Utilities::Amazon;
use strict;

use ListCentral::SETUP;
use ListCentral::Utilities::StringFormator;
use ListCentral::Utilities::AmazonRequestSignatureHelper;

##########################################################
# ListCentral::Amazon 
##########################################################

=head1 NAME

   ListCentral::Utilities::Amazon.pm

=head1 SYNOPSIS

   $Amazon = new ListCentral::Utilities::Amazon(Debugger, UserManager, DBManger);

=head1 DESCRIPTION

Used to communicate with Amazon and build affiliate links

=head2 ListCentral::Utilities::Amazon Constructor

=over 4

=item B<Parameters :>

   1. $Debugger

=itemB<Modes : >

   http://search.cpan.org/dist/Net-Amazon/lib/Net/Amazon/Validate/ItemSearch/us/Keywords.pm

    Apparel
    Automotive
    Baby
    Beauty
    Blended
    Books
    Classical
    DVD
    DigitalMusic
    Electronics
    GourmetFood
    HealthPersonalCare
    HomeGarden
    Industrial
    Jewelry
    Kitchen
    Magazines
    Merchants
    Miscellaneous
    Music
    MusicTracks
    MusicalInstruments
    OfficeProducts
    OutdoorLiving
    PCHardware
    PetSupplies
    Photo
    SilverMerchants
    Software
    SportingGoods
    Tools
    Toys
    UnboxVideo
    VHS
    Video
    VideoGames
    Wireless
    WirelessAccessories

Hash comes out like:
ASIN
DetailPageURL
SalesRank - OrderBy
ItemAttributes
    Artist
    Binding (CD, Cassette)
    Publisher
    Title

=back

=cut

########################################################
sub new {
########################################################
   my $classname=shift; 
   my $self; 
   %$self=@_; 
   bless $self,ref($classname)||$classname;

   $self->{Debugger}->debug("in ListCentral::Utilities::Amazon constructor");

   if(! $self->{"AmazonToken"}){ 
      $self->{"AmazonToken"} = $ListCentral::SETUP::AMAZON_TOKEN;
   }
   if(! $self->{"AmazonSecret"}){
      $self->{"AmazonSecret"} = $ListCentral::SETUP::AMAZON_SECRET;
   }
   #roa2now-20
   if(! $self->{"AmazonUserName"}){ 
      $self->{"AmazonUserName"} = $ListCentral::SETUP::AMAZON_ASSOCIATE_TAG;
   }

   return ($self); 
}


=head2 getTopSearchResults

Sends email to the email address passed with the body and subject line passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object
   2. $query - the email address to send the email to
   3. $mode - the subject of the email to be sent

=item B<Returns :>

   1. $results

=back

=cut

#############################################
sub getTopSearchResults {
#############################################
   my $self = shift;
   my $query = shift;
   my $mode = shift;
   my $page = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::Amazon::getTopSearchResults with $query, $mode, $page");

   # Help improve search returns
   if($query =~ m/\sby\s/){
      $query =~ s/\sby\s/ /;
   }

   my $endpoint = $ListCentral::SETUP::AMAZON_REQUESTS{'ENDPOINT'}{'US'};
   if(! $page == 1 || ($mode ne "Books" || $mode ne "Music" || $mode ne "DVD" || $mode ne "VideoGames")){
      $endpoint = $self->getEndPoint();
   }
   my $url = $self->getAmazonRequestURL($query, $mode, $endpoint, $page);

   my ($results, $error) = $self->sendAmazonRequest($url, $query);

   if($error){
      $results = "Error with Amazon query: $error";
   }
  
   #foreach my $asin (keys %{$results}) {
   #   $self->{Debugger}->debug("In getTopSearchResults: $asin -> SortOrder: $results->{$asin}->{SortOrder}");
   #}

   return $results;
}


=head2 getItemByASIN

Sends email to the email address passed with the body and subject line passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object
   2. $query - the email address to send the email to
   3. $mode - the subject of the email to be sent

=item B<Returns :>

   1. $results

=back

=cut

#############################################
sub getItemByASIN {
#############################################
   my $self = shift;
   my $ASIN = shift;
   my $endpoint = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::Amazon::getItemByASIN with $ASIN");

   if(! $endpoint){
      $endpoint = $self->getEndPoint();
   }

   if(! $ASIN){
      return;
   }
   my $url = $self->getAmazonRequestURL($ASIN, "ASIN", $endpoint);

   my ($results, $error) = $self->sendAmazonRequest($url);

   my $ASIN;
   my %AmazonResult;
   foreach $ASIN(keys %{$results}) {
      foreach my $field(keys %{$results->{$ASIN}}) {
         $AmazonResult{$field} = $results->{$ASIN}->{$field};
         $self->{Debugger}->debug("Amazon: $ASIN -> $field - $results->{$ASIN}->{$field}");
      }
      $AmazonResult{"ASIN"} = $ASIN;
   }

   if($error){
      $results = "Error with Amazon query: $error";
   }
  
   $self->{Debugger}->debug("Amazon Response: $results Amazon Error: $error");

   return \%AmazonResult;
}


=head2 getAmazonChoices

Gets choices from Amazon, and asks user to pick one

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $List

=item B<Returns :>

   1. $html - The html of the list choices

=back

=cut

#############################################
sub getAmazonChoices {
#############################################
   my $self = shift;
   my $List = shift;
   my $page = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::Amazon->getAmazonChoices");

   my $mode;
   if($self->{cgi}->{'AmazonMode'}){
      $mode = $self->{cgi}->{'AmazonMode'};
   }else{
      if($List->{Name} =~ m/book/i || $List->{Name} =~ m/novel/i || $List->{Name} =~ m/fiction/i || 
         $List->{Name} =~ m/read/i){
         $mode = "Books";
      }elsif($List->{Name} =~ m/music/i || $List->{Name} =~ m/song/i || $List->{Name} =~ m/track/i || 
             $List->{Name} =~ m/record/i || $List->{Name} =~ m/album/i || $List->{Name} =~ m/disk/i ||
             $List->{Name} =~ m/cd/i || $List->{Name} =~ m/tune/i){
         $mode = "Music";
      }elsif($List->{Name} =~ m/mp3/i){
         $mode = "DigitalMusic";
      }elsif($List->{Name} =~ m/movie/i || $List->{Name} =~ m/film/i || $List->{Name} =~ m/dvd/i || $List->{Name} =~ m/tv/i || 
             $List->{Name} =~ m/documentary/i || $List->{Name} =~ m/actor/i || $List->{Name} =~ m/director/i){
         $mode = "DVD";
      }elsif($List->{Name} =~ m/game/i || $List->{Name} =~ m/vids/i){
         $mode = "VideoGames";
      }else{
         $mode = "Blended";
      }
   }

   $self->{cgi}->{'mode'} = $mode;
   my $Choices = $self->getTopSearchResults($self->{cgi}->{"ListItem.NameDecoded"}, $mode, $page);

   #foreach my $asin(keys %{$Choices}) {
   #   $self->{Debugger}->debug("In getAmazonChoices: $asin -> SortOrder: $Choices->{$asin}->{SortOrder}");
   #}

   if($Choices =~ m/^Error with Amazon/){
      return $Choices;
   }elsif(scalar(keys %{$Choices} == 0)){
      return "";
   }

   my $count = 0;
   my $AmazonChoices = "";
   foreach my $ASIN(sort{$Choices->{$a}->{SortOrder} <=> $Choices->{$b}->{SortOrder}} keys %{$Choices}) {
      if($count < $ListCentral::SETUP::CONSTANTS{'AMAZON_CHOICE_LIMIT'}){
         $self->{Debugger}->debugNow("Choice - $ASIN, SortOrder: $Choices->{$ASIN}->{SortOrder}");
         $Choices->{$ASIN}->{ASIN} = $ASIN;
         my %Data = ("AmazonChoice" => $Choices->{$ASIN});
         $AmazonChoices .= $self->getBasicPage("$ListCentral::SETUP::DIR_PATH/Utilities/Amazon/choices_rows.html", \%Data);
         $count++;
      }
   }

   return $AmazonChoices;
}



=head2 getAmazonRequestURL

Builds and returns the Amazon Request URL

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $List

=item B<Returns :>

   1. $html - The html of the list choices

=back

=cut

#############################################
sub getAmazonRequestURL {
#############################################
   my $self = shift;
   my $query = shift;
   my $mode = shift;
   my $endpoint = shift;

   $self->{Debugger}->debug("in getAmazonRequestURL with $query, $mode, $endpoint");

   my $AssociatesTag = $ListCentral::SETUP::AMAZON_REQUESTS{'ASSOCIATE_TAG'}{'US'};
   if($endpoint =~ m/\.ca$/){
      $AssociatesTag = $ListCentral::SETUP::AMAZON_REQUESTS{'ASSOCIATE_TAG'}{'CA'};
   }elsif($endpoint =~ m/\.co\.uk$/){
      $AssociatesTag = $ListCentral::SETUP::AMAZON_REQUESTS{'ASSOCIATE_TAG'}{'UK'};
   }

   my $request;
   if($mode eq "ASIN"){
      $request = {
          Service => 'AWSECommerceService',
          Operation => 'ItemLookup',
          Version => '2009-03-31',
          ItemId => $query,
          IdType => "ASIN",
          ResponseGroup => 'Small,Images',
          AssociateTag => $AssociatesTag
      };
   }else{
      my $page = shift;
      if($mode != "Blended"){
         $request = {
             Service => 'AWSECommerceService',
             Operation => 'ItemSearch',
             Version => '2009-03-31',
             ResponseGroup => 'Small,Images',
             SearchIndex => $mode,
             Title => $query,
             ItemPage => $page,
             AssociateTag => $AssociatesTag
         };
      }else{
         $request = {
             Service => 'AWSECommerceService',
             Operation => 'ItemSearch',
             Version => '2009-03-31',
             ResponseGroup => 'Small,Images',
             SearchIndex => $mode,
             Keywords => $query,
             ItemPage => $page,
             AssociateTag => $AssociatesTag
         };
      }      
   }

   my $helper = new ListCentral::Utilities::AmazonRequestSignatureHelper (
       AWSAccessKeyId => $self->{"AmazonToken"},
       AWSSecretKey => $self->{"AmazonSecret"},
       EndPoint => $endpoint
   );

   my $signedRequest = $helper->sign($request);

   # We can use the helper's canonicalize() function to construct the query string too.
   my $queryString = $helper->canonicalize($signedRequest);
   my $url = "http://" . $endpoint . "/onca/xml?" . $queryString;

   return $url;
}

=head2 sendAmazonRequest

Builds and returns the Amazon Request URL

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $List

=item B<Returns :>

   1. $html - The html of the list choices

=back

=cut

#############################################
sub sendAmazonRequest {
#############################################
   my $self = shift;
   my $url = shift;
   my $query = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::Amazon::sendAmazonRequest with $url");

   use XML::Simple;
   use LWP::UserAgent;

   my $ua = new LWP::UserAgent();
   $ua->timeout( $ListCentral::SETUP::CONSTANTS{'LWP_TIMEOUT'} );
   my $response = $ua->get($url);
   my $content = $response->content();
   #$self->{Debugger}->debug("Error: " .$response->{Error} . "\nReturned content: $content");

   if($response->{Error} || !$content || $content =~ m/^500/){
      return 0, $content . $response->{Error};
   }
   
   my $xmlsimple = XML::Simple->new();
   my $response = $xmlsimple->XMLin($content);
   
   my %Items;
   if(ref($response->{Items}->{Item}) eq "ARRAY"){
      foreach my $item_hash_ref (@{$response->{Items}->{Item}}) {
          $self->readAmazonItemResponse($item_hash_ref, \%Items);
      }
   }else{
      $self->readAmazonItemResponse($response->{Items}->{Item}, \%Items);
   }


   # Sort according to image and relavance
   my $SortOrder = 1;
   foreach my $asin(keys %Items) {

      $Items{$asin}->{Title} =~ s/&/&amp;/g;
      if($Items{$asin}{"Title"} =~ m/$query/ && ($Items{$asin}{"LargeImage"} && $Items{$asin}{"LargeImage"} !~ m/no_amazon_image/)){
         $self->{Debugger}->debug("SortOrder - Title matches query $SortOrder");
         $Items{$asin}->{SortOrder} = $SortOrder;
         $SortOrder++;
      }  
   }
   foreach my $asin(keys %Items) {
      if(($Items{$asin}{"LargeImage"} && $Items{$asin}{"LargeImage"} !~ m/no_amazon_image/) && !$Items{$asin}->{SortOrder}){
         $self->{Debugger}->debug("SortOrder - Medium image $SortOrder");
         $Items{$asin}->{SortOrder} = $SortOrder;
         $SortOrder++;
      }
   }
   foreach my $asin(keys %Items) {
      if($Items{$asin}{"Title"} =~ m/$query/ && !$Items{$asin}->{SortOrder}){
         $self->{Debugger}->debug("SortOrder - Title matches query $SortOrder");
         $Items{$asin}->{SortOrder} = $SortOrder;
         $SortOrder++;
      }  
   }   
   foreach my $asin(keys %Items) {
      if( !$Items{$asin}->{SortOrder}){
         $self->{Debugger}->debug("SortOrder - Plain $SortOrder");
         $Items{$asin}->{SortOrder} = $SortOrder;
         $SortOrder++;
      }
   }

   #foreach my $asin(keys %Items) {
   #   $self->{Debugger}->debug("in sendAmazonRequest $asin -> SortOrder: $Items{$asin}{SortOrder}");
   #}
   
   my $error = $response->{Error};

   return (\%Items, $error);
}

=head2 readAmazonItemResponse

Given a hash with data from Amazone XML

=over 4

=item B<Parameters :>

   1. $self - Reference to a Amazon object
   2. $item_hash_ref - the page to print
   3. $DestinationItems - Reference to a hash where the data should go

=back

=cut

#############################################
sub readAmazonItemResponse {
#############################################
   my $self = shift;
   my $item_hash_ref = shift;
   my $Items = shift;

   if(!$item_hash_ref->{ASIN}){
      return;
   }

   $Items->{$item_hash_ref->{ASIN}}->{URL} = $item_hash_ref->{DetailPageURL};
   $Items->{$item_hash_ref->{ASIN}}->{SmallImage} = $item_hash_ref->{SmallImage}->{URL};
   if( !$Items->{$item_hash_ref->{ASIN}}->{SmallImage}){
      $Items->{$item_hash_ref->{ASIN}}->{SmallImage} = "/images/no_amazon_image.png";
   }
   $Items->{$item_hash_ref->{ASIN}}->{MediumImage} = $item_hash_ref->{MediumImage}->{URL};
   if( !$Items->{$item_hash_ref->{ASIN}}->{MediumImage}){
      $Items->{$item_hash_ref->{ASIN}}->{MediumImage} = "/images/no_amazon_image.png";
   }
   $Items->{$item_hash_ref->{ASIN}}->{LargeImage} = $item_hash_ref->{LargeImage}->{URL};
   if( !$Items->{$item_hash_ref->{ASIN}}->{LargeImage}){
      $Items->{$item_hash_ref->{ASIN}}->{LargeImage} = "/images/no_amazon_image.png";
   }
   
   $Items->{$item_hash_ref->{ASIN}}->{Title} = $item_hash_ref->{ItemAttributes}->{Title};
   $Items->{$item_hash_ref->{ASIN}}->{ProductGroup} = $item_hash_ref->{ItemAttributes}->{ProductGroup};
   
   if($item_hash_ref->{ItemAttributes}->{Artist}){
      $Items->{$item_hash_ref->{ASIN}}->{Creator} = $item_hash_ref->{ItemAttributes}->{Artist};
   }elsif($item_hash_ref->{ItemAttributes}->{Author}){
      $Items->{$item_hash_ref->{ASIN}}->{Creator} = $item_hash_ref->{ItemAttributes}->{Author};
   }elsif($item_hash_ref->{ItemAttributes}->{Manufacturer}){
      $Items->{$item_hash_ref->{ASIN}}->{Creator} = $item_hash_ref->{ItemAttributes}->{Manufacturer};
   }elsif($item_hash_ref->{ItemAttributes}->{Brand}){
      $Items->{$item_hash_ref->{ASIN}}->{Creator} = $item_hash_ref->{ItemAttributes}->{Brand};
   }elsif($item_hash_ref->{ItemAttributes}->{Director}){
      $Items->{$item_hash_ref->{ASIN}}->{Creator} = $item_hash_ref->{ItemAttributes}->{Brand};
   }else{
      $Items->{$item_hash_ref->{ASIN}}->{Creator} = "Unknown";
   }

   if(ref($Items->{$item_hash_ref->{ASIN}}->{Creator}) eq "ARRAY"){
      my $Creator = $Items->{$item_hash_ref->{ASIN}}->{Creator}->[0];
      $Items->{$item_hash_ref->{ASIN}}->{Creator} = $Creator;
   }
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

   #$self->{Debugger}->debug("in ListCentral::ListsManager->getTableRows with page $page, $Data");

   if($self->{UserManager}->{ThisUser}->{ID}){
      $page =~ s/$ListCentral::SETUP::DIR_PATH\///;
      if(-e "$ListCentral::SETUP::DIR_PATH/loggedin/$page"){      
         $page = "$ListCentral::SETUP::DIR_PATH/loggedin/$page";
      }else{
         $page = "$ListCentral::SETUP::DIR_PATH/$page";
      }   
   }

   # File Cache
   my @lines;
   if($self->{BasicFileCache}->{$page}){
      @lines = @{$self->{BasicFileCache}->{$page}};
   }else{     
      my $template = $page;
      if(! open (PAGE, $template)){
         my $error = "Cannot write file: $template $!";
         $self->{Debugger}->log($error);
         $self->{ErrorMessages} = $error;
         return $self->getPage("$ListCentral::SETUP::DIR_PATH/error.html");
      }
      @lines = <PAGE>;
      close PAGE;

      my @linesSave = @lines;
      $self->{BasicFileCache}->{$page} = \@linesSave;
   }


   my $content = "";
   foreach my $line (@lines) {
      if($line =~ m/<!--(.+)-->/){
         #$self->{Debugger}->debug("getPage tag: $1");
         if($line =~ m/<!--URL-->/){
            my $url = "http://$ENV{HTTP_HOST}";
            $line =~ s/<!--URL-->/$url/;
         }elsif($line =~ m/<!--SETUP\.([\w_]+)-->/){
            my $variable = $1;
            $line =~ s/<!--SETUP\.$variable-->/$ListCentral::SETUP::CONSTANTS{$variable}/;
         }elsif($line =~ m/<!--Self\.([\w\.]+)-->/g){
            my $variable = $1;
            if($variable =~ m/ErrorMessages/ && $self->{$variable}){
               $self->{$variable} = "<p class=\"error\">$self->{$variable}</p>";
            }
            $line =~ s/<!--Self\.$variable-->/$self->{$variable}/g;
         }elsif($line =~ m/<!--CGI\.([\w\.]+)-->/){
            my $field = $1;
            my $value = $self->{cgi}->{$field};
            $line =~ s/<!--CGI\.$field-->/$value/;
         }elsif($line =~ m/<!--ErrorMessages-->/){
            if($self->{ErrorMessages}){
               $self->{ErrorMessages} = "<p class=\"error\">$self->{ErrorMessages}</p>";
            }
            $line =~ s/<!--ErrorMessages-->/$self->{ErrorMessages}/;
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

=head2 runGeoLinkCheck

For the cron script to collect the UK and CA links, may add more in the future

=over 4

=item B<Parameters :>

   1. $self - Reference to a Amazon object

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub runGeoCheck {
#############################################
   my $self = shift;
   my $runAll = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::Amazon->runGeoLinkCheck");

   my $AmazonLinksObj = $self->{DBManager}->getTableObj("AmazonLinks");

   # Get all of AmazonLinks
   my $AmazonLinks = $AmazonLinksObj->get_all();

   foreach my $ID (keys %{$AmazonLinks}) {
      if($AmazonLinks->{$ID}->{ID}){
         if($AmazonLinks->{$ID}->{ChecksRun} < 5 || $runAll == 1){
            if(! $AmazonLinks->{$ID}->{US}){
               $self->setAmazonLink($AmazonLinks->{$ID}->{ASIN}, $AmazonLinksObj, 'US');
            }
            if(! $AmazonLinks->{$ID}->{CA}){
               $self->setAmazonLink($AmazonLinks->{$ID}->{ASIN}, $AmazonLinksObj, 'CA');
            }
            if(! $AmazonLinks->{$ID}->{UK}){
               $self->setAmazonLink($AmazonLinks->{$ID}->{ASIN}, $AmazonLinksObj, 'UK');
            }

            my $checksRun = $AmazonLinks->{$ID}->{ChecksRun} + 1;
            if(! $AmazonLinks->{$ID}->{ChecksRun}){
               $checksRun = 1;
            }

            $AmazonLinksObj->update("ChecksRun", $checksRun, $ID);
         }
      }
   }
}

=head2 getAmazonLink

For the cron script to collect the UK and CA links, may add more in the future

=over 4

=item B<Parameters :>

   1. $self - Reference to a Amazon object

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub getAmazonLink {
#############################################
   my $self = shift;
   my $AmazonLinkID = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::Amazon->getAmazonLink with LinkID: $AmazonLinkID");

   my $country = $self->getCountryByRemoteIP();

   $self->{Debugger}->debug("my country by ip: $country");

   my $AmazonLinksObj = $self->{DBManager}->getTableObj("AmazonLinks");
   my $AmazonLinks = $AmazonLinksObj->get_by_ID($AmazonLinkID);

   foreach my $k (keys %{$AmazonLinks}) {
      $self->{Debugger}->debug("$k --> $AmazonLinks->{$k}");
   }

   my $link = "";
   if($country eq "CA"){
      $link = $AmazonLinks->{CA};
   }elsif($country eq "UK"){
      $link = $AmazonLinks->{UK};
   }else{
      $link = $AmazonLinks->{US};
   }

   if($link eq ""){
      if($AmazonLinks->{US} ne ""){
         $link = $AmazonLinks->{US};
      }elsif($AmazonLinks->{CA} ne ""){
         $link = $AmazonLinks->{CA};
      }elsif($AmazonLinks->{UK} ne ""){
         $link = $AmazonLinks->{UK};
      }
   }

   $self->{Debugger}->debug("end of getAmazonLink wiith link: $link, country: $country");

   return $link;

}

=head2 getAmazonImage

Returns the amazon image src

=over 4

=item B<Parameters :>

   1. $self - Reference to a Amazon object

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub getAmazonImage {
#############################################
   my $self = shift;
   my $AmazonLinkID = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::Amazon->getAmazonImage with AmazonLinkID: $AmazonLinkID");

   my $country = $self->getCountryByRemoteIP();

   $self->{Debugger}->debug("my country by ip: $country");

   my $AmazonLinksObj = $self->{DBManager}->getTableObj("AmazonLinks");
   my $AmazonLinks = $AmazonLinksObj->get_by_ID($AmazonLinkID);

   my $Image = "";
   if($country eq "CA"){
      $Image = $AmazonLinks->{CAImage};
   }elsif($country eq "UK"){
      $Image = $AmazonLinks->{UKImage};
   }else{
      $Image = $AmazonLinks->{USImage};
   }

   if($Image eq ""){
      if($AmazonLinks->{USImage} ne ""){
         $Image = $AmazonLinks->{USImage};
      }elsif($AmazonLinks->{CAImage} ne ""){
         $Image = $AmazonLinks->{CAImage};
      }elsif($AmazonLinks->{UKImage} ne ""){
         $Image = $AmazonLinks->{UKImage};
      }
   }

   $self->{Debugger}->debug("end of getAmazonLink wiith link: $Image, country: $country");

   return $Image;

}

=head2 setAmazonLink

For the cron script to collect the UK and CA links, may add more in the future

=over 4

=item B<Parameters :>

   1. $self - Reference to a Amazon object

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub setAmazonLink {
#############################################
   my $self = shift;
   my $ASIN = shift;
   my $AmazonLinksObj = shift;
   my $Country = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::Amazon->setAmazonLink with ASIN: $ASIN, Country: $Country");

   my $AmazonItem = $self->getItemByASIN($ASIN, $ListCentral::SETUP::AMAZON_REQUESTS{'ENDPOINT'}{$Country});
   $self->{Debugger}->debug("AmazonItem->{'URL'}: " . $AmazonItem->{'URL'});

   my $AmazonLinksID;
   my $AmazonLinks = $AmazonLinksObj->get_with_restraints("ASIN = \"$ASIN\"");
   foreach (keys %{$AmazonLinks}) {
      # There should be only one
      $AmazonLinksID = $AmazonLinks->{$_}->{ID};
   }

   my $url = ListCentral::Utilities::StringFormator::htmlDecode($AmazonItem->{'URL'});
   my $imageurl = ListCentral::Utilities::StringFormator::htmlDecode($AmazonItem->{'LargeImage'});

   $AmazonLinksObj->update($Country, $url, $AmazonLinksID);
   $AmazonLinksObj->update($Country ."Image", $imageurl, $AmazonLinksID);

   return $AmazonItem->{'URL'};

}

=head2 getEndPoint

For the cron script to collect the UK and CA links, may add more in the future

=over 4

=item B<Parameters :>

   1. $self - Reference to a Amazon object

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub getEndPoint {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::Amazon->getEndPoint : " . $ListCentral::SETUP::AMAZON_REQUESTS{'ENDPOINT'}{'US'});

   my $country = $self->getCountryByRemoteIP();

   my $endpoint = $ListCentral::SETUP::AMAZON_REQUESTS{'ENDPOINT'}{$country};
   if(! $endpoint){
      $endpoint = $ListCentral::SETUP::AMAZON_REQUESTS{'ENDPOINT'}{'US'};
   }
   return $endpoint;
}

=head2 getEndPoint

For the cron script to collect the UK and CA links, may add more in the future

=over 4

=item B<Parameters :>

   1. $self - Reference to a Amazon object

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub getCountryByRemoteIP {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::Amazon->getCountryByRemoteIP $ENV{'REMOTE_ADDR'}");

   # Pick country from user's profile first
   $self->{'CountryByIP'} = $self->{UserManager}->getUsersAmazonCountry();

   # If no match from profile, use the IP
   if(! $self->{'CountryByIP'}){
      use Geo::IP;
      my $gi = Geo::IP->new(GEOIP_STANDARD);
      $self->{'CountryByIP'} = $gi->country_code_by_addr($ENV{'REMOTE_ADDR'});
   }

   if(! $self->{'CountryByIP'}){
      $self->{'CountryByIP'} = "US";
   }

   return $self->{'CountryByIP'};
}

=head2 saveAmazonLink

Saves a new AmazonLink

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub saveAmazonLink {
#############################################
   my $self = shift;
   my $cgi = shift;

   my $AmazonLinksObj = $self->{DBManager}->getTableObj("AmazonLinks");
   my $AmazonID;
   my $AmazonLinkCurrent = $AmazonLinksObj->getByASIN($cgi->{"ListItem.ASIN"});
   if($AmazonLinkCurrent->{ID}){
      $AmazonID = $AmazonLinkCurrent->{ID};
   }else{
      my %AmazonLinks = ();
      $AmazonLinks{"AmazonLinks.Status"} = 1;
      $AmazonLinks{"AmazonLinks.ASIN"} = $cgi->{"ListItem.ASIN"};
   
      $AmazonID = $AmazonLinksObj->store(\%AmazonLinks);
   
      my $country = $self->getCountryByRemoteIP();
      $self->setAmazonLink($AmazonLinks{"AmazonLinks.ASIN"}, $AmazonLinksObj, $country);
   }
   return $AmazonID;
}

=head2 getAmzonLinkAndImage

Returns the Amazon Link and image

=over 4

=item B<Parameters :>

   1. $self - Reference to a Amazon
   2. $AmazonID - The ID of the Amazon Link to ge tthe links and image for

=item B<Returns :>

   1. $link
   2. $imgsrc

=back

=cut

#############################################
sub getAmazonLinkAndImage {
#############################################
   my $self = shift;
   my $AmazonID = shift;

   my $AmazonLinksObj = $self->{DBManager}->getTableObj("AmazonLinks");
   my $AmazonLinks = $AmazonLinksObj->get_by_ID($AmazonID);
   my $country = $self->getCountryByRemoteIP();
   my $imgsrc = $AmazonLinks->{$country . "Image"};
   my $link = $AmazonLinks->{$country};
   
   
   if($link eq ""){
      my @Countries = ("US", "CA", "UK");
      foreach my $c(@Countries) {
         if($link eq ""){
            $link = $AmazonLinks->{$c};
            $imgsrc = $AmazonLinks->{$c . "Image"};
         }
      }
   }

   return ($link, $imgsrc);
}

1;

=head1 AUTHOR INFORMATION

   Author:  With help from the ApplicationFramework
   Last Updated: 22/10/2007

=head1 BUGS

   Not known

=cut
