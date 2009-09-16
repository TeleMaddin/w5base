package kernel::Field;
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
use kernel;
use kernel::Field::Id;
use kernel::Field::Vector;
use kernel::Field::Text;
use kernel::Field::FlexBox;
use kernel::Field::Databoss;
use kernel::Field::Password;
use kernel::Field::Phonenumber;
use kernel::Field::File;
use kernel::Field::Float;
use kernel::Field::Currency;
use kernel::Field::Number;
use kernel::Field::Percent;
use kernel::Field::Email;
use kernel::Field::Link;
use kernel::Field::DynWebIcon;
use kernel::Field::Interface;
use kernel::Field::Linenumber;
use kernel::Field::TextDrop;
use kernel::Field::MultiDst;
use kernel::Field::Textarea;
use kernel::Field::Htmlarea;
use kernel::Field::GoogleMap;
use kernel::Field::GoogleAddrChk;
use kernel::Field::ListWebLink;
use kernel::Field::Select;
use kernel::Field::Boolean;
use kernel::Field::SubList;
use kernel::Field::Group;
use kernel::Field::Contact;
use kernel::Field::ContactLnk;
use kernel::Field::PhoneLnk;
use kernel::Field::FileList;
use kernel::Field::WorkflowRelation;
use kernel::Field::TimeSpans;
use kernel::Field::Date;
use kernel::Field::MDate;
use kernel::Field::CDate;
use kernel::Field::Owner;
use kernel::Field::Creator;
use kernel::Field::Editor;
use kernel::Field::RealEditor;
use kernel::Field::Import;
use kernel::Field::Dynamic;
use kernel::Field::Container;
use kernel::Field::KeyHandler;
use kernel::Field::KeyText;
use kernel::Field::Mandator;
use kernel::Field::Duration;
use kernel::Field::Message;
use kernel::Field::QualityText;
use kernel::Field::QualityState;
use kernel::Field::QualityOk;
use kernel::Field::QualityLastDate;
use kernel::Field::QualityResponseArea;
use kernel::Field::Fulltext;
use kernel::Field::Interview;
use kernel::Field::InterviewState;
use kernel::Universal;
@ISA    = qw(kernel::Universal);

sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($self,$type);
   $self->{group}="default" if (!defined($self->{group}));
   $self->{_permitted}->{mainsearch}=1; # erzeugt gro�es Suchfeld
   $self->{_permitted}->{searchable}=1; # stellt das Feld als suchfeld dar
   $self->{_permitted}->{defsearch}=1;  # automatischer Focus beim Suchen
   $self->{_permitted}->{selectable}=1; # Feld kann im select statement stehen
   $self->{_permitted}->{fields}=1;     # Feld erzeugt dynamisch zus�tzl. Felder
   $self->{_permitted}->{align}=1;      # Ausrichtung
   $self->{_permitted}->{valign}=1;
   $self->{_permitted}->{htmlhalfwidth}=1; # halbe breite in HtmlDetail
   $self->{_permitted}->{nowrap}=1;     # kein automatischer Zeilenumbruch
   $self->{_permitted}->{htmlwidth}=1;  # Breite in der HTML Ausgabe (Spalten)
   $self->{_permitted}->{xlswidth}=1;   # Breite in der XLS Ausgabe (Spalten)
   $self->{_permitted}->{uivisible}=1;  # Anzeige in der Detailsicht bzw. Listen
   $self->{_permitted}->{history}=1;    # �ber das Feld braucht History
   $self->{_permitted}->{htmldetail}=1; # Anzeige in der Detailsicht
   $self->{_permitted}->{detailadd}=1;  # zus�tzliche Daten bei HtmlDetail
   $self->{_permitted}->{translation}=1;# �bersetzungsbasis f�r Labels
   $self->{_permitted}->{selectfix}=1;  # force to use this field alwasy in sql
   $self->{_permitted}->{default}=1;    # Default value on new records
   $self->{_permitted}->{unit}=1;       # Unit prefix in detail view
   $self->{_permitted}->{label}=1;      # Die Beschriftung des Felds
   $self->{_permitted}->{readonly}=1;   # Nur zum lesen
   $self->{_permitted}->{frontreadonly}=1;   # Nur zum lesen
   $self->{_permitted}->{grouplabel}=1; # 1 wenn in HTML Detail Grouplabel soll
   $self->{_permitted}->{dlabelpref}=1; # Beschriftungs prefix in HtmlDetail
   $self->{searchable}=1 if (!defined($self->{searchable}));
   $self->{selectable}=1 if (!defined($self->{selectable}));
   $self->{htmldetail}=1 if (!defined($self->{htmldetail}));
   if (!defined($self->{selectfix})){
      $self->{selectfix}=0;
   }
   if (!defined($self->{uivisible}) && $self->{selectable}){
      $self->{uivisible}=1;
   }
   if (!defined($self->{history})){
      $self->{history}=1;
   }
   if (!defined($self->{valign})){
      $self->{valign}="center";
      $self->{valign}="top";
   }
   if (!defined($self->{grouplabel})){
      $self->{grouplabel}=1;
   }
   if (!defined($self->{uivisible}) && !$self->{selectable}){
      $self->{uivisible}=0;
   }
   if (defined($self->{vjointo})){
      $self->{vjoinconcat}="; " if (!defined($self->{vjoinconcat}));
      $self->{_permitted}->{vjoinconcat}=1;# Verkettung der Ergebnisse
      if (!defined($self->{weblinkto})){
         $self->{weblinkto}=$self->{vjointo};
      }
      if (!defined($self->{weblinkon})){
         $self->{weblinkon}=$self->{vjoinon};
      }
   }
   return($self);
}

