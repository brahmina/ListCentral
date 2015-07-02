package Lists::Utilities::StringFormator;

use strict;
use Lists::SETUP;

##########################################################
# Lists::Utilities::StringFormater
##########################################################

=head1 NAME

    Lists::Utilities::StringFormater.pm

=head1 SYNOPSIS

   Lists::Utilities::StringFormater::fuction();

=head1 DESCRIPTION

Contains handy string manipulation functions

=head2 toTitleCase

   http://daringfireball.net/projects/titlecase/TitleCase.pl 

=over 4

=item B<Parameters :>

   1. $self - Reference to a OpenID object
   2. $sting - Field name to be updated

=item B<Returns :>

   1. $ring - the string in title case

=back

=cut

#############################################
sub toTitleCase {
#############################################
   my $string = shift;

   $string = lc($string);
   
   my @small_words = qw( (?<!q&)a an and as at(?!&t) but by en for if in of on or the to v[.]? via vs[.]? );
   my $small_re = join '|', @small_words;
  
   my $titleString = "";
   my @words = split(/ /, $string);


   #loop over strings
   my $n = 0;
   foreach my $word (@words) {
      if($small_re !~ m/|$word|/){
         #return with first let. caps
         $word = ucfirst($word);
         #assign back to array
         $words[$n] = $word;
      }        
      $n++;
   }

   #join the strings into one
   $titleString = join(" ", @words);

   return $titleString;

}

=head2 canonicalizeURL

   Add http:// if it's missing and you should convert the protocol 
   and domain to lowercase (but NOT the rest of the URL), 
   so e.g. "WWW.AOL.COM/myOpenID" should be stored as "http://www.aol.com/myOpenID". 
   You should also probably remove any trailing slashes from the URL.  

=over 4

=item B<Parameters :>

   1. $self - Reference to a OpenID object
   2. $url - Field name to be updated

=item B<Returns :>

   1. $url - the url canoicalized

=back

=cut

#############################################
sub canonicalizeURL {
#############################################
   my $url = shift;

   # Add http:// if it's missing and you should convert the protocol 
   # and domain to lowercase (but NOT the rest of the URL), 
   # so e.g. "WWW.AOL.COM/myOpenID" should be stored as "http://www.aol.com/myOpenID". 
   # You should also probably remove any trailing slashes from the URL. 

   return $url;

}

=head2 randomString

   Returns a random string of characters of the length passed 

=over 4

=item B<Parameters :>

   1. $self - Reference to a OpenID object
   2. $length - the length of the random string to generate

=item B<Returns :>

   1. $RandomString - The random string requested

=back

=cut

#############################################
sub randomString {
#############################################
     my $length_of_randomstring = shift;

     my @chars=('a'..'z','A'..'Z','_');
     my $random_string;
     foreach (1..$length_of_randomstring) {
             $random_string.=$chars[rand @chars];
     }
     return $random_string;
}

=head2 unquoteText

Processes ajax strings

=over 4

=item B<Parameters :>

   1. $Str - the string to be unquoted

=item B<Returns :>

   1. $String - the unquoted string

=back

=cut

#####################################
sub unquoteText {
#####################################
   my $Str = shift;

   use URI::Escape::JavaScript qw(unescape);
   my $result = unescape($Str);
   return $result;
}

=head2 htmlEncode

HTML encodes the string given and returns it

=over 4

=item B<Parameters :>

   1. $Str - the string to be unquoted

=item B<Returns :>

   1. $String - the unquoted string

=back

=cut

#####################################
sub htmlEncode {
#####################################
   my $Str = shift;

   use HTML::Entities;

   my $result = encode_entities($Str);

   return $result;
}

=head2 htmlDecode

HTML decode the string given and returns it

=over 4

=item B<Parameters :>

   1. $Str - the string to be unquoted

=item B<Returns :>

   1. $String - the unquoted string

=back

=cut

#####################################
sub htmlDecode {
#####################################
   my $Str = shift;

   use HTML::Entities;

   my $result = decode_entities($Str);

   return $result;
}

=head2 hasBadHTML

Checks for back html tags not permitted

script, object, img, meta

=over 4

=item B<Parameters :>

   1. $Str - the string to be unquoted

=item B<Returns :>

   1. $String - the unquoted string

=back

=cut

#####################################
sub hasBadHTML {
#####################################
   my $Str = shift;

   my $result = $Str;

   if($Str =~ m/<script/){
      return 1;
   }elsif($Str =~ m/<object/){
      return 1;
   }elsif($Str =~ m/<img/){
      return 1;
   }elsif($Str =~ m/<meta/ || $Str =~ m/<title/){
      return 1;
   }elsif($Str =~ m/<embed/ || $Str =~ m/<form/ || $Str =~ m/<input/ || $Str =~ m/<select/ ||$Str =~ m/<option/){
      return 1;
   }elsif($Str =~ m/<table/ || $Str =~ m/<\/table/ || $Str =~ m/<tr/ || $Str =~ m/<\/tr/ || $Str =~ m/<td/ || $Str =~ m/<\/td/){
      return 1;
   }elsif($Str =~ m/<html/ || $Str =~ m/<body/ || $Str =~ m/<head/ || $Str =~ m/<\/html/ || $Str =~ m/<\/body/ || $Str =~ m/<\/head/){
      return 1;
   }elsif($Str =~ m/<\/html/ || $Str =~ m/<\/body/ || $Str =~ m/<\/head/){
      return 1;
   }elsif($Str =~ m/<center/ || $Str =~ m/<\/center/ || $Str =~ m/<hr/){
      return 1;
   }elsif($Str =~ m/<h\d/ || $Str =~ m/<\/h\d/){
      # No headers, as they are defined by css
      return 1;
   }elsif($Str =~ m/<menu/ || $Str =~ m/<\/menu/ || $Str =~ m/<marquee/ || $Str =~ m/<\/marquee/){
      # No odd ball things
      return 1;
   }

   my @allTags = ($Str =~ m/<(\w+)/g);
   my %openingTags;
   foreach my $tag (@allTags){
      if($openingTags{$tag}){
         $openingTags{$tag} = $openingTags{$tag} + 1;
      }else{
         $openingTags{$tag} = 1;
      }
   }

   my @allTags = ($Str =~ m/<\/(\w+)>/g);
   my %closingTags;
   foreach my $tag (@allTags){
      if($closingTags{$tag}){
         $closingTags{$tag} = $closingTags{$tag} + 1;
      }else{
         $closingTags{$tag} = 1;
      }
   }

   my $return = "";
   foreach my $tag(keys %openingTags) {
      while ($closingTags{$tag} < $openingTags{$tag}) {
         
         $return .= "</$tag>";
         $closingTags{$tag}++;
      }
   }
   
   return $return;
}

1;

