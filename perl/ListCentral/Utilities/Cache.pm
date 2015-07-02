package ListCentral::Utilities::Cache;
use strict;

use ListCentral::SETUP;

##########################################################
# ListCentral::Cache 
##########################################################

=head1 NAME

   ListCentral::Utilities::Cache.pm

=head1 SYNOPSIS

   $Cache = new ListCentral::Utilities::Cache(Debugger);

=head1 DESCRIPTION

Used to get resources from the web

=head2 ListCentral::Utilities::Cache Constructor

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

   $self->{Debugger}->debug("in ListCentral::Utilities::Cache constructor");

   return ($self); 
}

=head2 checkCache

Given a page name ($r->file_requested)

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::AdvertManager object

=item B<Prints :>

   1. "build_and_cache", "build" or the content of the cached page to be dispalyed

=back

=cut

#############################################
sub checkCache {
#############################################
   my $self = shift;
   my $file_requested = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::Cache->checkCache with $file_requested");

   my $return = "";
   my $pageToCheck = $self->getCachePageName($file_requested);
   if($pageToCheck ne ""){
      if( -e $pageToCheck){
         my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($pageToCheck);

         my $tooOld = 1;
         my $secondOld = time() - $mtime;
         if($secondOld < (60*$ListCentral::SETUP::CACHE_EXPIRY)){
            # Older than $CACHE_EXPIRY mintes
            $tooOld = 0;
         }
         if(! $tooOld){
            if(! open(FILE, $pageToCheck)){
               $self->{Debugger}->throwNotifyingError("Cannot open cache file: $pageToCheck -> $!");
               $return = "build_and_cache";
            }
            my @lines = <FILE>;

            my $cacheContent = "";
            foreach (@lines) {
               $cacheContent .= $_;
            }
            close FILE;
            $return = $cacheContent;
         }else{
            $return = "build_and_cache";
         }
      }else{
         $return = "build_and_cache";
      }
   }else{
      $return = "build";
   }

   if($return =~ m/^build/){
      $self->{Debugger}->debug("checkCache returning $return")
   }else{
      $self->{Debugger}->debug("checkCache returning cached page $pageToCheck");
   }
 
   return $return;
}

=head2 setCache

Writes content to the cache for the file requested

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Utilities::Cache object
   2. $file_requested
   3. $page_content

=back

=cut

#############################################
sub setCache {
#############################################
   my $self = shift;
   my $file_requested = shift;
   my $page_content = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::Cache->setCache with $file_requested");

   my $pageToCheck = $self->getCachePageName($file_requested);
   if($pageToCheck ne ""){
      if(! open(FILE, "+>$pageToCheck")){
         if(! open(FILE, ">$pageToCheck")){
            $self->{Debugger}->throwNotifyingError("Cannot open cache file for writing $pageToCheck");
            return;
         }
      }
      
      print FILE $page_content;
      close FILE;
   }
}


=head2 getCachePageName

Converts $file_requested to the cache file name. If returns an empty string, this page should not be cached

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Utilities::Cache object
   2. $file_requested

=item B<Returns :>

   1. $cacheFilePageName

=back

=cut

#############################################
sub getCachePageName {
#############################################
   my $self = shift;
   my $file_requested = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::Cache->getCachePageName with $file_requested");

   my $cachePageName = "";
   if($file_requested =~ m/index/){
      $self->{Debugger}->debug("getCachePageName index -> $self->{cgi}->{WhichListings} : $self->{cgi}->{page}");
      # This is any of the 3 main listings: popular, new or active
      if(! $self->{cgi}->{WhichListings}){
         # not set if hit to index.html
         $self->{cgi}->{WhichListings} = "popular";
      }
      if(! $self->{cgi}->{page}){
         # not set if hit to index.html
         $self->{cgi}->{page} = 1;
      }
      $cachePageName = "$ListCentral::SETUP::CACHE_BASE_DIR/$self->{cgi}->{WhichListings}/$self->{cgi}->{page}.html";
   }elsif($file_requested =~ m/tag/){
      # Tag pages
      if($self->{cgi}->{Tag}){
         $cachePageName = "$ListCentral::SETUP::CACHE_BASE_DIR/tags/$self->{cgi}->{Tag}.html";
      }      
   }elsif($file_requested =~ m/lists/ && !$self->{UserManager}->{ThisUser}->{ID}){
      if($self->{cgi}->{ListID}){
         $cachePageName = "$ListCentral::SETUP::CACHE_BASE_DIR/lists/$self->{cgi}->{ListID}.html";
      }elsif($self->{cgi}->{UserID}){
         $cachePageName = "$ListCentral::SETUP::CACHE_BASE_DIR/users/$self->{cgi}->{UserID}.html";
      }      
   }elsif($file_requested =~ m/about.html/){
         $cachePageName = "$ListCentral::SETUP::CACHE_BASE_DIR/about.html";
   }elsif($file_requested =~ m/help.html/){
         $cachePageName = "$ListCentral::SETUP::CACHE_BASE_DIR/help.html";
   }elsif($file_requested =~ m/terms/){
         $cachePageName = "$ListCentral::SETUP::CACHE_BASE_DIR/terms.html";
   }elsif($file_requested =~ m/privacy/){
         $cachePageName = "$ListCentral::SETUP::CACHE_BASE_DIR/privacy.html";
   }
   $self->{Debugger}->debug("getCachePageName returning -> $cachePageName");

   return $cachePageName;
}  


1;

=head1 AUTHOR INFORMATION

   Author:  Brahmina Burgess
   Last Updated: 27/03/2009

=head1 BUGS

   Not known

=cut



