package Lists::Utilities::ImageResizer;
use strict;

use Lists::SETUP;
use Image::Magick;
use Image::Size;

##########################################################
# Lists::ImageResizer 
##########################################################

=head1 NAME

   Lists::Utilities::ImageResizer.pm

=head1 SYNOPSIS

   $ImageResizer = new Lists::Utilities::ImageResizer(Debugger);

=head1 DESCRIPTION

Used to place google analytic tracting information on the site pages

=head2 Lists::Utilities::ImageResizer Constructor

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

   $self->{Debugger}->debug("in Lists::Utilities::ImageResizer constructor");
   
   return ($self); 
}

=head2 resizeImage

Given an image creates the properly sized images for List Central and puts them in 
the user's dir passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Utilities::ImageResizer object
   2. $Image - Path to the temporary image 

=item B<Returns :>

   1. $Error - Empty string if all went well

=back

=cut

#############################################
sub resizeImage {
#############################################
   my $self = shift;
   my $OriginalImage = shift;

   $self->{Debugger}->debug("in Lists::Utilities::ImageResizer::resizeImage with $OriginalImage");

   # Check if the image is large enough to need resizing
   my ($width, $height) = imgsize($OriginalImage);

   my $extension; my $dir; my $imageID;
   if($OriginalImage =~ m/(.+)\/(\d+)\.(\w+)$/){
      $dir = $1 . "/";
      $imageID = $2;
      $extension = $3;
   }else{
      $self->{Debugger}->debug("ERROR:: resizeImage Image does follow expected pattern");
      return;
   }

   if($width > $Lists::SETUP::MAX_IMAGE_WIDTH_LARGE || $height > $Lists::SETUP::MAX_IMAGE_WIDTH_LARGE){
      my $ImageMagick = Image::Magick->new;
      my $Error = $ImageMagick->Read($OriginalImage);
   
      $self->{Debugger}->debug("read image: $Error");
   
      if($Error){
         return "Error in Image Resize: $Error";
      }

      my $LargeGeo = $Lists::SETUP::MAX_IMAGE_WIDTH_LARGE . "x" . $Lists::SETUP::MAX_IMAGE_WIDTH_LARGE;
      $Error = $ImageMagick->AdaptiveResize(geometry=>$LargeGeo, blur => 0.3);
      if($Error){
         return "Error in Image Resize: $Error";
      }     
      my $largeImage = $dir . $imageID . "L." . $extension;

      if($extension =~ m/jpeg/i || $extension =~ m/jpg/i){
         $Error = $ImageMagick->Set(compression => 'JPEG', quality=>$Lists::SETUP::IMAGE_QUALITY);
      }else{
         $Error = $ImageMagick->Set(quality=>$Lists::SETUP::IMAGE_QUALITY);
      }
      $ImageMagick->Write($largeImage);
      $self->{Debugger}->debug("Should have written image: $largeImage");
   }else{
      my $largeImage = $dir . $imageID . "L." . $extension;
      my $command = "cp $OriginalImage $largeImage";
      my $output = `$command`;
      $self->{Debugger}->debug("Command: $command - $output");
   }
   if($width > $Lists::SETUP::MAX_IMAGE_WIDTH_MEDIUM || $height > $Lists::SETUP::MAX_IMAGE_WIDTH_MEDIUM){
      my $ImageMagick = Image::Magick->new;
      my $Error = $ImageMagick->Read($OriginalImage);
   
      if($Error){
         return "Error in Image Resize: $Error";
      }

      my $MediumGeo = $Lists::SETUP::MAX_IMAGE_WIDTH_MEDIUM . "x" . $Lists::SETUP::MAX_IMAGE_WIDTH_MEDIUM;
      $Error = $ImageMagick->AdaptiveResize(geometry=>$MediumGeo, blur => 0);
      if($Error){
         return "Error in Image Resize: $Error";
      }     
      my $mediumImage = $dir . $imageID . "M." . $extension;
      
      if($extension =~ m/jpeg/i || $extension =~ m/jpg/i){
         $Error = $ImageMagick->Set(compression => 'JPEG', quality=>$Lists::SETUP::IMAGE_QUALITY);
      }else{
         $Error = $ImageMagick->Set(quality=>$Lists::SETUP::IMAGE_QUALITY);
      }
      $ImageMagick->Write($mediumImage);
      $self->{Debugger}->debug("Should have written image: $mediumImage");
   }else{
      my $mediumImage = $dir . $imageID . "M." . $extension;
      my $command = "cp $OriginalImage $mediumImage";
      my $output = `$command`;
      $self->{Debugger}->debug("Command: $command - $output");
   }
   if($width > $Lists::SETUP::MAX_IMAGE_WIDTH_SMALL || $height > $Lists::SETUP::MAX_IMAGE_WIDTH_SMALL){
      my $ImageMagick = Image::Magick->new;
      my $Error = $ImageMagick->Read($OriginalImage);
   
      $self->{Debugger}->debug("read image: $Error");
   
      if($Error){
         return "Error in Image Resize: $Error";
      }

      my $SmallGeo = $Lists::SETUP::MAX_IMAGE_WIDTH_SMALL . "x" . $Lists::SETUP::MAX_IMAGE_WIDTH_SMALL;
      $Error = $ImageMagick->AdaptiveResize(geometry=>$SmallGeo, blur => 0);
      if($Error){
         return "Error in Image Resize: $Error";
      }     
      my $smallImage = $dir . $imageID . "S." . $extension;

      if($extension =~ m/jpeg/i || $extension =~ m/jpg/i){
         $Error = $ImageMagick->Set(compression => 'JPEG', quality=>$Lists::SETUP::IMAGE_QUALITY);
      }else{
         $Error = $ImageMagick->Set(quality=>$Lists::SETUP::IMAGE_QUALITY);
      }
      $ImageMagick->Write($smallImage);
      $self->{Debugger}->debug("Should have written image: $smallImage");
   }else{
      my $smallImage = $dir . $imageID . "L." . $extension;
      my $command = "cp $OriginalImage $smallImage";
      my $output = `$command`;
      $self->{Debugger}->debug("Command: $command - $output");
   }

   if($Lists::SETUP::DELETE_ORIGINAL_IMAGE){
      my $command = "rm $OriginalImage";
      my $output = `$command`;
      $self->{Debugger}->debug("Command: $command - $output");
   }
}

