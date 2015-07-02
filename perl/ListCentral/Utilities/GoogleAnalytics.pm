package ListCentral::Utilities::GoogleAnalytics;
use strict;

use ListCentral::SETUP;

##########################################################
# ListCentral::GoogleAnalytics 
##########################################################

=head1 NAME

   ListCentral::Utilities::GoogleAnalytics.pm

=head1 SYNOPSIS

   $GoogleAnalyticsCode = ListCentral::Utilities::GoogleAnalytics::getCode();

=head1 DESCRIPTION

Used to place google analytic tracting information on the site pages

=head2 getCode

Returns the code to print 

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object

=item B<Return :>

   1. $code - The Google Analytics code

=back

=cut

#############################################
sub getCode {
#############################################
   my $self = shift;

   my $googleTracking = $ListCentral::SETUP::GOOGLE_ANALYTICS_CODE;
   #ListCentral.me UA-5860552-4
   my $googleAnalyticsCode = qq~
<script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
try {
var pageTracker = _gat._getTracker("$googleTracking");
pageTracker._trackPageview();
} catch(err) {}</script>~;

   return $googleAnalyticsCode;
}
1;

=head1 AUTHOR INFORMATION

   Author:  With help from the ApplicationFramework
   Last Updated: 22/10/2007

=head1 BUGS

   Not known

=cut

