package kernel::QRule;
#  W5Base Framework
#  Copyright (C) 2002  Hartmut Vogler (it@guru.de)
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
#
use vars qw(@ISA @EXPORT);
use strict;
use kernel;
use kernel::Universal;
use Exporter;


@ISA=qw(kernel::Universal Exporter);
@ISA=qw(Exporter kernel::Universal);

@EXPORT = qw(&ProcessOpList &OpAnalyse);

sub new
{
   my $type=shift;
   my $self=bless({@_},$type);
   return($self);
}

sub Init                  # at this method, the registration must be done
{
   my $self=shift;
   return(1);
}

sub getPosibleTargets
{
   my $self=shift;
   return;
}

sub getName
{
   my $self=shift;
   return($self->getParent->T($self->Self,$self->Self));
}

sub getDescription
{
   my $self=shift;
   my $instdir=$self->getParent->Config->Param("INSTDIR");
   my $selfname=$self->Self();
   $selfname=~s/::/\//g;
   my $filename=$instdir."/mod/${selfname}.pm";
   my $html=`cd /tmp && pod2html --title none --noheader --noindex --infile=$filename`;
   ($html)=$html=~m/<body[^>]*>(.*)<\/body>/smi;
   $html=~s/<p>\s*<\/p>//smi;
   $html=~s/<p><a name="__index__"><\/a><\/p>//smi;

   return($html);
}

sub qcheckRecord
{
   my $self=shift;
   my $rec=shift;

   my $result=3;       # undef = rule not useable
                       #     1 = rule failed, but no big problem
                       #     2 = rule failed
                       #     3 = rule failed - k.o. criterium
   my $desc={
               qmsg=>'this is a rule with no defined qcheckRecord method',
               dataissue=>'this could be an array of text to DataIssue Wf',
            };


   return($result,$desc);
}

sub priority           # priority in witch order the rules should be processed
{
   my $self=shift;
   return(1000);
}

sub T
{
   my $self=shift;
   my $t=shift;
   my $tr=(caller())[0];
   return($self->getParent->T($t,$tr,@_));
}


sub IfaceCompare
{
   my $self=shift;
   my $obj=shift;
   my $origrec=shift;
   my $origfieldname=shift;
   my $comprec=shift;
   my $compfieldname=shift;
   my $forcedupd=shift;
   my $wfrequest=shift;
   my $qmsg=shift;
   my $dataissue=shift;
   my $errorlevel=shift;
   my %param=@_;

   $param{mode}="native" if (!defined($param{mode}));
   $param{AllowEmpty}=1 if (!defined($param{AllowEmpty}));

   return if (!defined($obj->getField($origfieldname)));
   my $takeremote=0;
   my $ask=1;
   if ($param{mode} eq "native" ||
       $param{mode} eq "string"){           # like nativ string compares
      if (exists($comprec->{$compfieldname})){
         if (defined($comprec->{$compfieldname})){
            if (!defined($origrec->{$origfieldname}) ||
                $comprec->{$compfieldname} ne $origrec->{$origfieldname}){
               $takeremote++;
            }
         }
      }
   }
   elsif ($param{mode} eq "text"){          # for multiline text fields
      if (exists($comprec->{$compfieldname})){
         if (defined($comprec->{$compfieldname})){
            my $t1=$origrec->{$origfieldname};
            my $t2=$comprec->{$compfieldname};
            $t1=~s/\r\n/\n/gs;
            $t2=~s/\r\n/\n/gs;
            if (!defined($origrec->{$origfieldname}) || $t1 ne $t2){
               $takeremote++;
            }
         }
      }
   }
   elsif ($param{mode} eq "leftouterlinkcreate" ||
          $param{mode} eq "leftouterlink"){  # like servicesupprt links
      if (exists($comprec->{$compfieldname}) &&
          defined($comprec->{$compfieldname}) &&
          (!defined($origrec->{$origfieldname}) ||
           $comprec->{$compfieldname} ne $origrec->{$origfieldname})){
         my $lnkfield=$obj->getField($origfieldname);
         my $lnkobj=$lnkfield->{vjointo};
         my $chkobj=getModuleObject($self->getParent->Config,$lnkobj);
         if (defined($chkobj)){
            $chkobj->SetFilter($lnkfield->{vjoindisp}=>
                               "\"".$comprec->{$compfieldname}."\"");
            my ($chkrec,$msg)=$chkobj->getOnlyFirst($lnkfield->{vjoinon}->[1]);
            if (!defined($chkrec)){
               if ($param{mode} eq "leftouterlinkcreate"){
                  my $newrec={};
                  if (ref($param{onCreate}) eq "HASH"){
                     foreach my $k (keys(%{$param{onCreate}})){
                        $newrec->{$k}=$param{onCreate}->{$k};
                     }
                  }
                  #printf STDERR ("MSG: auto create element in '%s'\n%s\n",
                  #               $chkobj->Self(),Dumper($newrec));
                  $chkobj->ValidatedInsertRecord($newrec);
                  $takeremote++;
               }
               else{
                  msg(ERROR,"invalid value '$comprec->{$compfieldname}' ".
                            "while qrule compare '$origfieldname' and ".
                            "'$compfieldname'");
               }
            }
            else{
               $takeremote++;
            }
         }
      }
   }
   elsif ($param{mode} eq "integer"){  # like amounth of memory
      if (exists($comprec->{$compfieldname}) &&
          defined($comprec->{$compfieldname}) &&
          $comprec->{$compfieldname}!=0 &&
          (!defined($origrec->{$origfieldname}) ||
           $origrec->{$origfieldname} ==0 ||
           $comprec->{$compfieldname} != $origrec->{$origfieldname})){
         if (defined($param{tolerance})){
            if ( ($comprec->{$compfieldname}*((100+$param{tolerance})/100.0)<
                  $origrec->{$origfieldname}) ||
                 ($comprec->{$compfieldname}*((100-$param{tolerance})/100.0)>
                  $origrec->{$origfieldname})){
               $takeremote++;
            }
         }
         else{
            $takeremote++;
         }
      }
   }
   elsif ($param{mode} eq "boolean"){  # like true/false 1|0
      if (exists($comprec->{$compfieldname}) &&
          defined($comprec->{$compfieldname}) &&
          (!defined($origrec->{$origfieldname}) ||
           $comprec->{$compfieldname} != $origrec->{$origfieldname})){
         
         $takeremote++;
      }
   }
   if ($takeremote){
      my $compval;
      if (exists($comprec->{$compfieldname})){
         $compval=$comprec->{$compfieldname};
         if ($param{mode} eq "boolean"){ 
            if ($compval){ # some data cleanup in boolean mode 
               $compval=1;
            }
            else{
               $compval=0;
            }
         }
      }
      if ((exists($origrec->{allowifupdate}) && $origrec->{allowifupdate}) ||
          !defined($origrec->{$origfieldname}) ||
          $origrec->{$origfieldname}=~m/^\s*$/){
         if (!(!$param{AllowEmpty} && $comprec->{$compfieldname} eq "")){
            $forcedupd->{$origfieldname}=$compval;
         }
      }
      else{
         $wfrequest->{$origfieldname}=$compval;
      }
   }
}

