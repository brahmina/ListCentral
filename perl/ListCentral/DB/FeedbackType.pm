package ListCentral::DB::FeedbackType;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::FeedbackType 
##########################################################

=head1 NAME

   ListCentral::DB::FeedbackType.pm

=head1 SYNOPSIS

   $FeedbackType = new ListCentral::DB::FeedbackType($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the FeedbackType table in the 
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

   my @Fields = ("Status", "Name");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ();
   $self->{DateFields} = \@DateFields;
}

=head2 get_all_for_admin

Gets all the entries in FeedbackType, includeing those with 0 status

=over 4

=item B<Parameters :>

   1. $self - Reference to a FeedbackType object

=item B<Returns: >

   1. $FeedbackType - Reference to a hash with the FeedbackType data

=back

=cut

#############################################
sub get_all_for_admin {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::FeedbackType::get_all");

   my %FeedbackType;
   my $sql = "SELECT * FROM $ListCentral::SETUP::DB_NAME.FeedbackType";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $FeedbackType{$hash->{ID}} = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with FeedbackType SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   return \%FeedbackType;
}


1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 27/9/2008

=head1 BUGS

   Not known

=cut