sub addWebLinkToFacility
{
   my $self=shift;
   my $d=shift;
   my $current=shift;
   my %param=@_;

   my $weblinkon=$self->{weblinkon};
   my $weblinkto=$self->{weblinkto};
   if (ref($weblinkto) eq "CODE"){
      ($weblinkto,$weblinkon)=&{$weblinkto}($self,$d,$current);
   }

   if (defined($weblinkto) && defined($weblinkon) && lc($weblinkto) ne "none"){
      my $target=$weblinkto;
      $target=~s/::/\//g;
      $target="../../$target/Detail";
      my $targetid=$weblinkon->[1];
      my $targetval;
      if (!defined($targetid)){
         $targetid=$weblinkon->[0];
         $targetval=$d;
      }
      else{
         my $linkfield=$self->getParent->getField($weblinkon->[0]);
         if (!defined($linkfield)){
            msg(ERROR,"can't find field '%s' in '%s'",$weblinkon->[0],
                $self->getParent);
            return($d);
         }
         $targetval=$linkfield->RawValue($current);
      }
      if (defined($targetval) && $targetval ne "" && !ref($targetval)){
         my $detailx=$self->getParent->DetailX();
         my $detaily=$self->getParent->DetailY();
         $targetval=$targetval->[0] if (ref($targetval) eq "ARRAY");
         my $onclick="openwin('$target?".
                     "AllowClose=1&search_$targetid=$targetval',".
                     "'_blank',".
                     "'height=$detaily,width=$detailx,toolbar=no,status=no,".
                     "resizable=yes,scrollbars=no');";
         #$d="<a class=sublink href=JavaScript:$onclick>".$d."</a>";
         my $context;
         if (defined($param{contextMenu})){
            $context=" cont=\"$param{contextMenu}\" ";
         }
         $d="<span class=\"sublink\" $context onclick=\"$onclick\">".
            $d."</span>";
      }
   }
   return($d);
}

sub getSimpleInputField
{
   my $self=shift;
   my $value=shift;
   my $readonly=shift;
   my $name=$self->Name();
   $value=~s/"/&quot;/g;
   my $d;

   my $unit=$self->unit;
   $unit="<td width=40>$unit</td>" if ($unit ne "");
   my $inputfield="<input type=\"text\" id=\"$name\" value=\"$value\" ".
                  "name=\"Formated_$name\" class=\"finput\">";
   if (ref($self->{getHtmlImputCode}) eq "CODE"){
      $inputfield=&{$self->{getHtmlImputCode}}($self,$value,$readonly);
   }
   if (!$readonly){
      my $width="100%";
      $width=$self->{htmleditwidth} if (defined($self->{htmleditwidth}));
      $d=<<EOF;
<table style="table-layout:fixed;width:$width" cellspacing=0 cellpadding=0>
<tr><td>$inputfield</td>$unit</tr></table>
EOF
   }
   else{
      $d=<<EOF;
<table style="table-layout:fixed;width:100%" cellspacing=0 cellpadding=0>
<tr><td><span class="readonlyinput">$value</span></td>$unit</tr></table>
EOF
   }
   return($d);
}