sub HandleWfRequest
{
   my $self=shift;
   my $dataobj=shift;
   my $rec=shift;
   my $qmsg=shift;
   my $dataissue=shift;
   my $errorlevel=shift;
   my $wfrequest=shift;

   foreach my $name (sort(keys(%$wfrequest))){
      my $fo=$dataobj->getField($name);
      if (defined($fo)){
         my $label=$fo->rawLabel();
         push(@$dataissue,"[W5TRANSLATIONBASE=$fo->{translation}]");
         my $msg="$label: '$wfrequest->{$name}'";
         push(@$dataissue,$msg);

         my $label=$fo->Label();
         my $msg="$label: '$wfrequest->{$name}'";
         push(@$qmsg,$msg);
      }
   }
   #printf STDERR ("fifi request a DataIssue Workflow=%s\n",Dumper($wfrequest));
   if ($#{$qmsg}!=-1 || $$errorlevel>0){
      my $r={qmsg=>$qmsg,dataissue=>$dataissue};
      $r->{dataupdate}=$wfrequest;
      return($$errorlevel,$r);
   }
   return($$errorlevel,undef);
}

sub getPersistentModuleObject
{
   my $self=shift;
   my $label=shift;
   my $module=shift;

   $module=$label if (!defined($module) || $module eq "");
   if (!defined($self->{$label})){
      my $config=$self->getParent->Config();
      my $m=getModuleObject($config,$module);
      $self->{$label}=$m
   }
   $self->{$label}->ResetFilter();
   return($self->{$label});
}


