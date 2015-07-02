package ListCentral::DB::Embed;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::Embed 
##########################################################

=head1 NAME

   ListCentral::DB::Embed.pm

=head1 SYNOPSIS

   $Embed = new ListCentral::DB::Embed($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the Embed table in the 
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

   my @Fields = ("EmbedCode", "CreateDate", "Status");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;
}

=head2 saveEmbed

Saves a new Embed

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $ID - The ID of the embed saved

=back

=cut

#############################################
sub saveEmbed {
#############################################
   my $self = shift;
   my $cgi = shift;

   my %Embed = ();
   $Embed{"Embed.Status"} = 1;
   $Embed{"Embed.EmbedCode"} = $cgi->{"ListItem.Embed"};

   my $EmbedID = 0;
   $Embed{"Embed.EmbedCode"} =~ s/^\s+//;
   $Embed{"Embed.EmbedCode"} =~ s/\s+$//;
   #if(($Embed{"Embed.EmbedCode"} =~ m/^<object.+><\/object>$/) 
   #   && !($Embed{"Embed.EmbedCode"} =~ m/<script/) 
   #   && !($Embed{"Embed.EmbedCode"} =~ m/<html/) 
   #   && !($Embed{"Embed.EmbedCode"} =~ m/<iframe/)){
   #   my $EmbedObj = $self->{DBManager}->getTableObj("Embed");
   #   $EmbedID = $EmbedObj->store(\%Embed);
   #}

   my $EmbedObj = $self->{DBManager}->getTableObj("Embed");
   $EmbedID = $EmbedObj->store(\%Embed);
   
   return $EmbedID;
}


1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


