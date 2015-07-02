package Lists::DB::TableObject;

use strict;


use Lists::SETUP;
use Lists::Utilities::StringFormator;

##########################################################
# Lists::DB::TableObject 
##########################################################

=head1 NAME

   Lists::DB::TableObject.pm

=head1 SYNOPSIS

   $TableObject = new Lists::DB::TableObject($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the TableObject table in the 
Lists database.

=head2 Lists::DB::TableObject Constructor

=over 4

=item B<Parameters :>

   1. $dbh
   3. $debug

=back

=cut

########################################################
sub new {
########################################################
   my $classname = shift; 
   my $self; 
   %$self = @_; 
   bless $self, ref($classname)||$classname;

   if(!$self->{dbh}){
      die "Where is $classname's dbh??";
   }

   $self->{Table} = $classname;

   my $package_name = $Lists::SETUP::PACKAGE_NAME . "::DB::";
   $self->{Table} =~ s/$package_name//;

   $self->{Debugger}->debug("Constructing! $classname -> $self->{Table}");

   $self->init();

   if(!$self->{StatusField}){
      $self->{StatusField} = "Status";
   }

   return ($self); 
}

=head2 store

Stores a new Comment in the db

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::DB::TableObject object
   2. $TableObject - Reference to a hash with complete Comment data

=item B<Prints :>

   1. $ID - the ID of the new TableObj stored, returns 0 if the insert was unsuccessful

=back

=cut

#############################################
sub store {
#############################################
   my $self = shift;
   my $cgi = shift;

   $self->{Debugger}->debugNow("in Lists::DB::$self->{Table}::store with");

   my $TableObj_hash_ref;
   foreach my $field (keys %{$cgi}) {
      if($field =~ m/$self->{Table}\.(\w+)/){

         my $tableField = $1;
         my $value = $cgi->{$field};

         $value =~ s/"/\\\"/g;

         $TableObj_hash_ref->{$tableField} = $value;

         $self->{Debugger}->debug(" --> $tableField:  $value");
      }
   }

   # Fill in dates with epoch for now
   if($self->{DateFields}){
      my $time = time();
      foreach my $dateField( @{$self->{DateFields}}){
         if(! $TableObj_hash_ref->{$dateField}){
            $TableObj_hash_ref->{$dateField} = $time;
         }         
      }
   }

   if($self->{HTMLFields}){
      foreach my $htmlField( @{$self->{HTMLFields}}){
          
         my $badHTML = Lists::Utilities::StringFormator::hasBadHTML($TableObj_hash_ref->{$htmlField});
         if($badHTML == 1){
            return $Lists::SETUP::MESSAGES{'UNPERMITTED_HTML'};
         }elsif($badHTML ne ""){
            $TableObj_hash_ref->{$htmlField} .= $badHTML;
         }
      }
   }

   $TableObj_hash_ref->{IP} = $ENV{'REMOTE_ADDR'};

   # TODO - Make spam catcher work!
   #      - Put in update aswell
   # Any spam filtering on the comment should be done here
   #if($self->{SpamFields}){
   #   use Lists::Utilities::SpamCatcher;
   #   my $SpamCatcher = new Lists::Utilities::SpamCatcher(Debugger => $self->{Debugger});
   #   foreach my $spanField( @{$self->{DateFields}}){
   #       if($SpamCatcher->isSpam($TableObj_hash_ref->{$spanField})){
   #          return;
   #       }
   #   }
   #}

   my $first = 1; 
   my $fields = ""; 
   my $values = "";
   my $sql_insert = "INSERT INTO $self->{Table} (";
   foreach my $field (@{$self->{Fields}}){
      if($first != 1){
         $sql_insert .= ", ";
         $values .= ", ";
      }
      $first = 0;
      $sql_insert .= "$field";
      $values .= "\"$TableObj_hash_ref->{$field}\"";
   }
   $sql_insert .= ") VALUES ($values);";

   $self->{Debugger}->debug("$sql_insert");

   # The Commenter is the username of the throwNotifyingErrorged in user, or the name entered by the guest
   my $stm = $self->{dbh}->prepare($sql_insert);
   if ($stm->execute()){
      # Success!
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with $self->{Table} DB insert::: $sql_insert");
      return $Lists::SETUP::MESSAGES{'INSERT_ERROR'};; 
   }
   my $ID = $stm->{mysql_insertid};

   $stm->finish();

   $self->{GotAll} = 0;

   return $ID;
}

=head2 get_by_ID

Gets the TableObject entry corresponding the the ID passed and returns a reference to a hash containing
the TableObject information 

=over 4

=item B<Parameters :>

   1. $self - Reference to a TableObject object
   2. $ID - The TableObject id

=item B<Returns: >

   1. $TableObject - Reference to a hash with the TableObject data

=back

=cut

#############################################
sub get_by_ID {
#############################################
   my $self = shift;
   my $ID = shift;

   $self->{Debugger}->debug("in Lists::DB::$self->{Table}::get_by_ID with $ID");

   if($self->{Cache}->{$ID}){
      return $self->{Cache}->{$ID};
   }

   my $dates = "";
   if($self->{DateField}){
      $dates = ", from_unixtime($self->{DateField}) as $self->{DateField}Fomatted ";
   }

   my $TableObject;
   my $sql_select = "SELECT *$dates
                     FROM $Lists::SETUP::DB_NAME.$self->{Table} 
                     WHERE ID = $ID
                           AND $self->{StatusField} > 0";
   $self->{Debugger}->debug("$sql_select");
   my $stm = $self->{dbh}->prepare($sql_select);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $TableObject = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with $self->{Table}  SELECT: $sql_select - $DBI::errstr");
   }
   $stm->finish;

   $self->{Cache}->{$ID} = $TableObject;

   return $TableObject;
}

