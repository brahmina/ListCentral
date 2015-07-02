package ListCentral::Admin::Minify;
use strict;

use ListCentral::SETUP;

##########################################################
# ListCentral::Admin::Printer
##########################################################

=head1 NAME

   ListCentral::Admin::Minify.pm

=head1 SYNOPSIS

   $Admin::Printer = new ListCentral::Admin::Minify($Debugger);

=head1 DESCRIPTION

Used to handle the page requests to the Lists web application

=head2 ListCentral::Admin::Minify Constructor

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


   return ($self); 
}

=head2 minifyJS

Recurrsively goes through the directory html/js_src, minifies all .js files and drops the result in 
the directory html/js Copies the non js files as is

=over 4

=item B<Parameters :>

   1. $self - Reference to a Admin::Minify

=back

=cut

#############################################
sub minifyJS {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::Minify->minifyJS");

   my $devDir = "$ListCentral::SETUP::DIR_PATH/js_src"; 
   # Where the development happens
   my $proDir = "$ListCentral::SETUP::DIR_PATH/js";
   # The production version

   # Delete everything in destination
   my $command = "rm -rf $proDir/*.js";
   $self->{Debugger}->debug("Remove command - $command");
   my $output = `$command`;
   $self->{Debugger}->debug("Remove output: $output");

   # Copy the source to the destination
   #$command = "cp -r $destinationDir/* $saveDir/";
   #$self->{Debugger}->debug("Copy command - $command");
   #$output = `$command`;
   #$self->{Debugger}->debug("Copy output: $output");

   $self->minifyJSDir($devDir);

}

=head2 minifyJS

Recurrsively goes through the directory passed, minifies all .js files and drops the result in 
the directory html/js Copies the non js files as is

=over 4

=item B<Parameters :>

   1. $self - Reference to a Admin::Minify

=back

=cut

#############################################
sub minifyJSDir {
#############################################
   my $self = shift;
   my $source = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::Minify->minifyJSDir with $source");

   $source .= '/' if($source !~ /\/$/);
   for my $file (glob($source.'*')) {

      ## if the file is a directory
      if( -d $file){
         ### pass the directory to the routine ( recursion )
         #my $dir = $file;
         #$dir =~ s/\/js_src\//\/js\//;
         #if(! -e $dir){
         #   my $command = "mkdir $dir";
         #   my $output = `$command`;
         #   $self->{Debugger}->debug("Mkdir output: $output");
         #}
         #$self->minifyJSDir($file);
      }else{
         my $profile = $file;
         $profile =~ s/\/js_src\//\/js\//;

         if($file =~ m/\.js$/){
            $self->{Debugger}->debug("found a js file: $file, would be minifying");
            
            my $command = "java -jar /home/bin/yuicompressor-2.4.2.jar $file >> $profile";
            my $output = `$command`;
            $self->{Debugger}->debug("Minify output: $output");
         }else{
            $self->{Debugger}->debug("found some other file: $file, copying it");
            my $command = "cp $file $profile";
            my $output = `$command`;
            $self->{Debugger}->debug("Copy output: $output");
         }
      }
   }
}

1;

=head1 AUTHOR INFORMATION

   Author: 
   Last Updated: 12/01/2012

=head1 BUGS

   Not known

=head1 SEE ALSO


=cut

=over

=cut

