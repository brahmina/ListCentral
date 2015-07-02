package ListCentral::Utilities::ImageColorConverter;
use strict;

use ListCentral::SETUP;

use GD;
use Image::Magick;

##########################################################
# ListCentral::Utilities::ImageColorConverter 
##########################################################

=head1 NAME

   ListCentral::Utilities::ImageColorConverter.pm

=head1 SYNOPSIS

   $ImageColorConverter = new ListCentral::Utilities::ImageColorConverter(Debugger);

=head1 DESCRIPTION

Used to create the new images to be used in newly submitted themes

New images are always sourced from the images from Theme #1

=head2 ListCentral::Utilities::ImageColorConverter Constructor

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

   $self->{Debugger}->debug("in ListCentral::Utilities::ImageColorConverter constructor");
   
   return ($self); 
}


=head2 convertImagesWithIM

Given an array reference with 5 colors in it, this function copies all the images in the 
image source directory (ListCentral::SETUP::SOURCE_THEME_IMAGES_DIR) the image colors 
as per the needs of List Central themes

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object
   2. $colorArray - the email address to send the email to
   3. $saveLocation - the subject of the email to be sent

=item B<Returns :>

   1. $results - 1 if successful, 0 otherwise

=back

=cut

#############################################
sub convertImagesWithIM {
#############################################
   my $self = shift;
   my $ThemeID = shift;
   my $colorArray = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::ImageColorConverter::convertImages with ThemeID = $ThemeID");

   # Make the new dir
   my $newthemedir = $ListCentral::SETUP::SOURCE_THEME_IMAGES_DIR;
   $newthemedir =~ s/Base//;
   $newthemedir = $newthemedir . "/" . $ThemeID;
   if(! -e $newthemedir){
   my $output = `mkdir $newthemedir`;
      if($output){
         print $self->{Debugger}->throwNotifyingError("Error:: mkdir $newthemedir -> $!\n");
      }
   }else{
      # Empty the contents of the directory?? 
   }

   # Get the files in the base dir into an array
   opendir(BASE_DIR, $ListCentral::SETUP::SOURCE_THEME_IMAGES_DIR);
   
   my @files = readdir(BASE_DIR);
   closedir(BASE_DIR);

   foreach my $img(@files) {
      if($img =~ m/png$/i || $img =~ m/gif/i || $img =~ m/jpg/i || $img =~ m/jpeg/){
         my $iMagickOld = new Image::Magick;
         my $imagefile = $ListCentral::SETUP::SOURCE_THEME_IMAGES_DIR ."/".$img;

         my $warn = $iMagickOld->Read($imagefile);
         $self->{Debugger}->debug("READ WARN: $warn");
         my ($width, $height) = $iMagickOld->Get('width', 'height');

         my $size = $width ."x".$height;
         my $iMagickNew = new Image::Magick(size=>$size);
         $warn = $iMagickNew->ReadImage('NULL:white');
         $self->{Debugger}->debug("ReadImage WARN: $warn");


         for my $y (0..($height-1)){
            for my $x (0..($width-1)){

               my (@pixel) = split(/,/, $iMagickOld->Get("pixel[$x,$y]"));

               my $red = $self->DecToHex($pixel[0]);
               my $green = $self->DecToHex($pixel[1]);
               my $blue = $self->DecToHex($pixel[2]);

               my $color = "#" . $red . $green . $blue;

               for(my $i = 0; $i < @ListCentral::SETUP::THEME_BASE_COLORS; $i++ ) {
                  #$self->{Debugger}->debug("$color eq $ListCentral::SETUP::THEME_BASE_COLORS[$i] ??");
                  if($color eq $ListCentral::SETUP::THEME_BASE_COLORS[$i] && $color ne $colorArray->[$i]){
                     # change the pixel $colorArray->[$i]

                     my $r; my $g; my $b;
                     my $changeToColor = $colorArray->[$i];
                     if($changeToColor =~ m/#([\w\d]{2})([\w\d]{2})([\w\d]{2})/){
                        $r = $1; $g = $2; $b = $3;
                     }

                     my $red = $self->HexToDec($r);
                     my $green = $self->HexToDec($g);
                     my $blue = $self->HexToDec($b);

                     my $toColorHex = "#".$r.$g.$b;
                     my $toColorDec = "$red, $green, $blue";

                     my $x2 = $x + 1; my $y2 = $y + 1;
                     my $warn = $iMagickNew->Draw(fill=>$toColorHex, primitive=>'point',points=>"$x,$y");


                     if($warn){
                        $self->{Debugger}->debug("Changing pixl [$x,$y] from $color to $toColorHex ($toColorDec)\nWARN: $warn");
                     }
                  }
               }
            }
         }
         my $newImage = $newthemedir . '/' . $img;
         $self->{Debugger}->debug("Should be writing image $newImage");
	 my $warn = $iMagickNew->Write($newImage);
         $self->{Debugger}->debug("WARN: $warn");
      }
   }
}


=head2 convertImagesWithGD