=head2 resizeAvatar

Given an image creates the properly sized image for the Avatar, cropped too!

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Utilities::ImageResizer object
   2. $Image - Path to the temporary image 

=item B<Returns :>

   1. $Error - Empty string if all went well

=back

=cut

#############################################
sub resizeAvatar {
#############################################
   my $self = shift;
   my $OriginalImage = shift;

   $self->{Debugger}->debug("in Lists::Utilities::ImageResizer::resizeAvatar with $OriginalImage");

   # Check if the image is large enough to need resizing
   my ($width, $height) = imgsize($OriginalImage);

   my $extension; my $dir; my $imageID;
   if($OriginalImage =~ m/(.+)\/(\d+)\.(\w+)$/){
      $dir = $1 . "/";
      $imageID = $2;
      $extension = $3;
   }else{
      $self->{Debugger}->debug("ERROR:: resizeImage Image does follow expected pattern");
      return;
   }

   $self->{Debugger}->debug("Image width: $width, height: $height");

   if($width > $Lists::SETUP::MAX_AVATAR_WIDTH || $height > $Lists::SETUP::MAX_AVATAR_WIDTH){
      $self->{Debugger}->debug("in if");
      my $ImageMagick = Image::Magick->new;
      my $Error = $ImageMagick->Read($OriginalImage);   
      $self->{Debugger}->debug("Read image: $Error");   
      if($Error){
         return "Error in Image Resize: $Error";
      }

      if($width >= $height){
         $self->{Debugger}->debug("width > height");
         # resize so that height is 100
         my $targetWidth = int($width * $Lists::SETUP::MAX_AVATAR_WIDTH / $height);
         my $AvatarGeo = $targetWidth . "x" . $Lists::SETUP::MAX_AVATAR_WIDTH;
         $self->{Debugger}->debug("AvatarGeo: $AvatarGeo");
         $Error = $ImageMagick->AdaptiveResize(geometry=>$AvatarGeo, blur => 0);
         $self->{Debugger}->debug("Resize image: $Error");
         if($Error){
            return "Error in Image Resize: $Error";
         } 

         # crop width evenly on either side
         $ImageMagick->Set(Gravity=>'Center');
         my $geo = $Lists::SETUP::MAX_AVATAR_WIDTH . "x" . $Lists::SETUP::MAX_AVATAR_WIDTH;;
         $Error = $ImageMagick->Crop("$geo");
         $self->{Debugger}->debug("Geo: $geo -> Crop image: $Error");
      }else{
         $self->{Debugger}->debug("height > width");
         # resize so that width is 100
         my $targetHeight = int($height * $Lists::SETUP::MAX_AVATAR_WIDTH / $width);
         my $AvatarGeo = $Lists::SETUP::MAX_AVATAR_WIDTH . "x" . $targetHeight;
         $self->{Debugger}->debug("AvatarGeo: $AvatarGeo");
         $Error = $ImageMagick->AdaptiveResize(geometry=>$AvatarGeo, blur => 0);
         $self->{Debugger}->debug("Resize image: $Error");
         if($Error){
            return "Error in Image Resize: $Error";
         } 

         # crop height evenly on either side
         $ImageMagick->Set(Gravity=>'Center');
         my $geo = $Lists::SETUP::MAX_AVATAR_WIDTH . "x" . $Lists::SETUP::MAX_AVATAR_WIDTH;
         $Error = $ImageMagick->Crop($geo);
         $self->{Debugger}->debug("Geo: $geo -> Crop image: $Error");
      }

          
      my $AvatarImage = $dir . $imageID . "A." . $extension;

      if($extension =~ m/jpeg/i || $extension =~ m/jpg/i){
         $Error = $ImageMagick->Set(compression => 'JPEG', quality=>$Lists::SETUP::IMAGE_QUALITY);
      }else{
         $Error = $ImageMagick->Set(quality=>$Lists::SETUP::IMAGE_QUALITY);
      }
      $self->{Debugger}->debug("Set image: $Error");
      $Error = $ImageMagick->Write($AvatarImage);
      $self->{Debugger}->debug("Write image: $Error");
      $self->{Debugger}->debug("!!! Should have written image: $AvatarImage");
   }else{
      $self->{Debugger}->debug("in else");
      my $AvatarImage = $dir . $imageID . "A." . $extension;
      my $command = "cp $OriginalImage $AvatarImage";
      my $output = `$command`;
      $self->{Debugger}->debug("Command: $command - $output");
   }
  
   if($Lists::SETUP::DELETE_ORIGINAL_IMAGE){
      $self->{Debugger}->debug("Gonna delete image");
      my $command = "rm $OriginalImage";
      my $output = `$command`;
      $self->{Debugger}->debug("Command: $command - $output");
   }
}

