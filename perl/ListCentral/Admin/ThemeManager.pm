package ListCentral::Admin::ThemeManager;
use strict;

use ListCentral::SETUP;

use ListCentral::Utilities::Date;
use ListCentral::Utilities::Search;

##########################################################
# ListCentral::Admin::ThemeManager 
##########################################################

=head1 NAME

   ListCentral::Admin::ThemeManager.pm

=head1 SYNOPSIS

   $ListManager = new ListCentral::Admin::ThemeManager($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the List application

=head2 ListCentral::List Constructor

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

   $self->{Debugger}->debug("in ListCentral::Admin::ThemeManager constructor");

   if(!$self->{DBManager}){
      die $self->{Debugger}->log("Where is ThemeManager's DBManager??");
   }
   if(!$self->{cgi}){
      die $self->{Debugger}->log("Where is ThemeManager's cgi??");
   }
   if(!$self->{Debugger}){
      print STDERR "No debugger? $self->{Debugger}\n";
   }

   $self->{AdminUser} = $self->{DBManager}->getTableObj("AdminUser"); 

   return ($self); 
}

=head2 getThemeElement

The main function for utilizing the ThemeManager

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::ThemeManager object

=item B<Prints :>

   1. $content - The content requested

=back

=cut

#############################################
sub getThemeElement {
#############################################
   my $self = shift;
   my $element = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::ThemeManager::getThemeElement");

   if($element eq "AvailableThemes"){
      my $AvailableThemes = $self->getAvailableThemes();
      return $AvailableThemes;
   }elsif($element eq "ColourDivCSS"){
      if($self->{ColourDivCSS}){
         return $self->{ColourDivCSS};
      }else{
         $self->getAddNewThemeElements();
         return $self->{ColourDivCSS};
      }
   }elsif($element eq "ColourDivs"){
      if($self->{ColourDivs}){
         return $self->{ColourDivs};
      }else{
         $self->getAddNewThemeElements();
         return $self->{ColourDivs};
      }
   }elsif($element eq "ColoursJS"){
      if($self->{ColoursJS}){
         return $self->{ColoursJS};
      }else{
         $self->getAddNewThemeElements();
         return $self->{ColoursJS};
      }
   }else{
      return $self->{$element};
   }
}

=head2 getAddNewThemeElements

Fills $self->{ColourDivCSS} and $self->{ColourDivs} with the html/css required for
the add new theme function

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::ThemeManager object

=item B<Prints :>

   1. $content - The content requested

=back

=cut

#############################################
sub getAddNewThemeElements {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::ThemeManager::getAddNewThemeElements"); 

   my $ThemeColourObj = $self->{DBManager}->getTableObj("ThemeColours");
   my $ThemeColours = $ThemeColourObj->get_with_restraints("ThemeID = 1");
   if(!scalar(keys %{$ThemeColours})){
      $ThemeColours->{1}->{Colour} = "#ffffff";
      $ThemeColours->{2}->{Colour} = "#ffffff";
      $ThemeColours->{3}->{Colour} = "#ffffff";
      $ThemeColours->{4}->{Colour} = "#ffffff";
      $ThemeColours->{5}->{Colour} = "#ffffff";
   }
   my $rainbow_img = "/images/rainbow.png";

   my $i = 1;
   my $ColourDivCSS = "";
   my $ColourDivs = "";
   my $ColoursJS = "";
   foreach my $ID(sort{$a <=> $b} keys %{$ThemeColours}) {
      my $div_name = "Colour$i"."Div";
      $ColourDivCSS .= qq~
      #$div_name\{
                    margin: 1em 0 1em 1em;    
                    padding: 1em;
                    background-color: $ThemeColours->{$ID}->{Colour};
                    border: 1px solid #000000;
                    width: 120px;
                    float: left;
                    height: 120px;
                \}
                        ~;
      my $div_name = "Colour$i"."Div";
      $ColourDivs .= qq~<div id="$div_name" class="ColourDiv">
                               <h3>$ListCentral::SETUP::THEME_POSITION{$i}</h3><br />
                               <img id="myRainbow$i" src="$rainbow_img" alt="[c1]" width="16" height="16" class="rainbow" />
                               <input type="text" id="Colour$i" name="Colour$i" value="$ThemeColours->{$ID}->{Colour}" class="rainbow" onblur="javascript:setColour('$div_name', this.value)" />
                           </div>
                        ~;

      my $r; my $g; my $b;
      if($ThemeColours->{$ID}->{Colour} =~ m/#(\w{2})(\w{2})(\w{2})/){
         my $rhex = $1;
         my $ghex = $2;
         my $bhex = $3;

         $r = hex($rhex);
         $g = hex($ghex);
         $b = hex($bhex);
      }
      $ColoursJS .= qq~var c$i = new MooRainbow('myRainbow$i', {
                         id: 'myRainbow$i',
                         'startColor': [$r, $g, $b],
                         'onChange': function(color) {
                             \$('Colour$i').value = color.hex;
                             \$('$div_name').style.backgroundColor = color.hex;
                         }
                     });
                        ~;
      $i++;
   }

   $self->{ColourDivCSS}  = $ColourDivCSS;
   $self->{ColourDivs} = $ColourDivs;  
   $self->{ColoursJS} = $ColoursJS;  
}