=head2 get_by_field

Gets the TableObject entry corresponding the field and value passed and returns a reference to a hash containing
the TableObject information  - assumes that the value of field is unique to the entry, like username

=over 4

=item B<Parameters :>

   1. $self - Reference to a TableObject object
   2. $field - the field
   3. $value - the value

=item B<Returns: >

   1. $TableObject - Reference to a hash with the TableObject data

=back

=cut

#############################################
sub get_by_field {
#############################################
   my $self = shift;
   my $field = shift;
   my $value = shift;

   $self->{Debugger}->debug("in Lists::DB::TableObject::get_by_field with $field, $value");

   my $dates = "";
   if($self->{DateField}){
      $dates = ", from_unixtime($self->{DateField}) as $self->{DateField}Fomatted ";
   }

   my $TableObject;
   my $sql_select = "SELECT *$dates 
                     FROM $Lists::SETUP::DB_NAME.$self->{Table}  
                     WHERE $field = \"$value\"
                           AND $self->{StatusField} > 0";

   my $stm = $self->{dbh}->prepare($sql_select);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $TableObject = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with $self->{Table} SELECT: $sql_select - $DBI::errstr");
   }
   $stm->finish;

   return $TableObject;
}

=head2 get_field_by_ID

Get a TableObject field entry corresponding the the ID, and field name(s) passed and returns a reference to a 
hash containing the TableObject information 

=over 4

=item B<Parameters :>

   1. $self - Reference to a TableObject object
   2. $field - The field name(s), comma separated, to use
   3. $ID - The TableObject id

=item B<Returns: >

   1. $TableObject - Reference to a hash with the TableObject data

=back

=cut

#############################################
sub get_field_by_ID {
#############################################
   my $self = shift;
   my $field = shift;
   my $ID = shift;

   $self->{Debugger}->debug("in Lists::DB::$self->{Table}::get_field_by_ID with $field, $ID");

   if($self->{Cache}->{$ID}->{$field}){
      return $self->{Cache}->{$ID}->{$field};
   }

   my $result;
   my $sql = "SELECT $field FROM $Lists::SETUP::DB_NAME.$self->{Table} WHERE ID = $ID AND $self->{StatusField} > 0";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $result = $hash->{$field};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with $self->{Table} SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   return $result;
}

=head2 get_with_restraints

Get TableObject entries resulting from the select performed using the where clause passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a TableObject object
   2. $where_clause - the where clause to be used on select, starting with "WHERE "

=item B<Returns: >

   1. $TableObject - Reference to a hash with the TableObject data

=back

=cut

