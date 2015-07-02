package Lists::DB::Referrers;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::Referrers 
##########################################################

=head1 NAME

   Lists::DB::Referrers.pm

=head1 SYNOPSIS

   $Referrers = new Lists::DB::Referrers($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the Referrers table in the 
Lists database.


=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::AdImpressions::init");

   my @Fields = ("Count", "Note", "Name");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;
}


=head2 getTopReferrers

Gets the top referrers to be displayed to the admin people

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::Manager object

=item B<Returns :>

   1. $TopReferrers

=back

=cut

#############################################
sub getTopReferrers {
#############################################
   my $self = shift;
   my $limit = shift;

   $self->{Debugger}->debug("in Lists::DB::Referrers saveReferrer");

   my $count = 0;
   my %Referrers;
   my $sql = "SELECT * FROM Referrers ORDER BY Count DESC LIMIT $limit";

   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $Referrers{$hash->{ID}} = $hash;
         $count++;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with Referrers SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;


   return \%Referrers;
}

=head2 saveReferrer

Gets the 

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::Manager object

=item B<Returns :>

   1. $TopReferrers

=back

=cut

#############################################
sub saveReferrer {
#############################################
   my $self = shift;
   my $referrer = shift;

   $self->{Debugger}->debug("in Lists::DB::Referrers saveReferrer");

   my $Referrer;
   my $sql = "SELECT * FROM $Lists::SETUP::DB_NAME.Referrers WHERE Name = \"$referrer\"";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $Referrer = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with Referrers SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   if($Referrer->{ID}){
      my $count = $Referrer->{Count} + 1;
      $self->update("Count", $count, $Referrer->{ID});
   }else{
      my %Referrer = ("Referrers.Name" => $referrer,
                      "Referrers.Count" => 1 );
      my $ID = $self->store(\%Referrer);
   }
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 27/9/2008

=head1 BUGS

   Not known

=cut


