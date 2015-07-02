package ListCentral::Utilities::CCImage;
use strict;

use Flickr::API;

use ListCentral::SETUP;
use ListCentral::Utilities::StringFormator;

##########################################################
# ListCentral::CCImage 
##########################################################

=head1 NAME

   ListCentral::Utilities::CCImage.pm

=head1 SYNOPSIS

   $CCImage = new ListCentral::Utilities::CCImage(Debugger);

=head1 DESCRIPTION

Used to communicate with Flickr to get Creative Commons images

http://www.flickr.com/services/api/flickr.photos.search.html

=head2 ListCentral::Utilities::CCImage Constructor

=over 4

=item B<Parameters :>

   1. $Debugger

=itemB<Modes : >


=back

=cut

########################################################
sub new {
########################################################
   my $classname=shift; 
   my $self; 
   %$self=@_; 
   bless $self,ref($classname)||$classname;

   $self->{Debugger}->debug("in ListCentral::Utilities::CCImage constructor");

   #$self->{'FlickrKey'} = '206c3ec5c02a71e4ed8bc418774dc8e4';
   #$self->{'FlickrSecret'} = 'e0a2d8d4c17825ef';

   # Brahmina Burgess account for the List Central app
   $self->{'FlickrKey'} = '0fc723b0de48cfc57be97dbf8e6682dc';
   $self->{'FlickrSecret'} = '18e0f5ecc2475561';

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
sub getCCImageChoices {
#############################################
   my $self = shift;
   my $query = shift;
   my $page = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::CCImage::getTopSearchResults with $query, $page");

   if(! $page){
      $page = 1;
   }

   my @tags = split(" " , $query);
   my $numberOfWords = scalar(@tags);
   $self->{Debugger}->debug("scalar(\@tags): $numberOfWords"); 
   my $tags = $query;
   if($numberOfWords > 1){
      for(my $i = 0; $i < $numberOfWords-1; $i++){
         $tags .= ", $tags[$i] $tags[$i+1]";
      }
   }

   $self->{Debugger}->debug("resulting tags: $tags"); 


   my $api = new Flickr::API({'key' => $self->{"FlickrKey"},
                              'secret' => $self->{"FlickerSecret"}});

   my $response = $api->execute_method('flickr.photos.search', {
                'text ' => $query,
                'license ' => '1, 2, 3, 4, 5, 6, 7', 
                   # TODO -> decide on wether to ge non-comercial ones
                   # Leave because my users are using them, non-commercially?
                'per_page' => $ListCentral::SETUP::CONSTANTS{'CCIMAGE_CHOICE_LIMIT'},
                'page' => $page,
                'media' => 'photos',
                'tag_mode' => 'any',
                'tags' => $tags,
                #'title' => $query,
                #'user_id' => 'urpisdream',
                'content_type' => 1, # photos only
                'extras' => 'owner_name, url_m',
                'sort' => 'relavance' # 'interestingness-desc' #'relavance' 'date-posted-desc' 'relevance' 'interestingness-desc'  'date-taken-asc'
        });

   my $content = $response->decoded_content();
  
   $self->{Debugger}->debug("CCImage:\n$content");

   if(!$content || $content =~ m/^500/){
      return $content;
   }
   
   my %Photos;
   my @lines = split(/\n/, $content);
   foreach my $line(@lines){
      my $lineSave = $line;
      if($line =~ m/<photo/){
         my $ID;
         if($line =~ m/id="(\d+)"/){
            $ID = $1;
            $Photos{$ID}->{ID} = $ID;
         }else{
            next;
         }
         if($line =~ m/url_m="(.+?)"/){
            $Photos{$ID}->{ImageURL} = $1;
         }else{
            delete $Photos{$ID};
            next;
         }
         if($line =~ m/owner="(.+?)"/){
            $Photos{$ID}->{Owner} = $1;
         }
         if(! $Photos{$ID}->{Owner}){
            $Photos{$ID}->{Owner} = "unknown";
         }

         if($line =~ m/ownername="(.*?)"/){
            $Photos{$ID}->{Author} = $1;
         }
         if(! $Photos{$ID}->{Author}){
            $Photos{$ID}->{Author} = $Photos{$ID}->{Owner};
         }
         
         if($line =~ m/title="(.*?)"/){
            $Photos{$ID}->{Title} = $1;
         }

         $Photos{$ID}->{URL} = "http://www.flickr.com/photos/$Photos{$ID}->{Owner}/$ID/";
      }
   }

   my $count = 0;
   my $CCImageChoices = "";
   foreach my $ID(keys %Photos) {
      if($count < $ListCentral::SETUP::CONSTANTS{'CCIMAGE_CHOICE_LIMIT'}){
         $self->{Debugger}->debug("Choice - $ID");

         my %Data = ("CCImageChoice" => $Photos{$ID});
         $CCImageChoices .= $self->getBasicPage("$ListCentral::SETUP::DIR_PATH/Utilities/CCImage/choices_rows.html", \%Data);
         $count++;
      }
   }
   
   return $CCImageChoices;
}

=head2 getImageByID

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
sub getImageByID {
#############################################
   my $self = shift;
   my $ID = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::CCImage::getImageByID with $ID");
  
   if(! $ID){
      return;
   }

   my $api = new Flickr::API({'key' => $self->{"FlickrKey"},
                              'secret' => $self->{"FlickerSecret"}});

   my $response = $api->execute_method('flickr.photos.getInfo', {
                'photo_id' => $ID
        });


   my $content = $response->decoded_content();
   $self->{Debugger}->debug("\nCCImage Content:\n$content\n");

   if(!$content || $content =~ m/^500/ || $content =~ m/Error/){
      return $content;
   }

   my %Photo;
   my @lines = split(/\n/, $content);
   foreach my $line(@lines){

      if($line =~ m/<url type="photopage">(.+)<\/url>/){
         $Photo{Source} = $1;
      }

      if($line =~ m/<owner nsid="([\w@]+?)" username="(.+?)"/){
         $Photo{UserID} = $1;
         $Photo{Credit} = $2;
      }

      if($line =~ m/<photo id="(\d+)" secret="(\w+)" server="(\d+)" farm="(\d+)"/){
         my $photoID = $1;
         my $secret = $2;
         my $server = $3;
         my $farm = $4;
         $Photo{Image} = "http://farm" . $farm . ".static.flickr.com/" . $server . "/" . $photoID . "_" . $secret . ".jpg";
      }
   }
   if($Photo{Image}){
      $Photo{ID} = $ID;
   }   

   return \%Photo;
}

=head2 setCCImage

For the cron script to collect the UK and CA links, may add more in the future

=over 4

=item B<Parameters :>

   1. $self - Reference to a CCImage object

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub setCCImage {
#############################################
   my $self = shift;
   my $FlkrID = shift;
   my $CCImageObj = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::CCImage->setCCImage with FlkrID: $FlkrID");

   my $CCImage = $self->getImageByID($FlkrID);
   if($CCImage =~ m/^500/ || $CCImage =~ m/Error/){
      return $CCImage;
   }
   $self->{Debugger}->debug("CCImage->{'Image'}: " . $CCImage->{'URL'});

   
   my $CCImageFromDB = $CCImageObj->getByFlkrID($FlkrID);

   if(!$CCImageFromDB->{ID}){
      return "";
   }

   my $url = ListCentral::Utilities::StringFormator::htmlDecode($CCImage->{'URL'});

   $CCImageObj->update("Image", $CCImage->{'Image'}, $CCImageFromDB->{ID});
   $CCImageObj->update("Source", $CCImage->{'Source'}, $CCImageFromDB->{ID});
   $CCImageObj->update("Credit", $CCImage->{'Credit'}, $CCImageFromDB->{ID});
   return $CCImage->{'URL'};

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

   $self->{Debugger}->debug("in ListCentral::Utilities::CCImage->getBasicPage with page $page, $Data");

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

1;

=head1 AUTHOR INFORMATION

   Author:  Brahmina
   Last Updated: 2/12/2009

=head1 BUGS

   Not known

=cut