#############################################
sub get_with_restraints {
#############################################
   my $self = shift;
   my $where_clause = shift;
   my $orderBy = shift;
   my $limit = shift;

   $self->{Debugger}->debug("in Lists::DB::$self->{Table}::get_with_restraints with $where_clause");

   if($orderBy){
      $orderBy = "ORDER BY $orderBy";
   }else{
      $orderBy = "";
   }
   if($limit){
      $limit = "LIMIT $limit";
   }else{
      $limit = "";
   }

   my %TableObject; my $SortOrder = 0;
   my $sql = "SELECT * FROM $Lists::SETUP::DB_NAME.$self->{Table} WHERE $where_clause AND $self->{StatusField} > 0 $orderBy $limit";
   $self->{Debugger}->debug("get_with_restraints sql: $sql");
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $TableObject{$hash->{ID}} = $hash;

         if($orderBy){
            $TableObject{$hash->{ID}}->{SortOrder} = $SortOrder;
            $SortOrder++;
         }
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with $self->{Table} SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   return \%TableObject;
}

=head2 get_all

Get TableObject entries resulting from the select performed using the where clause passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a TableObject object

=item B<Returns: >

   1. $TableObject - Reference to a hash with the TableObject data

=back

=cut

#############################################
sub get_all {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::TableObject::get_all");

   if($self->{GotAll}){
      return $self->{Cache};
   }

   my %TableObject;
   my $sql = "SELECT * FROM $Lists::SETUP::DB_NAME.$self->{Table} WHERE $self->{StatusField} > 0";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $TableObject{$hash->{ID}} = $hash;

         $self->{Cache}->{$hash->{ID}} = $TableObject{$hash->{ID}};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with $self->{Table} SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   $self->{GotAll} = 1;
   return \%TableObject;
}


=head2 get_count

Gets TableObject table Count - total number of enties in the TableObject table

=over 4

=item B<Parameters :>

   1. $self - Reference to a TableObject object

=item B<Returns: >

   1. $count - the number of entires in the TableObject table

=back

=cut

#############################################
sub get_count {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::TableObject::get_count");

   my $count;
   my $sql = "SELECT COUNT(ID) AS Count FROM $Lists::SETUP::DB_NAME.$self->{Table} WHERE $self->{StatusField} > 0";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $count = $hash->{Count};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with $self->{Table} COUNT: $sql\n");
   }
   $stm->finish;

   return $count;
}

=head2 get_count_with_restraints

Gets the number of entries in the TableObject table corresponding to the where clause passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a TableObject object
   2. $where_clause - the where clause to be used on select, starting with 

=item B<Returns: >

   1. $count - the number of entires in the TableObject tablea

=back

=cut

#############################################
sub get_count_with_restraints {
#############################################
   my $self = shift;
   my $where_clause = shift;

   $self->{Debugger}->debug("in Lists::DB::TableObject::get_count_with_restraints");

   my $count;
   my $sql = "SELECT COUNT(ID) AS Count FROM $Lists::SETUP::DB_NAME.$self->{Table} WHERE $where_clause AND $self->{StatusField} > 0";
   $self->{Debugger}->debug($sql);
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $count = $hash->{Count};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with $self->{Table} COUNT: $sql\n");
   }
   $stm->finish;

   return $count;
}

=head2 get_distinct_field_count

Gets TableObject table Count - total number of enties in the TableObject table

=over 4

=item B<Parameters :>

   1. $self - Reference to a TableObject object
   2. $field - The field you want to count the unique entries of

=item B<Returns: >

   1. $count - the number of entires in the TableObject table

=back

=cut

#############################################
sub get_distinct_field_count {
#############################################
   my $self = shift;
   my $field = shift;

   $self->{Debugger}->debug("in Lists::DB::TableObject::get_distinct_field_count");

   my $count;
   my $sql = "SELECT COUNT(DISTINCT($field)) AS Count FROM $Lists::SETUP::DB_NAME.$self->{Table} WHERE $self->{StatusField} > 0";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $count = $hash->{Count};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with $self->{Table} COUNT: $sql\n");
   }
   $stm->finish;

   return $count;
}

=head2 get_distinct_field_count_with_restraints

Gets the number of entries in the TableObject table corresponding to the where clause passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a TableObject object
   2. $field - The field you want to count the unique entries of
   3. $where_clause - the where clause to be used on select, starting with 