=head2 getAvailableThemes

Gets the html for the available themes

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::ThemeManager object

=item B<Prints :>

   1. $content - The available themes content

=back

=cut

#############################################
sub getAvailableThemes {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::ThemeManager::getAvailableThemes");

   my $AvailableThemes = "";
   my $ThemeObj = $self->{DBManager}->getTableObj("Theme");
   my $ThemeColourObj = $self->{DBManager}->getTableObj("ThemeColours");
   my $Themes = $ThemeObj->get_all();
   foreach my $ThemeID(sort keys %{$Themes}) {
      $AvailableThemes .= "<tr><td class='ThemeColourHeader'><h3>$ThemeID</h3></td><td class='ThemeColourHeader'><h3>$Themes->{$ThemeID}->{Name}</h3></td>";

      my $ThemeColours = $ThemeColourObj->get_with_restraints("ThemeID = $ThemeID");
      foreach my $ID(sort{$ThemeColours->{$a}->{Position} <=> $ThemeColours->{$b}->{Position}} keys %{$ThemeColours}) {
         $AvailableThemes .= "<td bgcolor='$ThemeColours->{$ID}->{Colour}' class='ThemeColour'><br />$ThemeColours->{$ID}->{Colour}</td>";
      }

      if($Themes->{$ThemeID}->{Enabled}){
         $AvailableThemes .= qq~<td class="ThemeEnabling">On<br /> (<a href="/?todo=ThemeManager.DisableTheme&ThemeID=$ThemeID">disable</a>)</td>~;
      }else{
         $AvailableThemes .= qq~<td class="ThemeEnabling">Off<br /> (<a href="/?todo=ThemeManager.EnableTheme&ThemeID=$ThemeID">enable</a>)</td>~;
      }
      $AvailableThemes .= "</tr>";
   }

   return $AvailableThemes;
}

=head2 AddNewTheme

Creates a new theme, comprising of 4 or so colours

=over 4

=item B<Parameters :>

   1. $self - Reference to a ApplicationFramework::Processor object

=item B<Returns :>

   1. $page - The page to be displayed

=back

=cut

#############################################
sub AddNewTheme {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::ThemeManager->AddNewTheme");

   my $ThemeObj = $self->{DBManager}->getTableObj("Theme");
   my $ThemeColourObj = $self->{DBManager}->getTableObj("ThemeColours");

   my %Theme;
   my @ThemeColours;
   foreach my $param (sort{$a cmp $b} keys %{$self->{cgi}}) {
      if($param =~ m/Theme\.(\w+)/){
         $Theme{$param} = $self->{cgi}->{$param};
      }elsif($param =~ m/Colour(\d+)/){
         push(@ThemeColours, $self->{cgi}->{$param});
      }
   }

   $Theme{"Theme.Enabled"} = 0;
   $Theme{"Theme.Status"} = 1;
   my $ThemeID = $ThemeObj->store(\%Theme);   

   my $count = 1;
   foreach my $colour (@ThemeColours) {
      my %ThemeColour = (
                         'ThemeColours.ThemeID' => $ThemeID,
                         'ThemeColours.Colour' => $colour,
                         'ThemeColours.Position' => $count,
                         'ThemeColours.Status' => 1
                         );

      $ThemeColourObj->store(\%ThemeColour);
      $count++;
   }

   $self->generateCSS($ThemeID);
   
   return "$ListCentral::SETUP::ADMIN_DIR_PATH/theme_management.html";
}

=head2 DisableTheme

Enables a theme from the admin interpage

=over 4

=item B<Parameters :>

   1. $self - Reference to a ApplicationFramework::Processor object

=item B<Returns :>

   1. $page - The page to be displayed

=back

=cut