sub label
{
   my $self=shift;
   return(&{$self->{label}}($self)) if (ref($self->{label}) eq "CODE");
   return($self->{label});
}

sub Name()
{
   my $self=shift;
   return($self->{name});
}

sub Type()
{
   my $self=shift;
   my ($type)=$self=~m/::([^:]+)=.*$/;
   return($type);
}

sub UiVisible
{
   my $self=shift;
   my $mode=shift;
   my %param=@_;
   if (ref($self->{uivisible}) eq "CODE"){
      return(&{$self->{uivisible}}($self,$mode,%param));
   }
   return($self->{uivisible});
}

sub Uploadable
{
   my $self=shift;
   my %param=@_;
   if (defined($self->{uploadable})){
      if (ref($self->{uploadable}) eq "CODE"){
         return(&{$self->{uploadable}}($self,%param));
      }
      else{
         return($self->{uploadable});
      }
   }
   return(0) if (!$self->UiVisible("ViewEditor"));
   return(0) if ($self->readonly);
   return(0) if ($self->{name} eq "srcid");
   return(0) if ($self->{name} eq "srcsys");
   return(0) if ($self->{name} eq "srcload");
   return(1);
}

sub DefaultValue
{
   my $self=shift;
   my $newrec=shift;
   if (ref($self->{default}) eq "CODE"){
      return(&{$self->{default}}($self,$newrec));
   }
   return($self->{default});
}


sub FieldCache
{
   my $self=shift;
   my $pc=$self->getParent->Context;
   my $fieldkey="FieldCache:".$self->Name();
   $pc->{$fieldkey}={} if (!defined($pc->{$fieldkey}));
   return($pc->{$fieldkey});
}

sub vjoinobj
{
   my $self=shift;
   return(undef) if (!exists($self->{vjointo}));
   my $jointo=$self->{vjointo};
   my $joinparam=$self->{vjoinparam};
   ($jointo,$joinparam)=&{$jointo}($self) if (ref($jointo) eq "CODE");
   $self->{joincache}={} if (!defined($self->{joincache}));

   if (!defined($self->{joincache}->{$jointo})){
      #msg(INFO,"create of '%s'",$jointo);
      my $o=getModuleObject($self->getParent->Config,$jointo,$joinparam);
      #msg(INFO,"o=$o");
      $self->{joincache}->{$jointo}=$o;
      $self->{joincache}->{$jointo}->setParent($self->getParent);
   }
   $self->{joinobj}=$self->{joincache}->{$jointo};
   return($self->{joinobj});
}

sub vjoinContext
{
   my $self=shift;
   return(undef) if (!defined($self->{vjointo}));
   my $context=$self->{vjointo}.";";
   if (ref($self->{vjoinon}) eq "ARRAY"){
      $context.=join(",",@{$self->{vjoinon}});
   }
   if (defined($self->{vjoinbase})){
#printf STDERR ("fifi vjoinbase=%s on %s\n",$self->{vjoinbase},$self->Name());
      my @l;
      @l=@{$self->{vjoinbase}} if (ref($self->{vjoinbase}) eq "ARRAY");
      @l=%{$self->{vjoinbase}} if (ref($self->{vjoinbase}) eq "HASH");
      $context.="+".join(",",@l);
   }
   return($context);
}

sub Size     # returns the size in chars if any defined
{
   my $self=shift;
   return($self->{size});
}

sub contextMenu
{
   my $self=shift;
   my %param=@_;

   return;
}

sub getHtmlContextMenu
{
   my $self=shift;
   my $rec=shift;
   my $name=$self->Name();

   my @contextMenu=$self->contextMenu(current=>$rec);
   my $contextMenu=$self->getParent->getHtmlContextMenu($name,@contextMenu);
   return($contextMenu);
}

sub Label
{
   my $self=shift;
   my $label=$self->{label};
   my $d="-NoLabelSet-";
   $d=$label if ($label ne "");
   my $tr=$self->{translation};
   $tr=$self->getParent->Self if (!defined($tr));
   return($self->getParent->T($d,$tr));
}

sub rawLabel
{
   my $self=shift;
   my $label=$self->{label};
   my $d="-NoLabelSet-";
   $d=$label if ($label ne "");
   return($d);
}

sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $currentstate=shift;   # current state of write record

   if (!exists($newrec->{$self->Name()})){
      if (!defined($oldrec)){
         my $def=$self->DefaultValue($newrec);
         if (defined($def)){
            return({$self->Name()=>$def});
         }
      }
      return({});
   }
   if (!ref($newrec->{$self->Name()}) &&
       $self->Type() ne "File"){
      return({$self->Name()=>trim($newrec->{$self->Name()})});
   }
   return({$self->Name()=>$newrec->{$self->Name()}});
}

sub copyFrom
{
   my $self=shift;
   my $oldrec=shift;
   my $oldval=$self->RawValue($oldrec);
   return($oldval);
}

sub finishWriteRequestHash
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(undef);
}

sub prepareToSearch
{
   my $self=shift;
   my $filter=shift;
   return($filter);
}

sub preProcessFilter
{
   my $self=shift;
   my $hflt=shift;
   my $fobj=$self;
   my $field=$self->Name();
   my $changed=0;
   my $err;

   if (defined($self->{onPreProcessFilter}) &&
       ref($self->{onPreProcessFilter}) eq "CODE"){
      return(&{$self->{onPreProcessFilter}}($self,$hflt));
   }
   if (defined($fobj->{vjointo}) && !defined($fobj->{dataobjattr})){
      $fobj->vjoinobj->ResetFilter();
      my $loadfield=$fobj->{vjoinon}->[1];
      my $searchfield=$fobj->{vjoindisp};
      if (ref($fobj->{vjoindisp}) eq "ARRAY"){
         for(my $findex=0;$findex<=$#{$fobj->{vjoindisp}};$findex++){
            my $sfobj=$fobj->vjoinobj->getField($fobj->{vjoindisp}->[$findex]);
            if (defined($sfobj)){
               if ($sfobj->Self ne "kernel::Field::DynWebIcon"){
                  $searchfield=$fobj->{vjoindisp}->[$findex];
                  last;
               }
            }
         }
      }
      my %flt=($searchfield=>$hflt->{$field});
      $fobj->vjoinobj->SetFilter(\%flt);
      if (defined($hflt->{$fobj->{vjoinon}->[0]}) &&
          !defined($self->{dataobjattr})){
         $fobj->vjoinobj->SetNamedFilter("vjoinadd".$field,
                      {$fobj->{vjoinon}->[1]=>$hflt->{$fobj->{vjoinon}->[0]}});
      }


      $fobj->vjoinobj->SetCurrentView($fobj->{vjoinon}->[1]);
      delete($hflt->{$field});
      my $d=$fobj->vjoinobj->getHashIndexed($fobj->{vjoinon}->[1]);
      my @keylist=keys(%{$d->{$fobj->{vjoinon}->[1]}});
      if (($flt{$searchfield}=~m/\[LEER\]/) || 
          ($flt{$searchfield}=~m/\[EMPTY\]/)){
         push(@keylist,undef,"");
      }
      if ($#keylist==-1){
         @keylist=(-99);
      }

      $hflt->{$fobj->{vjoinon}->[0]}=\@keylist;
      if ($fobj->{vjoinon}->[0] ne $self->Name()){
         $changed=1;
      }
   }
   return($changed,$err);
}

sub doUnformat
{
   my $self=shift;

   if (defined($self->{onUnformat}) && ref($self->{onUnformat}) eq "CODE"){
      return(&{$self->{onUnformat}}($self,@_));
   }
   return($self->Unformat(@_));
}


sub Unformat
{
   my $self=shift;
   my $formated=shift;
   my $rec=shift;

   return({}) if ($self->readonly);
   if ($#{$formated}>0){
      return({$self->Name()=>$formated});
   }
   return({$self->Name()=>$formated->[0]});
}

sub prepUploadRecord   # prepair one record on upload
{
   my $self=shift;
   my $newrec=shift;
   my $oldrec=shift;
   return(1);
}