=item B<Returns: >

   1. $count - the number of entires in the TableObject tablea

=back

=cut

#############################################
sub get_distinct_field_count_with_restraints {
#############################################
   my $self = shift;
   my $field = shift;
   my $where_clause = shift;

   $self->{Debugger}->debug("in Lists::DB::$self->{Table}::get_distinct_field_count_from_with_restraints");

   my $count;
   my $sql = "SELECT COUNT(ID) AS Count FROM $Lists::SETUP::DB_NAME.$self->{Table} WHERE $where_clause AND $self->{StatusField} > 0";
   $self->{Debugger}->debug($sql);
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $count = $hash->{Count};
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with $self->{Table} COUNT: $sql\n");
   }
   $stm->finish;

   return $count;
}

=head2 delete

Get TableObject entries resulting from the select performed using the where clause pased

=over 4

=item B<Parameters :>

   1. $self - Reference to a TableObject object
   2. $ID - the ID of the TableObject to be deleted

=back

=cut

#############################################
sub delete {
#############################################
   my $self = shift;
   my $ID = shift;

   $self->{Debugger}->debug("in Lists::DB::TableObject::delete with $ID");

   my $sql = "DELETE FROM $Lists::SETUP::DB_NAME.$self->{Table} WHERE ID = $ID";
   my $stm = $self->{dbh}->prepare($sql);
   if ($self->{dbh}->do($sql)) {
      # Good Stuff
   }else {
      $self->{Debugger}->throwNotifyingError("ERROR: with $self->{Table} DELETE::: $sql\n");
   }
}

=head2 update

Get TableObject entries resulting from the select performed using the where clause pased

=over 4

=item B<Parameters :>

   1. $self - Reference to a TableObject object
   2. $field - Field name to be updated
   3. $value - the value to update the field to
   4. $ID - the ID of the TableObject to be updated

=back

=cut

#############################################
sub update {
#############################################
   my $self = shift;
   my $field = shift;
   my $value = shift;
   my $ID = shift;

   $self->{Debugger}->debug("in Lists::DB::$self->{Table}::update with $field, $value, $ID");

   $value =~ s/"/\\"/g;

   if($self->{HTMLFields}){
      foreach my $htmlField( @{$self->{HTMPFields}}){

         if($htmlField eq $field){
            my $badHTML = Lists::Utilities::StringFormator::hasBadHTML($value);
            if($badHTML == 1){
               return $Lists::SETUP::MESSAGES{'UNPERMITTED_HTML'};
            }elsif($badHTML ne ""){
               $value .= $badHTML;
            }
         }
      }
   }

   my $sql = "UPDATE $Lists::SETUP::DB_NAME.$self->{Table} SET $field = \"$value\" WHERE ID = $ID";
   my $stm = $self->{dbh}->prepare($sql);
   if ($self->{dbh}->do($sql)) {
      # Good Stuff
   }else {
      $self->{Debugger}->throwNotifyingError("ERROR: with $self->{Table} UPDATE::: $sql\n");
   }

   $self->{Cache}->{$ID} = undef;
   $self->{GotAll} = 0;
}

=head2 runSQLSelect

Runs a selete statement

=over 4

=item B<Parameters :>

   1. $self - Reference to a Area object
   2. $Query - the query

=item B<Returns :>

   1. $ResultsHash - Reference to the results hash

=back

=cut

#############################################
sub runSQLSelect {
#############################################
   my $self = shift;
   my $sql = shift;
   my $count = shift;
   my $results = shift;

   $self->{Debugger}->debug("in Lists::Utilities::Search::runSQLSelect with $sql");

   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         if(!$results->{$hash->{ID}}){
            $results->{$hash->{ID}} = $hash;
            $results->{$hash->{ID}}->{SearchOrder} = $count;
            $count++;
         }
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   return $count;
}

=head2 clearCache

Clears this object cache

=over 4

=item B<Parameters :>

   1. $self - Reference to a TableObject object

=back

=cut

#############################################
sub clearCache {
#############################################
   my $self = shift;
   my $ID = shift;

   if($ID){
      $self->{Cache}->{$ID} = undef;
   }else{
      $self->{Cache} = undef;
   }
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


