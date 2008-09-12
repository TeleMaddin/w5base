package kernel::Field::TextDrop;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
use strict;
use vars qw(@ISA);
use Data::Dumper;
use kernel;
@ISA    = qw(kernel::Field);


sub new
{
   my $type=shift;
   my $self=bless($type->SUPER::new(@_),$type);
   $self->{AllowEmpty}=0 if (!defined($self->{AllowEmpty}));
   if (!defined($self->{depend}) && defined($self->{vjoinon})){
      $self->{depend}=[$self->{vjoinon}->[0]]; # if there is a vjoin, we must
   }                         # be sure, to select the local criteria
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $currentstate=shift;   # current state of write record
   my $comprec=shift;        # values vor History Handling
   my $name=$self->Name();
   return({}) if (!exists($newrec->{$name}));
   my $newval=$newrec->{$name};
   my $filter={$self->{vjoindisp}=>'"'.$newval.'"'};

   $self->FieldCache->{LastDrop}=undef;

   if (defined($self->{vjoinbase})){
      $self->vjoinobj->SetNamedFilter("BASE",$self->{vjoinbase});
   }
   if (defined($self->{vjoineditbase})){
      $self->vjoinobj->SetNamedFilter("EDITBASE",$self->{vjoineditbase});
   }
   $self->vjoinobj->SetFilter($filter);
   my %param=(AllowEmpty=>$self->{AllowEmpty});
   my $fromquery=Query->Param("Formated_$name");
   if (defined($fromquery)){
      $param{Add}=[{key=>$fromquery,val=>$fromquery}];
      $param{selected}=$fromquery;
   }
   my ($dropbox,$keylist,$vallist)=$self->vjoinobj->getHtmlSelect(
                                                  "Formated_$name",
                                                  $self->{vjoindisp},
                                                  [$self->{vjoindisp}],%param);
   if ($#{$keylist}<0 && $fromquery ne ""){
      $filter={$self->{vjoindisp}=>'"*'.$newval.'*"'};
      $self->vjoinobj->ResetFilter();
      $self->vjoinobj->SetFilter($filter);
      ($dropbox,$keylist,$vallist)=$self->vjoinobj->getHtmlSelect(
                                                  "Formated_$name",
                                                  $self->{vjoindisp},
                                                  [$self->{vjoindisp}],%param);
   }
   if ($#{$keylist}>0){
      $self->FieldCache->{LastDrop}=$dropbox;
      $self->getParent->LastMsg(ERROR,"'%s' value '%s' is not unique",
                                      $self->Label,$newval);
      return(undef);
   }
   if ($#{$keylist}<0 && ((defined($fromquery) && $fromquery ne "") ||
                          (defined($newrec->{$name}) && 
                           $newrec->{$name} ne $oldrec->{$name}))){
      if ($newrec->{$name} eq "" && $self->{AllowEmpty}){
         return({$self->{vjoinon}->[0]=>undef});
      }
      $self->getParent->LastMsg(ERROR,"'%s' value '%s' not found",$self->Label,
                                      $newval);
      return(undef);
   }
   Query->Param("Formated_".$name=>$vallist->[0]);
   if (defined($comprec) && ref($comprec) eq "HASH"){
      $comprec->{$name}=$vallist->[0];
   }
   my $result={$self->{vjoinon}->[0]=>
           $self->vjoinobj->getVal($self->vjoinobj->IdField->Name(),$filter)};
   if (defined($self->{altnamestore})){
      $result->{$self->{altnamestore}}=$vallist->[0];      
   }
   return($result);
}

sub ViewProcessor
{
   my $self=shift;
   my $mode=shift;
   my $refid=shift;
   if ($mode eq "XML" && $refid ne ""){
      my $response={document=>{}};

      my $obj=$self->getParent();
      my $idfield=$obj->IdField();
      if (defined($idfield)){
         $obj->ResetFilter();
         $obj->SetFilter({$idfield->Name()=>\$refid});
         my ($rec,$msg)=$obj->getOnlyFirst(qw(ALL));
         my $fo=$obj->getField($self->Name(),$rec);
         if (defined($fo) && defined($rec)){
            my $d=$fo->RawValue($rec);
            $d=[$d] if (ref($d) ne "ARRAY");
            $response->{document}->{value}=$d;
         }
         else{
            $response->{document}->{value}="";
         }
      }
      print $self->getParent->HttpHeader("text/xml");
      print hash2xml($response,{header=>1});
      msg(INFO,hash2xml($response,{header=>1}));
      return;
   }
   return;
}


sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $mode=shift;
   if ($self->{async} && $mode eq "HtmlDetail"){
      my $idfield=$self->getParent->IdField();
      if (defined($idfield)){
         my $id=$idfield->RawValue($current);
         my $divid="ViewProcessor_$self->{name}";
         my $XMLUrl="$ENV{SCRIPT_URI}";
         $XMLUrl.="/../ViewProcessor/XML/$self->{name}/$id";
         my $d="<div id=\"$divid\"><font color=silver>init ...</font></div>";
         $d=$self->addWebLinkToFacility($d,$current);
         return(<<EOF);
$d
<script language="JavaScript">
function onLoadViewProcessor_$self->{name}(timedout)
{
   var ResContainer=document.getElementById("$divid");
   if (ResContainer && timedout==1){
      ResContainer.innerHTML="ERROR: XML request timed out";
      return;
   }
   // window.setTimeout("onLoadViewProcessor_$self->{name}(1);",10000);
   // timeout handling ist noch bugy!
   var xmlhttp=getXMLHttpRequest();
   xmlhttp.open("POST","$XMLUrl",true);
   xmlhttp.onreadystatechange=function() {
      var r=document.getElementById("$divid");
      if (r){
         if (xmlhttp.readyState<4){
            var t="<font color=silver>Loading ...</font>";
            if (r.innerHTML!=t){
               r.innerHTML=t;
            }
         }
         if (xmlhttp.readyState==4 && 
             (xmlhttp.status==200||xmlhttp.status==304)){
            var xmlobject = xmlhttp.responseXML;
            var result=xmlobject.getElementsByTagName("value");
            if (result){
               r.innerHTML="";
               for(rid=0;rid<result.length;rid++){
                  if (r.innerHTML!=""){
                     r.innerHTML+=", ";
                  }
                  if (result[rid].childNodes[0]){
                     r.innerHTML+=result[rid].childNodes[0].nodeValue;
                  }
               }
            }
            else{
               r.innerHTML="ERROR: XML error";
            }
         }
      }
   };
   xmlhttp.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
   var r=xmlhttp.send('Mode=XML');



//   ResContainer.innerHTML="<font color=silver>"+
//                          "- Informations isn't avalilable at now -"+
//                          "</font>";
}
addEvent(window,"load",onLoadViewProcessor_$self->{name});
</script>
EOF
      }
      return("- ERROR - no idfield - ");
   }
   my $d=$self->RawValue($current);
   my $name=$self->Name();
   my $app=$self->getParent();

   if (!defined($current)){
      # init from Query
      $d=Query->Param("Formated_".$name);
   }
   if ($mode eq "storedworkspace"){
      return($self->FormatedStoredWorkspace());
   }
   my $readonly=0;
   if ($self->readonly($current)){
      $readonly=1;
   }
   if ($self->frontreadonly($current)){
      $readonly=1;
   }

   if (($mode eq "edit" || $mode eq "workflow") && !$readonly){
      my $fromquery=Query->Param("Formated_$name");
      if (defined($fromquery)){
         $d=$fromquery;
      }
      if ($self->FieldCache->{LastDrop}){
         return($self->FieldCache->{LastDrop});
      }
      return("<input class=finput type=text name=Formated_$name value=\"$d\">");
   }
   if (!($d=~m/\[\?\]$/)){
      $d=$self->addWebLinkToFacility($d,$current) if ($mode eq "HtmlDetail");
      $d.=$self->getHtmlContextMenu($current);
   }
   return($d);
}

sub RawValue
{
   my $self=shift;
   my $d=$self->SUPER::RawValue(@_);
   my $current=shift;

   if ($self->{VJOINSTATE} eq "not found"){
      if (defined($self->{altnamestore})){
         my $alt=$self->getParent->getField($self->{altnamestore});
         $d=$alt->RawValue($current);
         $d.="[?]";
      }
   }
   return($d);
}


sub FormatedStoredWorkspace
{
   my $self=shift;
   my $name=$self->{name};
   my $d="";

   my @curval=Query->Param("Formated_".$name);
   my $disp="";
   $d="<!-- FormatedStoredWorkspace from textdrop -->";
   foreach my $var (@curval){
      $disp.=$var;
      $d.="<input type=hidden name=Formated_$name value=\"$var\">";
   }
   $d=$disp.$d;
   return($d);
}




1;
