package ListCentral::DB::ListTag;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::ListTag 
##########################################################

=head1 NAME

   ListCentral::DB::ListTag.pm

=head1 SYNOPSIS

   $ListTag = new ListCentral::DB::ListTag($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the ListTag table in the 
Lists database.


=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::AdImpressions::init");

   my @Fields = ("TagID", "ListID", "Status");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ();
   $self->{DateFields} = \@DateFields;
}

=head2 deleteListTagsByList

Given a List ID, deletes all the entries in the ListTtag table for that list

Currently does not check if the tags are still associated with any other lists

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListTag object
   2. $ListID - The list id

=back

=cut

#############################################
sub deleteListTagsByList {
#############################################
   my $self = shift;
   my $ListID = shift;

   $self->{Debugger}->debug("in ListCentral::DB::ListTag::update with $ListID");

   if($ListID){
      my $sql = "DELETE FROM $ListCentral::SETUP::DB_NAME.ListTag WHERE ListID = $ListID";
      my $stm = $self->{dbh}->prepare($sql);
      if ($self->{dbh}->do($sql)) {
         # Good Stuff
      }else {
         $self->{Debugger}->throwNotifyingError("ERROR: with ListTag DELETE by ListID::: $sql\n");
      }
   }
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