Given an array reference with 5 colors in it, this function copies all the images in the 
image source directory (ListCentral::SETUP::SOURCE_THEME_IMAGES_DIR) the image colors 
as per the needs of List Central themes

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object
   2. $colorArray - the email address to send the email to
   3. $saveLocation - the subject of the email to be sent

=item B<Returns :>

   1. $results - 1 if successful, 0 otherwise

=back

=cut

#############################################
sub convertImagesWithGD {
#############################################
   my $self = shift;
   my $ThemeID = shift;
   my $colorArray = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::Amazon::convertImages with ThemeID = $ThemeID");

   my $i = 0;
   foreach (@{$colorArray}) {
      $self->{Debugger}->debug("_____________________ _______________COLOR ARRAY: $_ , i: $i, in array: $colorArray->[$i]");
      $i++;
   }

   # Make the new dir
   my $newthemedir = $ListCentral::SETUP::SOURCE_THEME_IMAGES_DIR;
   $newthemedir =~ s/Base//;
   $newthemedir = $newthemedir . $ThemeID;
   my $output = `mkdir $newthemedir`;
   if($output){
      print $self->{Debugger}->throwNotifyingError("Error:: mkdir $newthemedir -> $!\n");
   }

   # Get the files in the base dir into an array
   opendir(BASE_DIR, $ListCentral::SETUP::SOURCE_THEME_IMAGES_DIR);
   my @files = readdir(BASE_DIR);
   closedir(BASE_DIR);


   foreach my $img(@files) {
      if($img =~ m/png$/i || $img =~ m/gif/i || $img =~ m/jpg/i || $img =~ m/jpeg/){
         my $iMagickOld = new Image::Magick;
         my $imagefile = $ListCentral::SETUP::SOURCE_THEME_IMAGES_DIR ."/".$img;
   
         my $oldImageGD = new GD::Image($imagefile);
         my ($width, $height) = $oldImageGD->getBounds();
         my $newImageGD = new GD::Image($width, $height);

         $self->{Debugger}->debug("Image has width: $width, height: $height");

         for my $y (0..($height-1)){
            for my $x (0..($width-1)){
               
               my $pixel = $oldImageGD->getPixel($x,$y);
               my ($r_old, $g_old, $b_old) = $oldImageGD->rgb($pixel);
               
               $self->{Debugger}->debug("R: $r_old, G: $g_old, B: $b_old");


               my $old_color = "#".$self->DecToHex($r_old).$self->DecToHex($g_old).$self->DecToHex($b_old);
               for(my $i = 0; $i < @ListCentral::SETUP::THEME_BASE_COLORS; $i++ ) {
                  $self->{Debugger}->debug("$old_color eq $ListCentral::SETUP::THEME_BASE_COLORS[$i]  ??");
                  if($old_color eq $ListCentral::SETUP::THEME_BASE_COLORS[$i] && $old_color ne $colorArray->[$i]){
                     $self->{Debugger}->debug("_____________ YES");
                     my $r; my $g; my $b;
                     my $changeToColor = $colorArray->[$i];
                     if($changeToColor =~ m/#([\w\d]{2})([\w\d]{2})([\w\d]{2})/){
                        $r = $1; $g = $2; $b = $3;
                     }
                     
                     my $new_color = $newImageGD->colorAllocate($r,$g,$b);
                     $self->{Debugger}->debug("giving pixel [$x,$y] color ($r,$g,$b)");
                     $newImageGD->setPixel($x,$y,$new_color);
                  }
               }
            }
         }   

         my $newImage = $newthemedir . "/" . $img;
         $self->{Debugger}->debug("Should be writing image $newImage");
         open (NEW_IMAGE, "+>$newImage") || die "Cannot open image file for writing: $newImage - $!";
         print NEW_IMAGE $newImageGD->png;
      }
   }
}



=head2 DecToHex

Converts a decimal number to a hexidecimal number

If result is 4 characters, returns the first two, which handles the raw RGB 
values returned from Image Magick on Get('pixel[x,y])

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object
   2. $Dec - a decimal number

=item B<Returns :>

   1. $hex - the corresponding hex number

=back

=cut

#############################################
sub DecToHex {
#############################################
   my $self = shift;
   my $dec = shift;

   my $hex = sprintf("%X", $dec);
   if($hex =~ m/^([\w\d]{2})/){
      $hex = $1;
   }

   $hex = lc($hex);
   return $hex;
} 

=head2 HexToDec

Converts a hexidecimal number to a decimal number

If result is 4 characters, returns the first two, which handles the raw RGB 
values returned from Image Magick on Get('pixel[x,y])

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object
   2. $Dec - a decimal number

=item B<Returns :>

   1. $hex - the corresponding hex number

=back

=cut

#############################################
sub HexToDec {
#############################################
   my $self = shift;
   my $hex = shift;

   my $dec = hex($hex);

   return $dec;
} 

1;

=head1 AUTHOR INFORMATION

   Author:  Brahmina Burgess
   Last Updated: 13/03/2009

=head1 BUGS

   Not known

=cut



