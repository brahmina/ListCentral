package ListCentral::Utilities::DataToHTML;

use strict;
use ListCentral::SETUP;

##########################################################
# ListCentral::Utilities::DataToHTML NOT USED
##########################################################

=head1 NAME

    ListCentral::Utilities::DataToHTML.pm

=head1 SYNOPSIS

   ListCentral::Utilities::DataToHTML::fuction();

=head1 DESCRIPTION

Contains handy data to html functions

=head2 basicHashToHTML

Given a hash of the form:

   $hash->{UniqueID}->{Field 1} = Value 1

Returns HTML table with the Fields being a header row

=over 4

=item B<Parameters :>

   1. $self - Reference to a DataToHTML object
   2. $hash - Reference to the hash data
   3. $class - The css class
   4. $orderBy - The column to order by, omitted at user's risk

=item B<Returns :>

   1. $html - the html

=back

=cut

#############################################
sub basicHashToHTML {
#############################################
   my $self = shift;
   my $hash = shift;
   my $class = shift;
   my $orderBy = shift;

   my $headerClass = $class . "Header";
   my $dataClass = $class . "Data";

   if(!$orderBy){
      $orderBy = "ID";
   }

   my $sortFunc; my $count = 0;
   foreach my $ID (sort keys %{$hash}) {
      my $value = $hash->{$ID}->{$orderBy};
      if($value =~ m/^\d+$/){
         $sortFunc = {$hash->{$a}->{$orderBy} <=> $hash->{$b}->{$orderBy}};
         if($count == 5){
            next;
         }
         $count++;
      }else{
         $sortFunc = {$hash->{$a}->{$orderBy} cmp $hash->{$b}->{$orderBy}};
         next;
      }
   }

   my $header = "<tr>";
   my $rows = ""; $count = 0;
   foreach my $ID (sort $sortFunc keys %{$hash}) {
      
      $rows .= "<tr>";
      my $sortFuncFields;
      if($hash->{$ID}->{$a}->{DTHOrder}){
         $sortFuncFields = {$hash->{$ID}->{$a}->{DTHOrder} cmp $hash->{$ID}->{$b}->{DTHOrder};
      }
      foreach my $field(sort $sortFuncFields keys %{$hash->{$ID}} ) {
         if($count == 0){
            $header .= qq~<td class="$headerClass">$field</td>~;

            $rows .= qq~<td class="$dataClass">$hash->{$ID}->{$field}</td>~;
         }
      }
      $rows .= "</tr>";
      $count++;
   }
   $header .= "<\tr>";

   my $html = qq~<table class="$class">
                     $header
                     $rows
                  </table>
               ~;

   return $html;

}



sub hashToHTML {

   $hash->{ColumsHeaders}->{field1}     ----    order by links
                         ->{field2}    |
                         ->{fieldn}    |

        ->{RowHeaders}->{field1}
                      ->{field2}
                      ->{fieldn}

        ->{Row1}->{Col1}
                ->{Col2}
                ->{Coln}



}

1;
