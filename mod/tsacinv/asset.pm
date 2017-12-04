package tsacinv::asset;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use Data::Dumper;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'assetid',
                label         =>'AssetId',
                size          =>'20',
                uppersearch   =>1,
                searchable    =>1,
                align         =>'left',
                dataobjattr   =>'"assetid"'),

      new kernel::Field::Text(
                name          =>'status',
                label         =>'Status',
                dataobjattr   =>'"status"'),

      new kernel::Field::Boolean(
                name          =>'deleted',
                readonly      =>1,
                label         =>'marked as delete',
                dataobjattr   =>'"deleted"'),

      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'full CI-Name',
                searchable    =>0,
                htmldetail    =>0,
                dataobjattr   =>'"fullname"'),


      new kernel::Field::Text(
                name          =>'systemname',
                vjointo       =>'tsacinv::system',
                vjoinon       =>['lassetid'=>'lassetid'],
                vjoinbase     =>[{status=>"\"!out of operation\"",
                                  deleted=>\'0'}],
                weblinkto     =>'none',
                vjoindisp     =>'systemname',
                label         =>'Systemname'),

      new kernel::Field::Text(
                name          =>'systemid',
                vjointo       =>'tsacinv::system',
                vjoinon       =>['lassetid'=>'lassetid'],
                vjoinbase     =>[{status=>"\"!out of operation\"",
                                  deleted=>\'0'}],
                weblinkto     =>'none',
                vjoindisp     =>'systemid',
                label         =>'SystemID'),

      new kernel::Field::Date(
                name          =>'install',
                label         =>'Install Date',
                timezone      =>'CET',
                #dataobjattr   =>'amasset.dinstall'), # this seems to be dcreate
                dataobjattr   =>'"install"'),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroup',
                label         =>'Assignment Group',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lassignmentid',
                label         =>'AC-AssignmentID',
                dataobjattr   =>'"lassignmentid"'),

      new kernel::Field::Text(
                name          =>'conumber',
                label         =>'CO-Number',
                size          =>'15',
                weblinkto     =>'tsacinv::costcenter',
                weblinkon     =>['lcostcenterid'=>'id'],
                dataobjattr   =>'"conumber"'),

      new kernel::Field::Link(
                name          =>'lcostcenterid',
                label         =>'CostCenterID',
                dataobjattr   =>'"lcostcenterid"'),

      new kernel::Field::Text(
                name          =>'sysconumber',
                vjointo       =>'tsacinv::system',
                vjoinon       =>['lassetid'=>'lassetid'],
                vjoinbase     =>[{status=>"\"!out of operation\"",
                                  deleted=>\'0'}],
                weblinkto     =>'none',
                vjoindisp     =>'conumber',
                label         =>'System CO-Number'),


      new kernel::Field::Import( $self,
                weblinkto     =>'tsacinv::location',
                weblinkon     =>['locationid'=>'locationid'],
                vjointo       =>'tsacinv::location',
                vjoinon       =>['locationid'=>'locationid'],
                group         =>'location',
                fields        =>['fullname','location']),

      new kernel::Field::Text(
                name          =>'room',
                label         =>'Room',
                group         =>"location",
                dataobjattr   =>'"room"'),

      new kernel::Field::Text(
                name          =>'place',
                label         =>'Place',
                group         =>"location",
                dataobjattr   =>'"place"'),

      new kernel::Field::Import( $self,
                weblinkto     =>'tsacinv::model',
                vjointo       =>'tsacinv::model',
                vjoinon       =>['lmodelid'=>'lmodelid'],
                weblinkon     =>['lmodelid'=>'lmodelid'],
                prefix        =>'model',
                group         =>'default',
                fields        =>['name']),

      new kernel::Field::Float(
                name          =>'memory',
                label         =>'Asset Memory',
                unit          =>'MB',
                precision     =>'0',
                dataobjattr   =>'"memory"'),

      new kernel::Field::Text(
                name          =>'cputype',
                label         =>'Asset CPU type',
                dataobjattr   =>'"cputype"'),

      new kernel::Field::Float(
                name          =>'cpucount',
                label         =>'Asset CPU count',
                precision     =>'0',
                dataobjattr   =>'"cpucount"'),

      new kernel::Field::Number(
                name          =>'cpumaxsup',
                htmldetail    =>0,
                label         =>'Asset max. CPU count supported',
                dataobjattr   =>'"cpumaxsup"'),

      new kernel::Field::Float(
                name          =>'cpuspeed',
                label         =>'Asset CPU speed',
                unit          =>'Hz',
                precision     =>'0',
                dataobjattr   =>'"cpuspeed"'),

      new kernel::Field::Float(
                name          =>'corecount',
                label         =>'Asset Core count',
                precision     =>'0',
                dataobjattr   =>'"corecount"'),

      new kernel::Field::Text(
                name          =>'serialno',
                ignorecase    =>1,
                label         =>'Asset Serialnumber',
                dataobjattr   =>'"serialno"'),

      new kernel::Field::Text(
                name          =>'inventoryno',
                label         =>'Asset Inventoryno',
                dataobjattr   =>'"inventoryno"'),

      new kernel::Field::Float(
                name          =>'systemsonasset',
                label         =>'Systems on Asset',
                precision     =>'0',
                searchable    =>0,
                depend        =>[qw(lassetid)],
                onRawValue    =>\&CalcSystemsOnAsset),


      new kernel::Field::TextDrop(
                name          =>'maintlevel',
                label         =>'Maintenance Level',
                group         =>'maint',
                vjointo       =>'tsacinv::contract',
                vjoinon       =>['maintlevelid'=>'contractid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'maintlevelid',
                group         =>'maint',
                label         =>'Maint LevelID',
                dataobjattr   =>'"maintlevelid"'),


      new kernel::Field::Select(
                name          =>'acqumode',
                label         =>'Acquisition Mode',
                group         =>'finanz',
                transprefix   =>'AQMODE.',
                value         =>[0,1,2,3,4,6],
                dataobjattr   =>'"acqumode"'),

      new kernel::Field::Date(
                name          =>'startacquisition',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(0) if ($current->{acqumode}==0);
                   return(1);
                },
                group         =>'finanz',
                depend        =>'acqumode',
                label         =>'Acquisition Start',
                timezone      =>'CET',
                dataobjattr   =>'"startacquisition"'),

      new kernel::Field::Number(
                name          =>'age',
                group         =>'finanz',
                depend        =>['assetid','acqumode','startacquisition'],
                htmldetail    =>0,
                searchable    =>0,
                onRawValue    =>\&CalcDep,
                label         =>'Age',
                unit          =>'days'),

       new kernel::Field::Date(
                name          =>'deprstart',
                group         =>'finanz',
                searchable    =>0,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(1) if ($current->{acqumode}==0);
                   return(0);
                },
                onRawValue    =>\&CalcDep,
                label         =>'Deprecation Start',
                timezone      =>'CET'),


      new kernel::Field::Date(
                name          =>'deprend',
                group         =>'finanz',
                searchable    =>0,
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(1) if ($current->{acqumode}==0);
                   return(0);
                },
                depend        =>['assetid','acqumode'],
                onRawValue    =>\&CalcDep,
                label         =>'Deprecation End',
                timezone      =>'CET'),

      new kernel::Field::Date(
                name          =>'compdeprstart',
                group         =>'finanz',
                depend        =>['assetid','acqumode'],
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(1) if ($current->{acqumode}==0);
                   return(0);
                },
                searchable    =>0,
                onRawValue    =>\&CalcDep,
                label         =>'Component Deprecation Start',
                timezone      =>'CET'),

      new kernel::Field::Date(
                name          =>'compdeprend',
                group         =>'finanz',
                searchable    =>0,
                depend        =>['assetid','acqumode'],
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(1) if ($current->{acqumode}==0);
                   return(0);
                },
                onRawValue    =>\&CalcDep,
                label         =>'Component Deprecation End',
                timezone      =>'CET'),

      new kernel::Field::Currency(
                name          =>'deprbase',
                group         =>'finanz',
                searchable    =>0,
                depend        =>['assetid','acqumode'],
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(1) if ($current->{acqumode}==0);
                   return(0);
                },
                onRawValue    =>\&CalcDep,
                label         =>'deprication base'),

      new kernel::Field::Currency(
                name          =>'residualvalue',
                group         =>'finanz',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(1) if ($current->{acqumode}==0);
                   return(0);
                },
                searchable    =>0,
                depend        =>['assetid','acqumode'],
                onRawValue    =>\&CalcDep,
                label         =>'residual value'),

      new kernel::Field::Currency(
                name          =>'mdepr',
                label         =>'Asset Depr./Month',
                size          =>'20',
                depend        =>['assetid','acqumode'],
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $current=$param{current};
                   return(1) if ($current->{acqumode}==0);
                   return(0);
                },
                group         =>'finanz',
                dataobjattr   =>'"mdepr"'),

      new kernel::Field::Currency(
                name          =>'mmaint',
                label         =>'Asset Maint./Month',
                size          =>'20',
                group         =>'finanz',
                dataobjattr   =>'"mmaint"'),

      new kernel::Field::Float(
                name          =>'powerinput',
                vjointo       =>'tsacinv::model',
                vjoinon       =>['lmodelid'=>'lmodelid'],
                vjoindisp     =>'assetpowerinput',
                label         =>'PowerInput of Asset',
                unit          =>'KVA'),

      new kernel::Field::Text(
                name          =>'maitcond',
                group         =>'maint',
                label         =>'Maintenance Codition',
                dataobjattr   =>'"maitcond"'),

      new kernel::Field::Link(
                name          =>'locationid',
                label         =>'LocationID',
                dataobjattr   =>'"locationid"'),

      new kernel::Field::Link(
                name          =>'lassetid',
                label         =>'LAssetPortfolioId',
                dataobjattr   =>'"lassetid"'),

      new kernel::Field::Link(
                name          =>'lassetassetid',
                label         =>'LAssetId',
                dataobjattr   =>'"lassetassetid"'),

      new kernel::Field::Link(
                name          =>'lmodelid',
                label         =>'LModelId',
                dataobjattr   =>'"lmodelid"'),

      new kernel::Field::SubList(
                name          =>'fixedassets',
                label         =>'Components',
                group         =>'components',
                forwardSearch =>1,
                vjointo       =>'tsacinv::fixedasset',
                vjoinon       =>['lassetassetid'=>'lassetid'],
                vjoindisp     =>['description','deprstart','deprend',
                                 'deprbase']),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>'"replkeypri"'),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>'"replkeysec"'),

      new kernel::Field::Date(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'"cdate"'),

      new kernel::Field::Date(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'"mdate"'),


      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'"srcsys"'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'"srcid"'),

   );
   $self->setWorktable("asset");
   $self->setDefaultView(qw(assetid status tsacinv_locationfullname 
                            systemname serialno));
   return($self);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/asset.jpg?".$cgi->query_string());
}
         