sub getSelectField     # returns the name/function to place in select
{
   my $self=shift;
   my $mode=shift;
   my $db=shift;

   if ($mode eq "select" || $mode=~m/^where\..*/){
      if (!defined($self->{dataobjattr}) && defined($self->{container})){
         if ($mode eq "where.select"){
            return($self->Name()); 
         }
      }
      return(undef) if (!defined($self->{dataobjattr}));
      if (ref($self->{dataobjattr}) eq "ARRAY"){
         $_=$db->DriverName();
         case: {
            /^mysql$/i and do {
               return("concat(".join(",'-',",@{$self->{dataobjattr}}).")");
               return(undef); # noch todo
            };
            /^oracle$/i and do {
               my @fl=@{$self->{dataobjattr}};
               my $wcmd=$fl[0];
               if ($#fl>0){
                  my @flx=shift(@fl);
                  my @kl;
                  map({push(@flx,"'-'",$_);
                       push(@kl,"))")} @fl);
                  my $last=pop(@flx);
                  $wcmd=join(",",map({"concat($_"} @flx)).",$last".join("",@kl);
               }
               return($wcmd); 
            };
            /^odbc$/i and do {
               return(join("+'-'+",
                           map({"'\"'+rtrim(ltrim(convert(char,$_)))+'\"'"} 
                           @{$self->{dataobjattr}})));
            };
            do {
               msg(ERROR,"conversion for date on driver '$_' not ".
                         "defined ToDo!");
               return(undef);
            };
         }
      }
      if ($mode eq "select" && $self->{noselect}){
         return(undef);
      }
      if ($mode eq "select" || $mode eq "where.select"){ 
         if (defined($self->{altdataobjattr})){
            $_=$db->DriverName();
            case: {
               /^mysql$/i and do {
                  my $f="if ($self->{altdataobjattr} is null,".
                        "$self->{dataobjattr},$self->{altdataobjattr})";
                  return($f); # noch todo
               };
               do {
                  msg(ERROR,"alternate conversion for date on driver '$_' not ".
                            "defined ToDo!");
                  return(undef);
               };
            }
            
         }
      }
      return($self->{dataobjattr});
   }
   if ($mode eq "order"){
      my $ordername=shift;
    
      if (defined($self->{dataobjattr}) && 
          ref($self->{dataobjattr}) ne "ARRAY"){
         my $orderstring=$self->{dataobjattr};
         $orderstring=$self->{name} if ($self->{dataobjattr}=~m/^max\(.*\)$/);
         my $sqlorder="";
         if (defined($self->{sqlorder})){
            $sqlorder=$self->{sqlorder};
         }
         if ($ordername=~m/^-/){
            if ($sqlorder eq "desc"){
               $sqlorder="";
            }
            else{
               $sqlorder="desc";
            }
         }
         $orderstring.=" ".$sqlorder;
         return(undef) if (lc($self->{sqlorder}) eq "none");
         return($orderstring);
      }
   }
   return(undef);
}


