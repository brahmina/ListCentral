package ListCentral::Handler;
  
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
use ListCentral::ListsManager;
use ListCentral::Printer;
use ListCentral::DB::DBManager;
use ListCentral::Utilities::AdServer;

###################################
sub handler {
###################################
   my $r = shift;

   
   my $uri = $r->uri();
   my $request = new Apache2::Request($r);
   my $cgi = parseParams($request); 
   my $debug = $ListCentral::SETUP::DEBUG;
   my $Debugger = new ListCentral::Debugger(debug=>$debug, request=>$r, cgi => $cgi);

   my $file_requested = $r->filename();
   
   if(! $r->is_initial_req && ! $file_requested =~ /errors/){
      # Not the initial request... go away please
      return Apache2::Const::DECLINED;
   }

   if($cgi == 404){
      $Debugger->debug("Returning 404? $file_requested");
      return Apache2::Const::NOT_FOUND;
   }
   
   # This is where the SEO of the urls is handled
   if($uri =~ m'/tagged/(\w+)/(\d+)/(.+)\.html'){
      # Tag 
      my $tag = $1;
      $cgi->{"Tag"} = $tag;
      $cgi->{"TagID"} = $2;
      my $file = $3;
      $file_requested = $ListCentral::SETUP::DIR_PATH . "/" . $file . ".html";
      $r->content_type("text/html");
   }elsif($uri =~ m'/list/(\w+)/(.+)/(\d+)/(\d+)/(\w+)\.html'){
      # List
      my $group = $1;
      my $list = $2;
      $cgi->{UserID} = $3;
      $cgi->{ListID} = $4;
      $cgi->{ListDivDisplay} = "ListNormalView";
      my $file = $5;
      $file_requested = $ListCentral::SETUP::DIR_PATH . "/" . $file . ".html";
      $r->content_type("text/html");
   }elsif($uri =~ m'/user/(\w+)/(\d+)/(.+)\.html'){
      # List
      my $user = $1;
      $cgi->{UserID} = $2;

      my $file = $3;
      $file_requested = $ListCentral::SETUP::DIR_PATH . "/" . $file . ".html";
      if($cgi->{UserID} == $ListCentral::SETUP::ABOUT_USER_ACCOUNT){
         $file_requested = $ListCentral::SETUP::DIR_PATH . "/" . "about.html";
      }
      $r->content_type("text/html"); 
   }elsif($uri =~ m'/about/(\d+)/\w+/help_page.html'){
      # List
      $cgi->{HelpPageID} = $1;
      $file_requested = $ListCentral::SETUP::DIR_PATH . "/about/help_page.html";
      $r->content_type("text/html"); 
   }

   $Debugger->debug("file_requested: $file_requested");

   # if its not an html file reject it -
   if(!$r->content_type() && !$file_requested =~ m/\.html$/){
      $Debugger->debug("No content type??? r->uri()" . $r->uri()); 
      $r->content_type("text/html") unless $r->uri() =~ m/\.cur$/ || $r->uri() =~ m/\.ico$/;

      # Just Give it to them
      open(FILE,$r->filename);
      while (<FILE>) {
          print;
      }
      close FILE;
      return OK;
   }

   # Turn debug off if we are serving an custom error page
   if($file_requested =~ m/errors/){
      $Debugger->{debug} = 0;
   }  

   return Apache2::Const::DECLINED unless $r->content_type() eq "text/html" || $file_requested =~ m/\.html$/;   

   #$Debugger->debugNow("r->uri()" . $r->uri());
   #$Debugger->debugNow("file_requested: $file_requested");
   #$Debugger->debugNow("r->finfo()" . $r->finfo());
   #$Debugger->debugNow("r->header_only()" . $r->header_only());
   #$Debugger->debugNow("r->headers_in()" . $r->headers_in());
   #$Debugger->debugNow("r->headers_out()" . $r->headers_out());
   #$Debugger->debugNow("r->notes()" . $r->notes());
   #$Debugger->debugNow("r->path_info()" . $r->path_info());
   #$Debugger->debugNow("r->status()" . $r->status());
   #$Debugger->debugNow("r->the_request()" . $r->the_request());
   #$Debugger->debugNow("r->unparsed_uri()" . $r->unparsed_uri());
   #$Debugger->debugNow("r->path_info()" . $r->path_info());
   #foreach my $key (sort keys(%ENV)) {
   #   $Debugger->debugNow( "ENV: $key = $ENV{$key}");
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

   # Handles the paging of the various listing
   if($file_requested =~ m/\/(popular|new|active|page)(\d*)\.html/){
      my $WhichListings = $1;
      $cgi->{WhichListings} = $WhichListings;
      if($cgi->{WhichListings} eq "page"){
         $cgi->{WhichListings} = "popular";
      }
      my $page = $2;
      $cgi->{page} = $page;
      if(!$cgi->{page}){
         $cgi->{page} = 1;
      }
      $file_requested =~ s/$WhichListings$page/popular/;
   }elsif($file_requested =~ m/tag(\d+)\.html/){
      $cgi->{page} = $1;
      my $fakePage = "tag" . $cgi->{page} . ".html"; 
      $file_requested =~ s/$fakePage/tag\.html/;
   }elsif($file_requested =~ m/search(\d+)\.html/){
      $cgi->{page} = $1;
      my $fakePage = "search" . $cgi->{page} . ".html"; 
      $file_requested =~ s/$fakePage/search\.html/;
   }

   ############ Instantiate Lists objects #########################    

   # Instantiate major objects   
   my $DBManager = new ListCentral::DB::DBManager(Debugger=>$Debugger, dbh=>$dbh);
    
   my $UserManager = new ListCentral::UserManager(Debugger=>$Debugger, DBManager=>$DBManager, 
                                                         Request=>$r, cgi=>$cgi);
   $Debugger->{UserManager} = $UserManager;
   my $AdServer = new ListCentral::Utilities::AdServer(Debugger=>$Debugger, DBManager=>$DBManager, Request=>$r,);

   # Get any cookies and instantiate the user object
   my $ListsManager = new ListCentral::ListsManager(Debugger=>$Debugger, 
                                              cgi=>$cgi, Request=>$r, AdServer => $AdServer,
                                              UserManager=>$UserManager, DBManager=>$DBManager);
   my $Printer = new ListCentral::Printer(cgi=>$cgi, Debugger=>$Debugger, dbh=>$dbh, 
                                    UserManager=>$UserManager, ListManager=>$ListsManager);
   my $content =  $ListsManager->handleRequest($file_requested);

   #$Debugger->debug("CONTENT: \n$content");

   my $IP = $ENV{'REMOTE_ADDR'};
   my $OneOfMyIPS = 0;
   foreach my $permittedIP(@ListCentral::SETUP::PERMITTED_IPS){
      if($IP eq $permittedIP){
         $OneOfMyIPS = 1;
      }
   }
   if(! $OneOfMyIPS){
      my $Hitlog = $DBManager->getTableObj("Hitlog");
      $Hitlog->storeHitlogEntry($UserManager->{ThisUser}->{ID});
   }

   my $Referrer = $ENV{HTTP_REFERER};
   if($Referrer !~ m/$ListCentral::SETUP::URL/ && $Referrer !~ m/$ListCentral::SETUP::URL2/){
      if($Referrer =~ m/http:\/\/([\w\.]+)\//){
         $Referrer = $1;
         my $ReferrersObj = $DBManager->getTableObj("Referrers");
         $ReferrersObj->saveReferrer($Referrer);
      }
   }

   if($cgi->{ajax}){
      print $content;
   }else{
      $Printer->print_template($content, $file_requested);
   }

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

      if($param =~ m/ID/){
         if($decoded =~ m/\D+/){
            # TODO - Error handle unexpected input
            # If this is happening, we likely have some sort of malicious request
            # Throw notifying error and send to 500 ?
            return 404;
         }
      }

      $cgi{$param} = $decoded;     

      if($param =~ m/File$/ && $encoded ne ""){
         my $upload = $req->upload($param);

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

   if($req->filename() =~ m/page(\d+)\.html/){
      $cgi{"page"} = $1;
   }

   return \%cgi;
}

1;

=head1 AUTHOR INFORMATION

   Author:  With help from the Lists
   Last Updated: 21/1/2008

=head1 BUGS

   Not known

=cut