#############################################
sub DisableTheme {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::ThemeManager->DisableTheme");

   my $ThemeObj = $self->{DBManager}->getTableObj("Theme");
   $ThemeObj->update("Enabled", 0, $self->{cgi}->{ThemeID});
   
   return "$ListCentral::SETUP::ADMIN_DIR_PATH/theme_management.html";
}

=head2 EnableTheme

Enables a theme from the admin interpage

=over 4

=item B<Parameters :>

   1. $self - Reference to a ApplicationFramework::Processor object

=item B<Returns :>

   1. $page - The page to be displayed

=back

=cut

#############################################
sub EnableTheme {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::ThemeManager->EnableTheme");

   my $ThemeObj = $self->{DBManager}->getTableObj("Theme");
   $ThemeObj->update("Enabled", 1, $self->{cgi}->{ThemeID});
   
   return "$ListCentral::SETUP::ADMIN_DIR_PATH/theme_management.html";
}


=head2 generateCSS

Given a ThemeID, generates the CSS required

=over 4

=item B<Parameters :>

   1. $self - Reference to a ApplicationFramework::Processor object
   2. $ThemeIS


=back

=cut

#############################################
sub generateCSS {
#############################################
   my $self = shift;
   my $ThemeID = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::ThemeManager->generateCSS");

   # Get the Theme Info
   my $ThemeObj = $self->{DBManager}->getTableObj("Theme");
   my $ThemeColourObj = $self->{DBManager}->getTableObj("ThemeColours");

   my $Theme = $ThemeObj->get_by_ID($ThemeID);
   my $ThemeColours = $ThemeColourObj->get_with_restraints("ThemeID = $ThemeID");
   my %OrderedThemeColours;
   foreach my $ID(%{$ThemeColours}) {
      $OrderedThemeColours{$ThemeColours->{$ID}->{Position}} = $ThemeColours->{$ID}->{Colour};
   }

   # Create the new dirs
   my $themeDir = "$ListCentral::SETUP::BASE_CSS_DIR/$ThemeID";
   if(! -e $themeDir){
      my $output = `mkdir $themeDir`;
   }

   # Write the css files
   my $baseDir = "$ListCentral::SETUP::BASE_CSS_DIR/Base";
   opendir(DIR, "$baseDir") || die "can't opendir $baseDir : $!";
   my @file = grep { !/^\./ && -f "$baseDir/$_" } readdir(DIR);
   closedir DIR;

   foreach my $file(@file) {
      open(FILE, "$baseDir/$file") || $self->{Debugger}->log("cannot open file: $baseDir/$file - $!");
      my @lines = <FILE>;
      close FILE;

      my $content = "";
      foreach my $line (@lines) {
         if($line =~ m/<!--(.+)-->/){
            if($line =~ m/<!--Colour(\d+)-->/){
               my $position = $1;
               $line =~ s/<!--Colour$position-->/$OrderedThemeColours{$position}/;
            }
            if($line =~ m/<!--ThemeID-->/){
               $line =~ s/<!--ThemeID-->/$ThemeID/;
            }
         }
         $content .= $line;
      }

      # Write out new css file
      my $newCSSFile = "$themeDir/$file";
      open(FILE, "+> $newCSSFile") || $self->{Debugger}->debug("cannot open file: $newCSSFile - $!");
      print FILE $content;
      close FILE;
   }
}

=head2 refreshBaseCSSFiles

Copies the file from the default theme directory, and copies all of the css files
subbing out the coulors for <!--ColourX-->, where X is the colours Position in the theme

=over 4

=item B<Parameters :>

   1. $self - Reference to a ApplicationFramework::Processor object
   2. $ThemeIS


=back

=cut