sub RawValue
{
   my $self=shift;
   my $current=shift;
   my $d;

   if (exists($current->{$self->Name()})){
      $d=$current->{$self->Name()};
   }
   elsif (defined($self->{onRawValue}) && ref($self->{onRawValue}) eq "CODE"){
      $current->{$self->Name()}=&{$self->{onRawValue}}($self,$current);
      $d=$current->{$self->Name()};
   }
   elsif (defined($self->{vjointo}) && 
          $self->Self() ne "kernel::Field::FlexBox"){
      my $c=$self->getParent->Context();
      $c->{JoinData}={} if (!exists($c->{JoinData}));
      $c=$c->{JoinData};
      my $joincontext=$self->vjoinContext();
      my @view;
      if (ref($self->{vjoindisp}) eq "ARRAY"){
         @view=(@{$self->{vjoindisp}},$self->{vjoinon}->[1]);
      }
      else{
         @view=($self->{vjoindisp},$self->{vjoinon}->[1]);
      }
      if ($self->getParent->can("getCurrentView")){
         foreach my $fieldname ($self->getParent->getCurrentView()){
            my $fobj=$self->getParent->getField($fieldname);
            next if (!defined($fobj));
            if ($fobj->vjoinContext() eq $joincontext){
               if (!grep(/^$fobj->{vjoindisp}$/,@view)){
                  push(@view,$fobj->{vjoindisp});
               }
            }
         }
      }
      $joincontext.="+".join(",",sort(@view));
      $c->{$joincontext}={} if (!exists($c->{$joincontext}));
      $c=$c->{$joincontext};
      my @joinon=@{$self->{vjoinon}};
      my %flt=();
      my $joinval=0;
      if ($self->getParent->can("getField")){
         while(my $myfield=shift(@joinon)){
            my $joinfield=shift(@joinon);
            my $myfieldobj=$self->getParent->getField($myfield);
            if (defined($myfieldobj)){
               if ($myfieldobj ne $self){
                  my $myval=$myfieldobj->RawValue($current);
                  if (!ref($myval)){
                     $flt{$joinfield}=\$myval;
                  }
                  else{
                     $flt{$joinfield}=$myval;
                  }
                  $joinval=1 if (defined($myval) && $myval ne "");
               }
               else{
                  $flt{$joinfield}=\undef;
                  $joinval=1;
               }
            }
         }
      }

      my $joinkey=join(";",map({ my $k=$flt{$_};
                                 $k=$$k if (ref($k) eq "SCALAR");
                                 $k=join(";",@$k) if (ref($k) eq "ARRAY");
                                 $_."=".$k;
                               } sort(keys(%flt))));
      delete($self->{VJOINSTATE});
      delete($self->{VJOINKEY});
      delete($self->{VJOINCONTEXT});
      if (keys(%flt)>0){
         if ($joinval){ 
            if (!exists($c->{$joinkey})){
               if (defined($self->{vjoinbase})){
                  my $base=$self->{vjoinbase};
                  if (ref($base) eq "HASH"){
                     $base=[$base];
                  }
                  $self->vjoinobj->SetNamedFilter("BASE",@{$base});
               }
               $self->vjoinobj->SetFilter(\%flt);
               $c->{$joinkey}=[$self->vjoinobj->getHashList(@view)];
               Dumper($c->{$joinkey}); # ensure that all subs are resolved
            }
            my %u=();
            my $disp=$self->{vjoindisp};
            $disp=$disp->[0] if (ref($disp) eq "ARRAY");
            map({
                   my %current=%{$_};
                   my $dispobj=$self->vjoinobj->getField($disp,\%current);
                   my $bk=$dispobj->RawValue(\%current);
                   $bk=join(", ",@$bk) if (ref($bk) eq "ARRAY");
                   $u{$bk}=1;
                } @{$c->{$joinkey}});
            if (keys(%u)>0){
               $self->{VJOINSTATE}="ok";
               $self->{VJOINKEY}=$joinkey;
               $self->{VJOINCONTEXT}=$joincontext;
            }
            else{
               $self->{VJOINSTATE}="not found";
            }
            $current->{$self->Name()}=join($self->{vjoinconcat},sort(keys(%u)));
            $d=$current->{$self->Name()};
         }
         else{
            $d=undef;
         }
      }
      else{
         return("ERROR: can't find join target '$self->{vjoinon}->[0]'");
      }
   }
   elsif (defined($self->{container})){
      my $container=$self->getParent->getField($self->{container});
      if (!defined($container)){ # if the container comes from the parrent
                                 # DataObj (if i be a SubDataObj)
         my $parentofparent=$self->getParent->getParent();
         $container=$parentofparent->getField($self->{container});
      }
      my $containerdata=$container->RawValue($current);
      if (wantarray()){
         return(@{$containerdata->{$self->Name}});
      }
      if (ref($containerdata->{$self->Name}) eq "ARRAY" &&
          $#{$containerdata->{$self->Name}}<=0){
         $d=$containerdata->{$self->Name}->[0];
      }
      else{
         $d=$containerdata->{$self->Name};
      }
   }
   elsif (defined($self->{alias})){
      my $fo=$self->getParent->getField($self->{alias});
      return(undef) if (!defined($fo));
      my $d=$fo->RawValue($current);
      return($d);
   }
   else{
      $d=$current->{$self->Name};
   }
   if (ref($self->{prepRawValue}) eq "CODE"){
      $d=&{$self->{prepRawValue}}($self,$d,$current);
   }
   $d=$self->{default} if (exists($self->{default}) && (!defined($d) ||
                           $d eq ""));
   return($d);
}

sub getLastVjoinRec          # to use the last joined record
{
   my $self=shift;
   my $joinkey=$self->{VJOINKEY};
   my $joincontext=$self->{VJOINCONTEXT};
   my $c=$self->getParent->Context();

   if (defined($joinkey) && defined($joincontext) &&
       defined($c->{JoinData}->{$joincontext}) && 
       defined($c->{JoinData}->{$joincontext}->{$joinkey})){
      return($c->{JoinData}->{$joincontext}->{$joinkey});
   }

   return(undef);

}

sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   #printf STDERR ("fifi default FinishWrite handler for field %s\n",
   #               $self->{name});
   if (defined($self->{onFinishWrite}) && 
       ref($self->{onFinishWrite}) eq "CODE"){   
      return(&{$self->{onFinishWrite}}($self,$oldrec,$newrec));
   }
   return(undef);
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;

   if (defined($self->{onFinishDelete}) && 
       ref($self->{onFinishDelete}) eq "CODE"){   
      return(&{$self->{onFinishDelete}}($self,$oldrec));
   }
   return(undef);
}

sub FormatedResult
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my $d=$self->FormatedDetail($current,$FormatAs);
   return($d);
}

sub FormatedDetail
{
   my $self=shift;
   my $current=shift;
   my $FormatAs=shift;
   my $d=$self->RawValue($current);
   $d=join("; ",@$d) if (ref($d) eq "ARRAY" && $FormatAs=~m/^Html/);
   return($d);
}

sub FormatedSearch
{
   my $self=shift;

   my $name=$self->{name};
   my $label=$self->Label;
   my $curval=Query->Param($name);
   if (!defined($curval)){
      $curval=Query->Param("search_".$name);
   }
   $curval=~s/"/&quot;/g;
   my $d="<table style=\"table-layout:fixed;width:100%\" ".
         "border=0 cellspacing=0 cellpadding=0>\n";
   $d.="<tr><td>". # for min width, add an empty image with 50px width
       "<img width=50 border=0 height=1 ".
       "src=\"../../../public/base/load/empty.gif\">";
   $d.="<input type=text  name=\"search_$name\" ".
       "class=finput style=\"min-width:50px\" value=\"$curval\">";
   $d.="</td>";
   my $FieldHelpUrl=$self->getFieldHelpUrl();
   if (defined($FieldHelpUrl)){
      $d.="<td width=10 valign=top align=right>";
      $d.="<img style=\"cursor:pointer;cursor:hand;float:right;\" ".
          "onClick=\"FieldHelp_On_$name()\" align=right ".
          "src=\"../../../public/base/load/questionmark.gif\" ".
          "border=0>";
      $d.="</td>";
      my $q=kernel::cgi::Hash2QueryString(field=>"search_$name",
                                          label=>$label);
      $d.=<<EOF;
<script langauge="JavaScript">
function FieldHelp_On_$name()
{
   showPopWin('$FieldHelpUrl?$q',500,200,RestartApp);
}
</script>
EOF
   }
   $d.="</td></tr></table>\n";
   return($d);
}

sub getFieldHelpUrl
{
   my $self=shift;

   if (defined($self->{FieldHelp})){
      if (ref($self->{FieldHelp}) eq "CODE"){
         return(&{$self->{FieldHelp}}($self));
      }
      return($self->{FieldHelp});
   }
   my $type=$self->Type();
   if ($type=~m/Date$/){
      return("../../base/load/tmpl/FieldHelp.Date");
   }
   if ($self->{FieldHelp} ne "0"){
      return("../../base/load/tmpl/FieldHelp.Default");
   }
   return(undef);
}

#
# vor history displaying in Workflow Mode
#
sub FormatedStoredWorkspace
{
   my $self=shift;
   my $name=$self->{name};
   my $d="";

   my @curval=Query->Param("Formated_".$name);
   my $disp="";
   my $var=$name;
   if (defined($self->{vjointo})){
      $var=$self->{vjoinon}->[0];
   }
   if ($#curval>0){
      $disp.=$self->FormatedResult({$var=>\@curval},"HtmlDetail");
   }
   else{
      $disp.=$self->FormatedResult({$var=>$curval[0]},"HtmlDetail");
   }
   foreach my $var (@curval){
      $d.="<input type=hidden name=Formated_$name value=\"$var\">";
   }
   $d=$disp.$d;
   return($d);
}

sub getXLSformatname
{
   my $self=shift;
   return("default");
}

sub WSDLfieldType
{
   my $self=shift;
   my $ns=shift;
   my $mode=shift;
   if (exists($self->{WSDLfieldType})){
      if (!($self->{WSDLfieldType}=~m/:/)){
         return($ns.":".$self->{WSDLfieldType});
      }
      return($self->{WSDLfieldType});
   }
   return("xsd:string");
}


# Zugriffs funktionen

1;