sub CalcSystemsOnAsset
{
   my $self=shift;
   my $current=shift;
   my $sys=$self->getParent->getPersistentModuleObject("CalcSystemsOnAssetobj",
                                                       "tsacinv::system");
   my $assetid=$current->{lassetid};
   return(undef) if ($assetid eq "" || $assetid eq "0");
   $sys->SetFilter({'lassetid'=>$assetid,status=>"\"!out of operation\""});
   my @l=$sys->getHashList(qw(lassetid));
   return($#l+1);
}

sub CalcDep
{
   my $self=shift;
   my $current=shift;
   my $name=$self->Name();
   my $assetid=$current->{assetid};
   my $context=$self->getParent->Context();
   return(undef) if (!defined($assetid) || $assetid eq "");
   if (!defined($context->{CalcDep}->{$assetid})){
      $context->{CalcDep}->{$assetid}=
           $self->getParent->CalcDepr($current,$assetid);
   }
   return($context->{CalcDep}->{$assetid}->{$name});
}

sub CalcDepr
{
   my $self=shift;
   my $current=shift;
   my $assetid=shift;
   my $ac=$self->getPersistentModuleObject("CalcDepr","tsacinv::fixedasset");

   my $compdeprend;
   my $compdeprstart;
   my $deprend;
   my $deprstart;
   my $residualvalue;
   my $deprbase;
   my $age;
   if ($current->{acqumode}==0){
      if ($assetid ne ""){
         $ac->ResetFilter();
         $ac->SetFilter({assetid=>\$assetid});
         my @fal=$ac->getHashList(qw(deprend deprstart deprbase residualvalue));
         my $maxdeprbase=0; 
         foreach my $fa (@fal){
            $maxdeprbase=$fa->{deprbase} if ($fa->{deprbase}>$maxdeprbase);
         }
         foreach my $fa (@fal){
            $residualvalue+=$fa->{residualvalue};
            $deprbase+=$fa->{deprbase};
            if ($maxdeprbase==$fa->{deprbase}){
               $deprend=$fa->{deprend}         if (!defined($deprend));
               $deprstart=$fa->{deprstart}     if (!defined($deprstart));
            }
            else{
               $compdeprend=$fa->{deprend}     if (!defined($compdeprend));
               $compdeprstart=$fa->{deprstart} if (!defined($compdeprstart));
               if ($compdeprend lt $fa->{deprend}){
                  $compdeprend=$fa->{deprend};
               }
               if ($compdeprstart gt $fa->{deprstart}){
                  $compdeprstart=$fa->{deprstart};
               }
            }
         }
      }
      $compdeprend=$deprend     if (!defined($compdeprend));
      $compdeprstart=$deprstart if (!defined($compdeprstart));

      if ($deprstart ne ""){
         my $d=CalcDateDuration($deprstart,NowStamp("en"));
         if (defined($d)){
            $age=int($d->{totaldays});
         }
      }

      

      return({compdeprend=>$compdeprend,compdeprstart=>$compdeprstart,
              deprend=>$deprend,deprstart=>$deprstart,
              deprbase=>$deprbase,
              age=>$age,
              residualvalue=>$residualvalue});
   }
   else{
      my $startacquisition=$current->{startacquisition}; 
      my $age;
      if ($startacquisition ne ""){
         my $d=CalcDateDuration($startacquisition,NowStamp("en"));
         if (defined($d)){
            $age=int($d->{totaldays});
         }
      }

      return({compdeprend=>undef,compdeprstart=>undef,
              deprend=>undef,deprstart=>undef,
              deprbase=>undef,
              age=>$age,
              residualvalue=>undef});
   }
   


}


sub SetFilter
{
   my $self=shift;
   my @flt=@_;

   if ($W5V2::OperationContext eq "W5Replicate"){
      if ($#flt!=0 || ref($flt[0]) ne "HASH"){
         $self->LastMsg("ERROR","invalid Filter request on $self");
         return(undef);
      }

      my %f1=(%{$flt[0]});
      $f1{status}='!"wasted"';

      @flt=([\%f1]);
   }
   return($self->SUPER::SetFilter(@flt));
}




sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_status"))){
     Query->Param("search_status"=>"\"!wasted\"");
   }
   if (!defined(Query->Param("search_deleted"))){
     Query->Param("search_deleted"=>$self->T("no"));
   }
}



sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("ALL");
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   return(undef);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default location maint finanz components source));
}



1;
