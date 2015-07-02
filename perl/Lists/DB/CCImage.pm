package Lists::DB::CCImage;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::CCImage 
##########################################################

=head1 NAME

   Lists::DB::CCImage.pm

=head1 SYNOPSIS

   $CCImage = new Lists::DB::CCImage($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the CCImage table in the 
Lists database.


=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::CCImage::init");

   my @Fields = ("Image", "Source", "Credit", "CreateDate", "Status", "FlkrID");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;
}

=head2 getByFlkrID

Gets the TableObject entry corresponding the the ID passed and returns a reference to a hash containing
the TableObject information 

=over 4

=item B<Parameters :>

   1. $self - Reference to a TableObject object
   2. $FlkrID - The CCImage's flickr id

=item B<Returns: >

   1. $TableObject - Reference to a hash with the TableObject data

=back

=cut

#############################################
sub getByFlkrID {
#############################################
   my $self = shift;
   my $FlkrID = shift;

   $self->{Debugger}->debug("in Lists::DB::CCImage::getByFlkrID with $FlkrID");

   my $dates = "";
   if($self->{DateField}){
      $dates = ", from_unixtime($self->{DateField}) as $self->{DateField}Fomatted ";
   }

   my $TableObject;
   my $sql_select = "SELECT *$dates
                     FROM $Lists::SETUP::DB_NAME.$self->{Table} 
                     WHERE FlkrID = \"$FlkrID\"
                           AND $self->{StatusField} > 0";
   $self->{Debugger}->debug($sql_select);
   my $stm = $self->{dbh}->prepare($sql_select);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $TableObject = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with CCImage  SELECT: $sql_select - $DBI::errstr");
   }
   $stm->finish;

   return $TableObject;
}

=head2 saveCCImage

Saves a new CCImage

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub saveCCImage {
#############################################
   my $self = shift;
   my $cgi = shift;

   $self->{Debugger}->debug("in Lists::DB::CCImage saveCCImage");

   my $CCImageID;
   my $CCImageCurrent = $self->getByFlkrID($cgi->{"ListItem.CCImage"});
   if($CCImageCurrent->{ID}){
      $CCImageID = $CCImageCurrent->{ID};
   }else{   
      my %CCImage = ();
      $CCImage{"CCImage.Status"} = 1;
      $CCImage{"CCImage.FlkrID"} = $cgi->{"ListItem.CCImage"};
      
      $CCImageID = $self->store(\%CCImage);
   
      use Lists::Utilities::CCImage;
      my $CCImage = new Lists::Utilities::CCImage(Debugger => $self->{Debugger}, DBManager => $self->{DBManager});
      $CCImage->setCCImage($CCImage{"CCImage.FlkrID"}, $self);
   }
   return $CCImageID;
}



1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


