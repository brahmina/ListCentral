package ListCentral::Utilities::HelpManager;
use strict;

use ListCentral::SETUP;
use ListCentral::Admin::PageGetter;

##########################################################
# ListCentral::HelpManager 
##########################################################

=head1 NAME

   ListCentral::Utilities::HelpManager.pm

=head1 SYNOPSIS

   $HelpManager = new ListCentral::Utilities::HelpManager(Debugger);

=head1 DESCRIPTION

Used to get resources from the web

=head2 ListCentral::Utilities::HelpManager Constructor

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

   $self->{Debugger}->debug("in ListCentral::Utilities::HelpManager constructor");
   
   return ($self); 
}


=head2 AddHelpPage

Adds a new help page from the admin system

=over 4

=item B<Parameters :>

   1. $self - Reference to a HelpManager object

=item B<Returns :>

   1. 

=back

=cut

#############################################
sub AddHelpPage {
#############################################
   my $self = shift;

   my $HelpObj = $self->{DBManager}->getTableObj("Help");

   my $nextPosition = $HelpObj->getNextHelpPosition();
   $self->{cgi}->{"Help.Ordering"} = $nextPosition;
   my $HelpID = $HelpObj->store($self->{cgi});

   return "$ListCentral::SETUP::ADMIN_DIR_PATH/help_management.html";
}

=head2 DeleteHelpPage

Adds a new help page from the admin system

=over 4

=item B<Parameters :>

   1. $self - Reference to a HelpManager object

=item B<Returns :>

   1. 

=back

=cut

#############################################
sub DeleteHelpPage {
#############################################
   my $self = shift;

   my $HelpObj = $self->{DBManager}->getTableObj("Help");
   my $Help = $HelpObj->update("Status", 0, $self->{cgi}->{"Help.ID"});

   return "$ListCentral::SETUP::ADMIN_DIR_PATH/help_management.html";
}

=head2 EditHelpPage

Adds a new help page from the admin system

=over 4

=item B<Parameters :>

   1. $self - Reference to a HelpManager object

=item B<Returns :>

   1. 

=back

=cut

#############################################
sub EditHelpPage {
#############################################
   my $self = shift;

   my $HelpObj = $self->{DBManager}->getTableObj("Help");
   my $Help = $HelpObj->get_by_ID($self->{cgi}->{"Help.ID"});
   foreach my $key (keys %{$Help}) {
      if($Help->{$key} ne $self->{cgi}->{"Help.".$key} && $key ne "Status" && $key ne "ID"){
         $HelpObj->update($key, $self->{cgi}->{"Help.".$key}, $self->{cgi}->{"Help.ID"});
      }
   }

   return "$ListCentral::SETUP::ADMIN_DIR_PATH/help_management.html";
}

=head2 getHelpListings

Gets the help listings for the help pages

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the help listing

=back

=cut

#############################################
sub getHelpListings {
#############################################
   my $self = shift;

   $self->{Debugger}->debugNow("in ListCentral::HelpManager::getHelpListings"); 

   my $HelpObj = $self->{DBManager}->getTableObj("Help");
   my $Helps = $HelpObj->getListings();

   my $Listings = "";
   foreach my $ID(sort{$Helps->{$a}->{Ordering} <=> $Helps->{$b}->{Ordering}} keys %{$Helps}) {
      $self->{Debugger}->debugNow("Help ID - $ID"); 
      $Listings .= qq~<li><a href="/about/$ID/$Helps->{$ID}->{Url}/help_page.html">$Helps->{$ID}->{Name}</a></li>~;
   }
   return $Listings;
}

=head2 getHelpPage

Gets the help page content for the id passes

=over 4

=item B<Parameters :>

   1. $self - Reference to a HelpManager object

=item B<Returns :>

   1. $html - The html of the help page

=back

=cut

#############################################
sub getHelpPage {
#############################################
   my $self = shift;
   my $HelpID = shift;

   $self->{Debugger}->debug("in ListCentral::HelpManager::getHelpPage"); 

   my $HelpObj = $self->{DBManager}->getTableObj("Help");
   my $Help = $HelpObj->get_by_ID($HelpID);

   return ("<h3 class='TopH3'>List Central Help - $Help->{Name}</h3>$Help->{ContentHTML}", "List Central Help - $Help->{Name}");
}

=head2 GetHelpListingsAdmin

Gets the help listings for the help pages

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the help listing

=back

=cut

#############################################
sub GetHelpListingsAdmin {
#############################################
   my $self = shift;

   $self->{Debugger}->debugNow("in ListCentral::HelpManager::GetHelpListingsAdmin"); 

   my $HelpObj = $self->{DBManager}->getTableObj("Help");
   my $Helps = $HelpObj->get_all();

   my $PageGetter = new ListCentral::Admin::PageGetter(Debugger => $self->{Debugger});
   

   my $Listings = "";
   foreach my $ID(sort{$Helps->{$a}->{Ordering} <=> $Helps->{$b}->{Ordering}} keys %{$Helps}) {
      $self->{Debugger}->debugNow("Help ID - $ID"); 

      my %Data;
      $Data{"HelpID"} = $ID;
      $Data{"Name"} = $Helps->{$ID}->{Name};
      $Data{"Url"} = $Helps->{$ID}->{Url};
      $Data{"Ordering"} = $Helps->{$ID}->{Ordering};
      $Data{"ContentHTML"} = $Helps->{$ID}->{ContentHTML};

      $Listings .= $PageGetter->getBasicPage("$ListCentral::SETUP::ADMIN_DIR_PATH/edit_help.html", \%Data);

   }
   return $Listings;
}

1;

=head1 AUTHOR INFORMATION

   Author:  Brahmina Burgess
   Last Updated: 13/05/2009

=head1 BUGS

   Not known

=cut

