package ListCentral::DB::Image;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;

use ListCentral::SETUP;

##########################################################
# ListCentral::DB::Image 
##########################################################

=head1 NAME

   ListCentral::DB::Image.pm

=head1 SYNOPSIS

   $Image = new ListCentral::DB::Image($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the Image table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::Image::init");

   my @Fields = ("Filename", "Alt", "Status", "CreateDate", "UserID", "Extension");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;
}

=head2 getImageInfo

When image.html is called, this func puts the relavant image info into self

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListItemStatus object

=back

=cut

#############################################
sub getImageInfo {
#############################################
   my $self = shift;
   my $ImageID = shift;
   my $DBManager = shift;
   my $UserManager = shift;

   $self->{Debugger}->debug("in ListCentral::ListManager::getImageInfo with ImageID: $ImageID");

   my $ListItemObj = $DBManager->getTableObj("ListItem"); 
   my $Image = $self->get_by_ID($ImageID);
   my $directory = $UserManager->getUsersDirectory($Image->{UserID});

   my %ImageInfo;
   $ImageInfo{ImageSRC} = "$ListCentral::SETUP::USER_CONTENT_DIRECTORY/$directory/$ImageID" . "L.$Image->{Extension}";

   my $ListItem = $ListItemObj->get_with_restraints("ImageID = $ImageID");

   # There should only be one, but it's a multi-level hash
   foreach my $ID(keys %{$ListItem}) {
      $ImageInfo{ListItemName} = $ListItem->{$ID}->{Name};
   }

   $ImageInfo{PageTitle} = "LC Image - $self->{ListItemName}";

   return \%ImageInfo;
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 21/1/2008

=head1 BUGS

   Not known

=cut


