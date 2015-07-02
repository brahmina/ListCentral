package ListCentral::Admin::Handler;
  
use strict;

use DBI;

use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Const;
use Apache2::Request;
use Apache2::Upload;

use ListCentral::SETUP;
use ListCentral::Debugger;
use ListCentral::UserManager;
use ListCentral::Admin::Manager;
use ListCentral::Admin::Printer;
use ListCentral::DB::DBManager;

###################################
sub handler {
###################################
   my $r = shift;
      
   my $debug = $ListCentral::SETUP::DEBUG;
   my $Debugger = new ListCentral::Debugger(debug=>$debug, request=>$r);
   $Debugger->debug("in ListCentral::Admin::Handler"); 

   my $file_requested = $r->filename();
   if(! $r->is_initial_req){
      # Not the initial request... go away please
      return Apache2::Const::DECLINED;
   }

   my $IP = $ENV{'REMOTE_ADDR'};
   my $IPisPermitted = 0;
   foreach my $permittedIP(@ListCentral::SETUP::PERMITTED_IPS){
      if($IP eq $permittedIP){
         $IPisPermitted = 1;
      }
   }
   if(! $IPisPermitted){
      $Debugger->debug(" ListCentral::Admin::Handler"); 
      return Apache2::Const::DECLINED;
   }

   my $uri = $r->uri();
   # if its not an html file reject it -
   if(!$r->content_type() && !$file_requested =~ m/\.html$/){
      #$Debugger->debug("No content type??? r->uri()" . $r->uri()); 
      $r->content_type("text/html") unless $r->uri() =~ m/\.cur$/ || $r->uri() =~ m/\.ico$/;

      # Just Give it to them
      open(FILE,$r->filename);
      while (<FILE>) {
          print;
      }
      close FILE;
      return OK;
   }

   return Apache2::Const::DECLINED unless $file_requested =~ m/\.html$/;

   $Debugger->debug("r->uri()" . $r->uri());
   #$Debugger->debug("file_requested: $file_requested");
   #$Debugger->debug("r->finfo()" . $r->finfo());
   #$Debugger->debug("r->header_only()" . $r->header_only());
   #$Debugger->debug("r->headers_in()" . $r->headers_in());
   #$Debugger->debug("r->headers_out()" . $r->headers_out());
   #$Debugger->debug("r->notes()" . $r->notes());
   #$Debugger->debug("r->path_info()" . $r->path_info());
   #$Debugger->debug("r->status()" . $r->status());
   #$Debugger->debug("r->the_request()" . $r->the_request());
   #$Debugger->debug("r->unparsed_uri()" . $r->unparsed_uri());
   #$Debugger->debug("r->path_info()" . $r->path_info());
   #foreach my $key (sort keys(%ENV)) {
   #   $Debugger->debug( "ENV: $key = $ENV{$key}");
   #} 
   

   $Debugger->debug("file requested: $file_requested") unless $file_requested =~ m/\.js$/ || $file_requested =~ m/\.css/;

   my $dbh = DBI->connect($ListCentral::SETUP::DB,
                          $ListCentral::SETUP::USER_NAME,
                          $ListCentral::SETUP::PASSWORD);
   
   if (!$dbh) {
      $Debugger->log("Unable to connect to database $ListCentral::SETUP::DB");
      exit 1;
   }else{
      $Debugger->debug("Connected to $ListCentral::SETUP::DB database ");
   }

   ############ Instantiate Lists objects ##########################
   my $request = new Apache2::Request($r);
   my $cgi = parseParams($request);   

   foreach my $field(keys %{$cgi}) {
      $Debugger->debug("CGI: $field - $cgi->{$field}");
   }
   
   
   # Instantiate major objects   
   my $DBManager = new ListCentral::DB::DBManager(Debugger=>$Debugger, dbh=>$dbh);
    
   my $UserManager = new ListCentral::UserManager(Debugger=>$Debugger, dbh=>$dbh, DBManager=>$DBManager, 
                                                         Request=>$r, cgi=>$cgi);
   
   # Get any cookies and instantiate the user object
   my $Manager = new ListCentral::Admin::Manager(Debugger=>$Debugger, 
                                              dbh=>$dbh, cgi=>$cgi, Request=>$r,
                                              UserManager=>$UserManager, DBManager=>$DBManager);
   my $Printer = new ListCentral::Admin::Printer(cgi=>$cgi, Debugger=>$Debugger, dbh=>$dbh, 
                                           UserManager=>$UserManager, Manager=>$Manager);
   my $content =  $Manager->handleRequest($file_requested);

   $Printer->print_template($content, $file_requested);

   $dbh->disconnect();
  
   return OK;
}

#####################################
sub parseParams {
#####################################
   my $req = shift;

   use HTML::Entities;

   my %cgi;
   foreach my $param ($req->param()) {
      my $encoded = $req->param($param);
      my $decoded = decode_entities($encoded);

      $cgi{$param} = $decoded;     

      if($param =~ m/File$/ && $encoded ne ""){
         my $upload = $req->upload($param);

         print STDERR "\n\nUPLOAD: $upload ($param)\n\n";

         my $io = $upload->io();
         my $UploadedFile = "";
         my $count = 0;
         while (<$io>){
            $UploadedFile .= $_;
            $count++;
         }
         #my $FH = $upload->fh();
         $cgi{"Upload$param"} = $UploadedFile;
      }
   }

   return \%cgi;
}

1;

=head1 AUTHOR INFORMATION

   Author:  With help from the Lists
   Last Updated: 25/9/2008

=head1 BUGS

   Not known

=cut
