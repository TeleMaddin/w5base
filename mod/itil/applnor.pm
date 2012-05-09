package itil::applnor;
#  W5Base Framework
#  Copyright (C) 2012  Hartmut Vogler (it@guru.de)
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
use itil::appldoc;
@ISA=qw(itil::appldoc);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   $param{Worktable}='applnor';
   $param{doclabel}='-NOR';
   $param{displayall}='1';
   my $self=bless($type->SUPER::new(%param),$type);

   my $ic=$self->getField("isactive");
   $ic->{label}="active NOR certificate";
   $ic->{translation}='itil::applnor';

   $self->AddFields( 
      new kernel::Field::Link(
                name          =>'databossid',
                label         =>'Delivery Manager',
                vjointo       =>'finance::costcenter',
                vjoinon       =>['conumber'=>'name'],
                vjoindisp     =>'delmgrid'),
   );

   $self->AddFields(
      new kernel::Field::Databoss(),
                insertafter=>'mandator'

   );


   $self->AddFields(
      new kernel::Field::Text(
                name          =>'custcontract',
                label         =>'customer contract',
                searchable    =>0,
                onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                container     =>'additional'),
                insertafter=>'name'
   );

   $self->AddFields(
      new kernel::Field::TextDrop(
                name          =>'adv',
                label         =>'relevant ADV',
                readonly      =>'1',
                vjointo       =>'itil::appladv',
                vjoinon       =>['advid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'normodel',
                label         =>'relevant NOR-Solutionmodel',
                readonly      =>'1',
                weblinkto     =>'NONE',
                vjointo       =>'itil::appladv',
                vjoinon       =>['advid'=>'id'],
                vjoindisp     =>'itnormodel'),

      new kernel::Field::TextDrop(
                name          =>'modules',
                label         =>'Modules',
                readonly      =>'1',
                weblinkto     =>'NONE',
                vjointo       =>'itil::appladv',
                vjoinon       =>['advid'=>'id'],
                vjoindisp     =>'modules'),

      new kernel::Field::Boolean(
                name          =>'scddata',
                label         =>'SCD Datahandling',
                readonly      =>'1',
                weblinkto     =>'NONE',
                vjointo       =>'itil::appladv',
                vjoinon       =>['advid'=>'id'],
                vjoindisp     =>'scddata'),

      new kernel::Field::Text(
                name          =>'advid',
                htmldetail    =>0,
                label         =>'linked ADV ID',
                readonly      =>1,
                searchable    =>0,
                onRawValue    =>sub{   # if the record 'isactive' then
                   my $self=shift;     # use the 'isactive' ADV - else
                   my $current=shift;  # use the storedadvid
                   my $app=$self->getParent();
                   if (!defined($current->{isactive}) ||
                       !defined($current->{dstate}) ||
                       $current->{dstate}==10 ||
                       $current->{isactive}==1){
                      if ($current->{srcparentid} ne ""){
                         my $o=getModuleObject($app->Config,"itil::appladv");
                         $o->SetFilter({srcparentid=>\$current->{srcparentid},
                                        isactive=>'1 [EMPTY]'});
                         my ($rec,$msg)=$o->getOnlyFirst(qw(id
                                                            fullname));
                         # you need to select two fields, because selectfix
                         # only effects on views with more then one field!
                         return($rec->{id});
                      }
                   }
                   my $so=$app->getField("storedadvid",$current);
                   my $storedadvid=$so->RawValue($current);
                   return($storedadvid);
                }),

      new kernel::Field::Link(
                name          =>'storedadvid',
                label         =>'stored ADV ID',
                selectfix     =>1,
                readonly      =>1,
                searchable    =>0,
                container     =>'additional'),
   );

   my $adv=getModuleObject($self->Config,"itil::appladv");
   my @allmodules=$adv->getAllPosibleApplModules();
   $self->{allModules}=[];
   while(my $k=shift(@allmodules)){
      shift(@allmodules);
      push(@{$self->{allModules}},$k);
   }

   foreach my $module (@{$self->{allModules}}){
      $self->AddGroup($module,translation=>'itil::appladv');
      $self->AddFields(
         new kernel::Field::Text(
                   name          =>$module."DeliveryCountries", 
                   label         =>"Delivery Countries",
                   group         =>$module,
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                   container     =>"additional"),
         new kernel::Field::Text(
                   name          =>$module."DeliveryOrgs", 
                   label         =>"Delivery Organisations",
                   group         =>$module,
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                   container     =>"additional"),
         new kernel::Field::Textarea(
                   name          =>$module."DeliveryAddresses", 
                   label         =>"Delivery Addresses",
                   group         =>$module,
                   vjoinconcat   =>"\n",
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                   container     =>"additional"),

         new kernel::Field::Boolean(
                   name          =>$module."isSCDconform", 
                   label         =>"SCD conform",
                   group         =>$module,
                   readonly      =>1,
                   markempty     =>1,
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>sub{
                       my $self=shift;
                       return(undef);
                   }),

         new kernel::Field::Text(
                   name          =>$module."DeliveryItemID", 
                   label         =>"Delivery ConfigItem IDs",
                   group         =>$module,
                   htmldetail    =>$self->{displayall},
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                   container     =>"additional"),
         new kernel::Field::Text(
                   name          =>$module."DeliveryGroup", 
                   label         =>"Delivery Groups",
                   group         =>$module,
                   htmldetail    =>$self->{displayall},
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                   container     =>"additional"),
         new kernel::Field::Text(
                   name          =>$module."DeliveryGroupID", 
                   label         =>"Delivery GroupIDs",
                   group         =>$module,
                   htmldetail    =>$self->{displayall},
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                   container     =>"additional"),
         new kernel::Field::Text(
                   name          =>$module."DeliveryContactID", 
                   label         =>"Delivery Contacts",
                   group         =>$module,
                   htmldetail    =>$self->{displayall},
                   extLabelPostfix=>": ".$module,
                   searchable    =>0,
                   onRawValue    =>\&itil::appldoc::handleRawValueAutogenField,
                   container     =>"additional"),
         new kernel::Field::Text(
                   name          =>$module."ADVCountryRest", 
                   label         =>"ADV Country restrictions",
                   group         =>$module,
                   htmldetail    =>$self->{displayall},
                   extLabelPostfix=>": ".$module,
                   readonly      =>1,
                   weblinkto     =>'NONE',
                   vjointo       =>'itil::appladv',
                   vjoinon       =>['advid'=>'id'],
                   vjoindisp     =>$module."CountryRest"),

         new kernel::Field::Boolean(
                   name          =>$module."isCompliant", 
                   label         =>"valid against ADV country restrictions",
                   group         =>$module,
                   extLabelPostfix=>": ".$module,
                   markempty     =>1,
                   depend        =>[$module."ADVCountryRest"],
                   searchable    =>0,
                   readonly      =>1,
                   onRawValue    =>sub{
                       my $self=shift;
                       my $current=shift;
                       my $cur=$current->{$self->{group}."DeliveryCountries"};
                       my $sol=$current->{$self->{group}."ADVCountryRest"};
                       return(1) if ($sol eq "");
                       $cur=[split(/[;,]\s*/,uc($cur))] if (!ref($cur));
                       $sol=[split(/[;,]\s*/,uc($sol))] if (!ref($sol));
                       foreach my $chk (@$cur){
                          if (!in_array($chk,@$sol)){
                             return(0);
                          }
                       }
                       return(1);
                   }),

      );
   }

   $self->AddFields(
      new kernel::Field::Boolean(
                name          =>"SUMMARYisSCDconform", 
                label         =>"total SCD conform",
                group         =>"summary",
                readonly      =>1,
                searchable    =>0,
                onRawValue    =>sub{
                    my $self=shift;
                    return(undef);
                }),

      new kernel::Field::Boolean(
                name          =>"SUMMARYisCompliant", 
                label         =>"total valid against ADV",
                group         =>"summary",
                searchable    =>0,
                readonly      =>1,
                onRawValue    =>sub{
                    my $self=shift;
                    return(0);
                })
   );


   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (effVal($oldrec,$newrec,"dstate")==20){
      $newrec->{storedadvid}=effVal($oldrec,$newrec,"advid");
   }
   return($self->SUPER::Validate($oldrec,$newrec,$origrec));
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   my @l=$self->SUPER::isViewValid($rec);

   my @modules=split(/,\s/,$rec->{modules});
   @modules=@{$modules[0]} if (ref($modules[0]) eq "ARRAY");
   push(@l,"nordef","advdef","summary",@modules);
   return(@l);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   if ($rec->{dstate}<30){
      my @l;
      my @modules=split(/,\s/,$rec->{modules});
      @modules=@{$modules[0]} if (ref($modules[0]) eq "ARRAY");
      push(@l,"nordef","advdef",@modules);
      my $userid=$self->getCurrentUserId();
      return(@l) if ($rec->{databossid} eq $userid ||
                     $rec->{delmgr2id} eq $userid ||
                     $self->IsMemberOf("admin"));
      if ($rec->{delmgrteamid} ne ""){
         return(@l) if ($self->IsMemberOf($rec->{delmgrteamid}));
      }
   }
   return();
}