=head2 resizeAmazonImage

Given an image creates the properly sized image for the Avatar

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Utilities::ImageResizer object
   2. $Image - Path to the temporary image 

=item B<Returns :>

   1. $Error - Empty string if all went well

=back

=cut

#############################################
sub resizeAmazonImage {
#############################################
   my $self = shift;
   my $OriginalImage = shift;

   $self->{Debugger}->debug("in Lists::Utilities::ImageResizer::resizeAmazonImage with $OriginalImage");

   # Check if the image is large enough to need resizing
   my ($width, $height) = imgsize($OriginalImage);

   my $extension; my $dir; my $imageID;
   if($OriginalImage =~ m/(.+)\/(\d+)M\.(\w+)$/){
      $dir = $1 . "/";
      $imageID = $2;
      $extension = $3;
   }else{
      $self->{Debugger}->debug("ERROR:: resizeImage Image does follow expected pattern");
      return;
   }

   $self->{Debugger}->debug("Image width: $width, height: $height");

   if($width > $Lists::SETUP::MAX_AMAZON_IMAGE_WIDTH || $height > $Lists::SETUP::MAX_AMAZON_IMAGE_WIDTH){
      $self->{Debugger}->debug("in if");
      my $ImageMagick = Image::Magick->new;
      my $Error = $ImageMagick->Read($OriginalImage);
   
      $self->{Debugger}->debug("Read image: $Error");
   
      if($Error){
         return "Error in Image Resize: $Error";
      }

      my $AmazonGeo = $Lists::SETUP::MAX_AMAZON_IMAGE_WIDTH . "x" . $Lists::SETUP::MAX_AMAZON_IMAGE_WIDTH;
      $Error = $ImageMagick->AdaptiveResize(geometry=>$AmazonGeo, blur => 0);
      $self->{Debugger}->debug("Resize image: $Error");
      if($Error){
         return "Error in Image Resize: $Error";
      }     
      my $AmazonImage = $OriginalImage;

      # Compression for just jpeg should be ok for amazon images, amazon isn't
      # likely to be serving different formats
      $Error = $ImageMagick->Set(compression => 'JPEG', quality=>$Lists::SETUP::IMAGE_QUALITY);
      $self->{Debugger}->debug("Set image: $Error");
      $Error = $ImageMagick->Write($AmazonImage);
      $self->{Debugger}->debug("Write image: $Error");
      $self->{Debugger}->debug("!!! Should have written image: $AmazonImage");
  
   }
}



1;

=head1 AUTHOR INFORMATION

   Author:  Marilyn Burgess
   Last Updated: 22/10/2007

=head1 BUGS

   Not known

=cut