sub OpAnalyse
{
   my $fpComperator=shift;
   my $fpRecGenerator=shift;
   my $refList=shift;
   my $cmpList=shift;
   my $opList=shift;
   my %param=@_;
 
   if (ref($fpComperator) ne "CODE"){
      return(1); 
   }
   if (ref($fpRecGenerator) ne "CODE"){
      return(2); 
   }
   if (ref($refList) ne "ARRAY"){
      return(10); 
   }
   if (ref($cmpList) ne "ARRAY"){
      return(11); 
   }
   if (ref($opList) ne "ARRAY"){
      return(12); 
   }

   my %cmpRes;
   for(my $refC=0;$refC<=$#{$refList};$refC++){
      my $found=0;
      cmpCloop: for(my $cmpC=0;$cmpC<=$#{$cmpList};$cmpC++){
         if (!exists($cmpRes{$refC."-".$cmpC})){
            $a=$refList->[$refC];
            $b=$cmpList->[$cmpC];
            $cmpRes{$refC."-".$cmpC}=&{$fpComperator}($a,$b);
            if (defined($cmpRes{$refC."-".$cmpC}) && 
                !$cmpRes{$refC."-".$cmpC}){
               # do an update   
               my $mode="update";
               foreach my $op (&{$fpRecGenerator}($mode,
                                                  $refList->[$refC],
                                                  $cmpList->[$cmpC],
                                                  %param)){
                  if (ref($op) eq "HASH"){
                     $op->{OP}=$mode         if (!exists($op->{OP}));
                     $op->{IDENTIFYBY}=undef if (!exists($op->{IDENTIFYBY}));
                     push(@{$opList},$op);
                  }
               }
            }
         }
         if (exists($cmpRes{$refC."-".$cmpC}) &&
             defined($cmpRes{$refC."-".$cmpC})){
            $found=1;
            last cmpCloop;
         }
      }
      if (!$found){
         # do a delete
         my $mode="delete";
         foreach my $op (&{$fpRecGenerator}($mode,
                                            $refList->[$refC],
                                            undef,
                                            %param)){
            if (ref($op) eq "HASH"){
               $op->{OP}=$mode         if (!exists($op->{OP}));
               $op->{IDENTIFYBY}=undef if (!exists($op->{IDENTIFYBY}));
               push(@{$opList},$op);
            }
         }
      }
   }
   for(my $cmpC=0;$cmpC<=$#{$cmpList};$cmpC++){
      my $found=0;
      refCloop: for(my $refC=0;$refC<=$#{$refList};$refC++){
         if (!exists($cmpRes{$refC."-".$cmpC})){
            $a=$refList->[$refC];
            $b=$cmpList->[$cmpC];
            $cmpRes{$refC."-".$cmpC}=&{$fpComperator}($a,$b);
            if (defined($cmpRes{$refC."-".$cmpC}) && !$cmpRes{$refC."-".$cmpC}){
               # do an update   
               my $mode="update";
               foreach my $op (&{$fpRecGenerator}($mode,
                                                  $refList->[$refC],
                                                  $cmpList->[$cmpC],
                                                  %param)){
                  if (ref($op) eq "HASH"){
                     $op->{OP}=$mode         if (!exists($op->{OP}));
                     $op->{IDENTIFYBY}=undef if (!exists($op->{IDENTIFYBY}));
                     push(@{$opList},$op);
                  }
               }
            }
         }
         if (defined($cmpRes{$refC."-".$cmpC})){
            $found=1;
            last refCloop; 
         }
      }
      if (!$found){
         # do an insert
         my $mode="insert";
         foreach my $op (&{$fpRecGenerator}($mode,
                                            undef,
                                            $cmpList->[$cmpC],
                                            %param)){
            if (ref($op) eq "HASH"){
               $op->{OP}=$mode         if (!exists($op->{OP}));
               $op->{IDENTIFYBY}=undef if (!exists($op->{IDENTIFYBY}));
               push(@{$opList},$op);
            }
         }
      }
   }
}

sub ProcessOpList
{
   my $self=shift;
   my $opList=shift;
   my $config=$self->Config;
   my $objCache={};
   #msg(INFO,"ProcessOpList: Start");
   foreach my $op (@{$opList}){
      if (!exists($objCache->{$op->{DATAOBJ}})){
         $objCache->{$op->{DATAOBJ}}=getModuleObject($config,$op->{DATAOBJ});
      }
      my $dataobj=$objCache->{$op->{DATAOBJ}};
      if (defined($dataobj)){
         $dataobj->ResetFilter();
         #msg(INFO,sprintf("OP:%s\n",Dumper($op)));
         if ($op->{OP} eq "nop"){
            msg(DEBUG,"skipped operation");
         }
         elsif ($op->{OP} eq "insert"){
            my $id=$dataobj->ValidatedInsertRecord($op->{DATA});
            $op->{IDENTIFYBY}=$id;
            msg(INFO,"insert id ok = $id");
         }
         elsif ($op->{OP} eq "update"){
            if ($op->{IDENTIFYBY} ne ""){
               my $idfield=$dataobj->IdField();
               my $idname=$idfield->Name();
               $dataobj->SetFilter({$idname=>\$op->{IDENTIFYBY}});
               my ($oldrec,$msg)=$dataobj->getOnlyFirst(qw(ALL));
               my $id=$dataobj->ValidatedUpdateRecord($oldrec,$op->{DATA},
                                                 {$idname=>\$op->{IDENTIFYBY}});
               msg(INFO,"update id ok = $id");
            }
         }
         elsif ($op->{OP} eq "delete"){
            if ($op->{IDENTIFYBY} ne ""){
               my $idfield=$dataobj->IdField();
               my $idname=$idfield->Name();
               $dataobj->SetFilter({$idname=>\$op->{IDENTIFYBY}});
               my ($oldrec,$msg)=$dataobj->getOnlyFirst(qw(ALL));
               my $id=$dataobj->ValidatedDeleteRecord($oldrec,
                                                 {$idname=>\$op->{IDENTIFYBY}});
               msg(INFO,"delete id ok = $id");
            }
         }
      }
   }
   #msg(INFO,"ProcessOpList: End");
}




1;