#############################################
sub refreshBaseCSSFiles {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::ThemeManager->refreshBaseCSSFiles");

   my $ThemeColoursObj = $self->{DBManager}->getTableObj("ThemeColours");
   my $ThemeColours = $ThemeColoursObj->get_with_restraints("ThemeID = $ListCentral::SETUP::CONSTANTS{'DEFAULT_THEME'}");
   my %OrderedThemeColours;
   foreach my $ID(keys %{$ThemeColours}) {
      $OrderedThemeColours{$ThemeColours->{$ID}->{Position}} = $ThemeColours->{$ID}->{Colour};
   }
   
   # Create the new dirs
   my $defaultThemeDir = "$ListCentral::SETUP::DIR_PATH/css/$ListCentral::SETUP::CONSTANTS{'DEFAULT_THEME'}";
   my $baseThemeDir = "$ListCentral::SETUP::DIR_PATH/css/Base";
   if( -e $defaultThemeDir){
      my $output = `cp  $defaultThemeDir/* $baseThemeDir/`;  
   }

   # Write the IE css files
   opendir(DIR, $baseThemeDir) || die "can't opendir $baseThemeDir : $!";
   my @file = grep { !/^\./ && -f "$baseThemeDir/$_" } readdir(DIR);
   closedir DIR;

   foreach my $file(@file) {
      open(FILE, "$baseThemeDir/$file") || $self->{Debugger}->log("cannot open file: $file - $!");
      my @lines = <FILE>;
      close FILE;

      my $content = "";
      foreach my $line (@lines) {
         foreach my $position(keys %OrderedThemeColours) {
            my $colour = $OrderedThemeColours{$position};
            if($line =~ m/$colour/){
               $self->{Debugger}->debug("-------------- line matches colour: $colour");
               my $replace = "<!--Colour" . $position . "-->";
               $line =~ s/$colour/$replace/;
            }
         }

         if($line =~ m/\/1\//){
            $line =~ s/\/1\//\/<!--ThemeID-->\//;
         }

         $content .= $line;
      }

      # Write out new css file
      my $newCSSFile = "$baseThemeDir/$file";
      open(FILE, "+> $newCSSFile") || $self->{Debugger}->log("cannot open file: $newCSSFile - $!");
      print FILE $content;
      close FILE;
   }
}

=head2 generateImages

Given a ThemeID, generates the images needed for the new List Central theme

=over 4

=item B<Parameters :>

   1. $self - Reference to a ApplicationFramework::Processor object
   2. $ThemeIS


=back

=cut

#############################################
sub generateImages {
#############################################
   my $self = shift;
   my $ThemeID = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::ThemeManager->generateImages");

   use ListCentral::Utilities::ImageColorConverter;
   my $ImageColorConverter = new ListCentral::Utilities::ImageColorConverter("Debugger" => $self->{Debugger});

   # Get the Theme Info
   my $ThemeObj = $self->{DBManager}->getTableObj("Theme");
   my $ThemeColourObj = $self->{DBManager}->getTableObj("ThemeColours");

   my $Theme = $ThemeObj->get_by_ID($ThemeID);
   my $ThemeColours = $ThemeColourObj->get_with_restraints("ThemeID = $ThemeID");
   my @OrderedThemeColours;
   foreach my $ID(sort{$ThemeColours->{$a}->{Position} <=> $ThemeColours->{$b}->{Position}} keys %{$ThemeColours}) {
      $self->{Debugger}->debug("pushing $ThemeColours->{$ID}->{Colour}");
      push(@OrderedThemeColours, $ThemeColours->{$ID}->{Colour});
   }
   my $link = $ImageColorConverter->convertImagesWithIM($ThemeID, \@OrderedThemeColours);
}

=head2 RegenerateThemes

Handles the process of generating the elements of the themes on call

To be used when images and/or css change, and the change must be generated across 
all themes

=over 4

=item B<Parameters :>

   1. $self - Reference to a ApplicationFramework::Processor object

=item B<Returns :>

   1. $page - The page to be displayed

=back

=cut

#############################################
sub RegenerateThemes {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::ThemeManager->RegenerateThemes");

   # From the values of the buttons
   my $regenerate = $self->{cgi}->{"regenerate"};
   $self->{Debugger}->debug("regenerate: $regenerate");
   my $ThemeObj = $self->{DBManager}->getTableObj("Theme");
   my $Themes = $ThemeObj->get_all();
   foreach my $ThemeID(keys %{$Themes}) {
      if($ThemeID != $ListCentral::SETUP::CONSTANTS{'DEFAULT_THEME'}){
         if($regenerate eq "Regenerate Theme Css & Images"){
            $self->refreshBaseCSSFiles();
            $self->generateCSS($ThemeID);
            $self->generateImages($ThemeID);
         }elsif($regenerate eq "Rebuild CSS"){
            $self->refreshBaseCSSFiles();
            $self->generateCSS($ThemeID);
         }elsif($regenerate eq "Regenerate Theme Images"){
            $self->generateImages($ThemeID);
         }  
      }
   }
   return "$ListCentral::SETUP::ADMIN_DIR_PATH/theme_management.html";
}


1;

=head1 AUTHOR INFORMATION

   Author: Brahmina Burgess 
   Created: 10/1/2008

=head1 BUGS

   Not known

=cut