sub autoFillAutogenField
{
   my $self=shift;
   my $fld=shift;
   my $current=shift;

   if ($fld->{name} eq "MApplDeliveryGroup" || 
       $fld->{name} eq "MApplDeliveryItemID" ||
       $fld->{name} eq "MApplDeliveryGroupID" ||
       $fld->{name} eq "custcontract"){
      my $o=getModuleObject($self->Config,"itil::appl");
      $o->SetFilter({id=>\$current->{srcparentid}});
      my ($rec,$msg)=$o->getOnlyFirst(qw(id businessteam businessteamid 
                                         systems custcontracts));
      if (defined($rec)){
         $self->autoFillAddResultCache(
            ["MApplDeliveryGroupID",
             $rec->{businessteamid},$current->{srcparentid}],
            ["MApplDeliveryGroup",
             $rec->{businessteam}, $current->{srcparentid}],
            ["MApplDeliveryItemID",
             $rec->{id}, $current->{srcparentid}]);

         my %ssystemid=();
         my %systemid=();
         foreach my $s (@{$rec->{systems}}){
            $ssystemid{$s->{systemsystemid}}++ if ($s->{systemsystemid} ne "");
            $systemid{$s->{systemid}}++ if ($s->{systemid} ne "");
         };
         my %con=();
         foreach my $contr (@{$rec->{custcontracts}}){
            if ($contr->{custcontractcistatusid}<=4 &&
                $contr->{custcontractcistatusid}>=2){
               $con{$contr->{custcontract}}++;
            }
         }
         $self->autoFillAddResultCache(
            ["custcontract",
             [keys(%con)], $current->{srcparentid}],
            ["systemsystemid",
             [keys(%ssystemid)], $current->{srcparentid}],
            ["MSystemOSDeliveryItemID",
             [keys(%systemid)], $current->{srcparentid}]);
      }
   }
   elsif (
          $fld->{name} eq "MWebSrvDeliveryGroup" || 
          $fld->{name} eq "MWebSrvDeliveryItemID" ||
          $fld->{name} eq "MWebSrvDeliveryGroupID" ||
          $fld->{name} eq "MDBDeliveryGroup" || 
          $fld->{name} eq "MDBDeliveryItemID" ||
          $fld->{name} eq "MDBDeliveryGroupID"
         ){
      my $swnature="NIX";
      if ($fld->{group} eq "MWebSrv"){
         $swnature='apache iis';
      }
      if ($fld->{group} eq "MDB"){
         $swnature='mysql mssql "Oracle DB Server"';
      }
      my $o=getModuleObject($self->Config,"itil::swinstance");
      $o->SetFilter({applid=>\$current->{srcparentid},
                     swnature=>$swnature,
                     cistatusid=>"<=5"});
      foreach my $rec ($o->getHashList(qw(id swteam swteamid))){
         $self->autoFillAddResultCache(
            [$fld->{group}."DeliveryGroupID",
             $rec->{swteamid},$current->{srcparentid}],
            [$fld->{group}."DeliveryGroup",
             $rec->{swteam}, $current->{srcparentid}],
            [$fld->{group}."DeliveryItemID",
             $rec->{id}, $current->{srcparentid}]);
      }
   }
   elsif ($fld->{name} eq "MSystemOSDeliveryGroupID" ||
          $fld->{name} eq "MSystemOSDeliveryGroup"){
      my $gfld=$self->getField("MApplDeliveryGroup",$current);
      my $refid=$gfld->RawValue($current);
      my $r=$self->autoFillGetResultCache("systemsystemid",
                                          $current->{srcparentid});
      my $o=getModuleObject($self->Config,"itil::system");
      $o->SetFilter({systemid=>$r});
      foreach my $srec ($o->getHashList(qw(adminteam adminteamid))){
         if ($srec->{adminteam} ne ""){
            $self->autoFillAddResultCache(
               ["MSystemOSDeliveryGroupID",
                $srec->{adminteamid},$current->{srcparentid}],
               ["MSystemOSDeliveryGroup",
                $srec->{adminteam},$current->{srcparentid}]);
         }
      }
   }
   elsif ($fld->{name} eq "MHardwareOSDeliveryItemID" ||
          $fld->{name} eq "MHardwareOSDeliveryGroup" ||
          $fld->{name} eq "MHardwareOSDeliveryGroupID"){
      my $gfld=$self->getField("MApplDeliveryGroup",$current);
      my $refid=$gfld->RawValue($current);
      my $r=$self->autoFillGetResultCache("systemsystemid",
                                          $current->{srcparentid});
      my $o=getModuleObject($self->Config,"itil::asset");
      $o->SetFilter({systemids=>$r});
      foreach my $srec ($o->getHashList(qw(location id
                                           guardianteam guardianteamid))){
         $self->autoFillAddResultCache(
            ["MHardwareOSDeliveryItemID", 
             $srec->{id}, $current->{srcparentid}],
            ["MHardwareOSDeliveryGroup", 
             $srec->{guardianteam}, $current->{srcparentid}],
            ["MHardwareOSDeliveryGroupID",
             $srec->{guardianteamid},
             $current->{srcparentid}]);
      }
   }
   elsif ($fld->{name}=~m/^.*DeliveryContactID$/){
      my $gfld=$self->getField($fld->{group}."DeliveryGroupID",$current);
      my $refid=$gfld->RawValue($current);
      if (defined($refid)){
         $refid=[$refid] if (!ref($refid));
         my $o=getModuleObject($self->Config,"base::grp");
         $o->SetFilter({grpid=>$refid,
                        cistatusid=>"<=5"});
         my @uidlist=();
         foreach my $rec ($o->getHashList("users")){
            foreach my $urec (@{$rec->{users}}){
               if ($urec->{usertyp} eq "user" ||
                   $urec->{usertyp} eq "extern"){
                  push(@uidlist,$urec->{userid});
               }
            }
         }
         $self->autoFillAddResultCache([$fld->{name},
                                        \@uidlist,
                                        $current->{srcparentid}]);
      }
   }
   elsif ($fld->{name}=~m/^.*DeliveryAddresses$/){
      my $gfld=$self->getField($fld->{group}."DeliveryContactID",$current);
      my $refid=$gfld->RawValue($current);
      if (defined($refid)){
         my (%uadr,$rec,$msg);
         foreach my $uid (@{$refid}){
            my $adr;
            my $CacheKey="DeliveryContactAddr-".$uid;
            my $r=$self->autoFillGetResultCache($CacheKey);
            if (!defined($r)){
               my $rec=$self->resolvUserID($uid);
               if (defined($rec)){
                  $adr=$rec->{office_zipcode};
                  if ($rec->{office_location} ne ""){
                     $adr.=" " if ($adr ne "");
                     $adr.=$rec->{office_location};
                  }
                  if ($rec->{office_street} ne ""){
                     $adr.="; " if ($adr ne "");
                     $adr.=$rec->{office_street};
                  }
               }
               $adr="unknown/invalid address at '$uid'" if ($adr eq "");
               $self->autoFillAddResultCache([$CacheKey,$adr]);
               $r=$self->autoFillGetResultCache($CacheKey);
            }

            $uadr{$r->[0]}++;
         }
         $self->autoFillAddResultCache(
            [$fld->{name},
             [keys(%uadr)], $current->{srcparentid}]);
      }
   }
   return($self->SUPER::autoFillAutogenField($fld,$current));
}

sub resolvUserID
{
   my $self=shift;
   my $uid=shift;

   my ($rec,$msg);
   if ($uid=~m/^\d{10,20}$/){
      my $o=getModuleObject($self->Config,"base::user");
      ($rec,$msg)=$o->getOnlyFirst({userid=>\$uid},
                                    qw(office_zipcode
                                       office_location
                                       office_street));
   }
   elsif ($uid=~m/^\S{3,8}$/){
      my $o=getModuleObject($self->Config,"base::user");
      ($rec,$msg)=$o->getOnlyFirst({posix=>\$uid},
                                    qw(office_zipcode
                                       office_location
                                       office_street));
   }
   return($rec);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default ),@{$self->{allModules}},qw(summary source));
}












1;
