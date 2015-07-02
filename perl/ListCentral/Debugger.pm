package ListCentral::Debugger;
use strict;

use ListCentral::SETUP;

##########################################################
# ListCentral::Debugger 
##########################################################

=head1 NAME

   ListCentral::Debugger.pm

=head1 SYNOPSIS

   $Mailer = new Debugger(debug);

=head1 DESCRIPTION

Used to debug and log activites in the Lists system

=head2 ListCentral::Debugger Constructor

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

   #$self->debug("In ListCentral::Debugger constructor");

   $self->{DebugMessages} = "";
   
   return ($self); 
}

=head2 log

Prints the log message passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a <--DatabaseName--> object
   2. $msg - the debug message to be passed

=item B<Prints :>

   1. the debug message with a <br> at the end

=back

=cut

#############################################
sub log {
#############################################
   my $self = shift;
   my $msg = shift;

   my ($package, $filename, $line) = caller();
   my $date = localtime();

   if($msg =~ m/ERROR/){
      $msg =~ s/ERROR/<b>ERROR<\/b>/;
   }

   my $log_file = $ApplicationFramework::SETUP::LOG_FILE;
   open LOG_FILE, ">$log_file" || die "Error: Cannot open $log_file for writing - $!\n";
   print LOG_FILE "[$package, $line ($date)] $msg\n";
   close LOG_FILE;

   if($self->{debug}){
      my ($package, $filename, $line) = caller();
      my $date = localtime();
      $self->{DebugMessages} .= "[$package, $line, ($date), $ENV{REMOTE_ADDR}] $msg<br>";
   }
}

=head2 debug

Prints the debug message passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a <--DatabaseName--> object
   2. $msg - the debug message to be passed

=item B<Prints :>

   1. the debug message with a <br> at the end

=back

=cut

#############################################
sub debug {
#############################################
   my $self = shift;
   my $msg = shift;

   #use Apache::Debug ();
   #my $apachemsg = Apache::Debug::dump($r, SERVER_ERROR, "Uh Oh!");

   if($self->{debug} == 1){
      my ($package, $filename, $line) = caller();
      my $date = localtime();
      $self->{DebugMessages} .= "[$package, $line, $ENV{REMOTE_ADDR}] $msg<br>";
   }elsif($self->{debug} == 2 && $msg =~ m/<b>/){
      my ($package, $filename, $line) = caller();
      my $date = localtime();
      $self->{DebugMessages} .= "[$package, $line, $ENV{REMOTE_ADDR}] $msg<br>";
   }elsif($self->{debug} == 3){ # AJAX
      my ($package, $filename, $line) = caller();
      my $date = localtime();
      #print STDERR "[$package, $line] $msg\n";
      print STDERR "[$package, $line, $ENV{REMOTE_ADDR}] $msg\n";
   }elsif($self->{debug} == 4){ # Command line
      my ($package, $filename, $line) = caller();
      my $date = localtime();
      #print STDERR "[$package, $line] $msg\n";
      print "[$package, $line] $msg\n";
   }
}

=head2 debugNow

Prints the debug message passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a <--DatabaseName--> object
   2. $msg - the debug message to be passed

=item B<Prints :>

   1. the debug message with a <br> at the end

=back

=cut

#############################################
sub debugNow {
#############################################
   my $self = shift;
   my $msg = shift;

   my ($package, $filename, $line) = caller();
   my $date = localtime();
   if($self->{request}){
      print STDERR "[$package, $line, $ENV{REMOTE_ADDR}] $msg\n" unless $self->{request}->filename =~ m/404/;
   }else{
      print STDERR "[$package, $line, $ENV{REMOTE_ADDR}] $msg\n";
   }
   
}

=head2 error

Prints the debug message passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a <--DatabaseName--> object
   2. $msg - the debug message to be passed

=item B<Prints :>

   1. the debug message with a <br> at the end

=back

=cut

#############################################
sub error {
#############################################
   my $self = shift;
   my $msg = shift;

   my ($package, $filename, $line) = caller();
   my $date = localtime();
   print STDERR "[$package, $line, ($date), $ENV{REMOTE_ADDR}] ERROR: $msg\n";
}

=head2 throwNotifyingError

Prints the debug message passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a <--DatabaseName--> object
   2. $msg - the debug message to be passed

=item B<Prints :>

   1. the debug message with a <br> at the end

=back

=cut

#############################################
sub throwNotifyingError {
#############################################
   my $self = shift;
   my $msg = shift;

   my ($package, $filename, $line) = caller();
   my $date = localtime();
   my $err = "[$package, $line, ($date), $ENV{REMOTE_ADDR}] $msg\nDefault error: $!\n";
   $self->debugNow($err);

   my $extra = "Error: $err\n\nRequest: \n";
   if($self->{request}){
      $extra .= "r->filename: " . $self->{request}->filename ."\n";
      $extra .= "r->header_only(): " . $self->{request}->header_only() ."\n";
      $extra .= "r->status(): " . $self->{request}->status() ."\n";
      $extra .= "r->the_request(): " . $self->{request}->the_request() ."\n";
   }

   $extra .= "\nUser: $self->{UserManager}->{ThisUser}->{ID}, $self->{UserManager}->{ThisUser}->{Username}\n";

   $extra .= "\nCGI:\n";
   foreach my $k(keys %{$self->{cgi}}) {
      $extra .= "$k -> $self->{cgi}->{$k}\n";
   }

   $extra .= "\nENV:\n";
   foreach my $key (sort keys(%ENV)) {
      $extra .=  "$key = $ENV{$key}\n";
   }

   use ListCentral::Utilities::Mailer;
   my $Mailer = new ListCentral::Utilities::Mailer(Debugger=>$self);
   $Mailer->sendEmailToIT("Error $ListCentral::SETUP::DB_NAME in $package", "[$package, $line, ($date), $ENV{REMOTE_ADDR}]\n\n$msg\n\n$extra");
}

1;

=head1 AUTHOR INFORMATION

   Author:  With help from the ProjectAssistant
   Last Updated: 21/1/2008

=head1 BUGS

   Not known

=cut

