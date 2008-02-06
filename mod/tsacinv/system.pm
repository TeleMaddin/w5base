package tsacinv::system;
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
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   
   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'systemid',
                label         =>'SystemId',
                size          =>'13',
                uppersearch   =>1,
                align         =>'left',
                dataobjattr   =>'amportfolio.assettag'),

      new kernel::Field::Text(
                name          =>'systemname',
                label         =>'Systemname',
                uppersearch   =>1,
                size          =>'16',
                dataobjattr   =>'amportfolio.name'),

      new kernel::Field::Text(
                name          =>'conumber',
                label         =>'CO-Number',
                size          =>'15',
                weblinkto     =>'tsacinv::costcenter',
                weblinkon     =>['lcostcenterid'=>'id'],
                dataobjattr   =>'amcostcenter.trimmedtitle'),

      new kernel::Field::Import($self,
                vjointo       =>'tsacinv::location',
                vjoinon       =>['locationid'=>'locationid'],
                group         =>"location",
                fields        =>[qw(fullname location)]),

      new kernel::Field::Link(
                name          =>'lcostcenterid',
                label         =>'CostCenterID',
                dataobjattr   =>'amcostcenter.lcostid'),

      new kernel::Field::Text(
                name          =>'cocustomeroffice',
                label         =>'CO-Number/Customer Office',
                size          =>'20',
                dataobjattr   =>'amcostcenter.customeroffice'),

      new kernel::Field::Text(
                name          =>'bc',
                label         =>'Business Center',
                dataobjattr   =>'amcostcenter.alternatebusinesscenter'),

      new kernel::Field::TextDrop(
                name          =>'assignmentgroup',
                label         =>'Assignment Group',
                vjointo       =>'tsacinv::group',
                vjoinon       =>['lassignmentid'=>'lgroupid'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'lassignmentid',
                label         =>'AC-AssignmentID',
                dataobjattr   =>'amportfolio.lassignmentid'),

      new kernel::Field::Text(
                name          =>'controlcenter',
                weblinkto     =>'tsacinv::group',
                weblinkon     =>['controlcenter'=>'name'],
                label         =>'ControlCenter',
                dataobjattr   =>'amportfolio.controlcenter'),

      new kernel::Field::Text(
                name          =>'status',
                group         =>'form',
                label         =>'Status',
                dataobjattr   =>'amcomputer.status'),

      new kernel::Field::Text(
                name          =>'usage',
                group         =>'form',
                label         =>'Usage',
                dataobjattr   =>'amportfolio.usage'),

      new kernel::Field::Text(
                name          =>'type',
                label         =>'Type',
                group         =>'form',
                dataobjattr   =>'amcomputer.computertype'),

      new kernel::Field::Float(
                name          =>'systemcpucount',
                label         =>'System CPU count',
                unit          =>'CPU',
                precision     =>0,
                dataobjattr   =>'amcomputer.lcpunumber'),

      new kernel::Field::Float(
                name          =>'systemcpuspeed',
                label         =>'System CPU speed',
                unit          =>'MHz',
                precision     =>0,
                dataobjattr   =>'amcomputer.lcpuspeedmhz'),

      new kernel::Field::Float(
                name          =>'systemmemory',
                label         =>'System Memory',
                unit          =>'MB',
                precision     =>0,
                dataobjattr   =>'amcomputer.lmemorysizemb'),

      new kernel::Field::Text(
                name          =>'systemos',
                label         =>'System OS',
                dataobjattr   =>'amcomputer.operatingsystem'),

      new kernel::Field::Float(
                name          =>'partofasset',
                label         =>'System Part of Asset',
                unit          =>'%',
                depend        =>['lassetid'],
                prepRawValue  =>\&SystemPartOfCorrection,
                dataobjattr   =>'amcomputer.psystempartofasset'),

      new kernel::Field::Text(
                name          =>'costallocactive',
                label         =>'Cost allocation active',
                dataobjattr   =>'amcomputer.bcostallocactive'),

      new kernel::Field::Text(
                name          =>'systemola',
                label         =>'System OLA',
                dataobjattr   =>'amcomputer.olaclasssystem'),

      new kernel::Field::Text(
                name          =>'priority',
                label         =>'Priority of system',
                dataobjattr   =>'amportfolio.priority'),

      new kernel::Field::Import($self,
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                weblinkto     =>'tsacinv::asset',
                weblinkon     =>['lassetid'=>'lassetid'],
                prefix        =>"asset",
                group         =>"assetdata",
                fields        =>[qw(assetid serialno inventoryno modelname 
                                    powerinput cpucount cpuspeed
                                    systemsonasset)]),

      new kernel::Field::Import($self,
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                prefix        =>"asset",
                group         =>"assetfinanz",
                fields        =>[qw( mdepr mmaint)]),

      new kernel::Field::Link(
                name          =>'partofassetdec',
                label         =>'System Part of Asset',
                dataobjattr   =>'amcomputer.psystempartofasset'),

      new kernel::Field::Link(
                name          =>'lcomputerid',
                label         =>'AC-ComputerID',
                dataobjattr   =>'amcomputer.lcomputerid'),

      new kernel::Field::Link(
                name          =>'lassetid',
                label         =>'AC-AssetID',
                dataobjattr   =>'amportfolio.lparentid'),

      new kernel::Field::Link(
                name          =>'lportfolioitemid',
                label         =>'PortfolioID',
                dataobjattr   =>'amportfolio.lportfolioitemid'),

      new kernel::Field::Link(
                name          =>'locationid',
                label         =>'AC-LocationID',
                vjointo       =>'tsacinv::asset',
                vjoinon       =>['lassetid'=>'lassetid'],
                vjoindisp     =>'locationid'),

      new kernel::Field::Link(
                name          =>'altbc',
                label         =>'Alternate BC',
                dataobjattr   =>'amcostcenter.alternatebusinesscenter'),

      new kernel::Field::SubList(
                name          =>'services',
                label         =>'Services',
                group         =>'services',
                vjointo       =>'tsacinv::service',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>[qw(name type ammount unit)],
                vjoininhash   =>['name','type','ammount']),

      new kernel::Field::SubList(
                name          =>'ipadresses',
                label         =>'IP-Adresses',
                group         =>'ipaddresses',
                vjointo       =>'tsacinv::ipaddress',
                vjoinon       =>['systemid'=>'systemid'],
                vjoindisp     =>[qw(ipaddress description)]),

      new kernel::Field::SubList(
                name          =>'applications',
                label         =>'Applications',
                group         =>'applications',
                vjointo       =>'tsacinv::lnkapplsystem',
                vjoinon       =>['lportfolioitemid'=>'lchildid'],
                vjoindisp     =>[qw(parent)]),

      new kernel::Field::Dynamic(
                name          =>'dynservices',
                depend        =>[qw(systemid)],
                group         =>'services',
                label         =>'Services Columns',
                fields        =>\&AddServices),

      new kernel::Field::Text(
                name          =>'w5base_appl',
                group         =>'w5basedata',
                searchable    =>0,
                label         =>'W5Base Anwendung',
                onRawValue    =>\&AddW5BaseData,
                depend        =>'systemid'),

      new kernel::Field::Text(
                name          =>'w5base_sem',
                searchable    =>0,
                group         =>'w5basedata',
                label         =>'W5Base SeM',
                onRawValue    =>\&AddW5BaseData,
                depend        =>'systemid'),

      new kernel::Field::Text(
                name          =>'w5base_tsm',
                searchable    =>0,
                group         =>'w5basedata',
                label         =>'W5Base TSM',
                onRawValue    =>\&AddW5BaseData,
                depend        =>'systemid'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'amportfolio.externalsystem'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'amportfolio.externalid'),


   );
   $self->setDefaultView(qw(systemname bc tsacinv_locationfullname systemid assetassetid));
   return($self);
}

sub AddW5BaseData
{
   my $self=shift;
   my $current=shift;
   my $systemid=$current->{systemid};
   my $app=$self->getParent();
   my $c=$self->getParent->Context();
   return(undef) if (!defined($systemid) || $systemid eq "");
   if (!defined($c->{W5BaseSys}->{$systemid})){
      my $w5sys=$app->getPersistentModuleObject("W5BaseSys","itil::system");
      my $w5appl=$app->getPersistentModuleObject("W5BaseAppl","itil::appl");
      $w5sys->ResetFilter();
      $w5sys->SetFilter({systemid=>\$systemid});
      my ($rec,$msg)=$w5sys->getOnlyFirst(qw(applications sem tsm));
      my %l=();
      if (defined($rec)){
         my %appl=();
         my %sem=();
         my %tsm=();
printf STDERR ("fifi x=%s\n",Dumper($rec->{applications}));
         if (defined($rec->{applications}) && 
             ref($rec->{applications}) eq "ARRAY"){
            foreach my $app (@{$rec->{applications}}){
               $appl{$app->{applid}}=$app->{appl};
               $w5appl->ResetFilter();
               $w5appl->SetFilter({id=>\$app->{applid}});
               my ($arec,$msg)=$w5appl->getOnlyFirst(qw(sem semid tsm tsmid));
               if (defined($arec)){
                  $sem{$arec->{semid}}=$arec->{sem};
                  $tsm{$arec->{tsmid}}=$arec->{tsm};
               }
            }
         }
         $l{w5base_appl}=[sort(values(%appl))];
         $l{w5base_sem}=[sort(values(%sem))];
         $l{w5base_tsm}=[sort(values(%tsm))];
      }
printf STDERR ("fifi d=%s\n",Dumper(\%l));
      $c->{W5BaseSys}->{$systemid}=\%l;
   }
   return($c->{W5BaseSys}->{$systemid}->{$self->Name});
   
}

sub AddServices
{
   my $self=shift;
   my %param=@_;
   my @dyn=();
   my $c=$self->Context();
   if (!defined($c->{db})){
      $c->{db}=getModuleObject($self->getParent->Config,"tsacinv::service");
   }
   if (defined($param{current})){
      my $systemid=$param{current}->{systemid};
      $c->{db}->SetFilter({systemid=>\$systemid});
      my @l=$c->{db}->getHashList(qw(name ammount));
      my %sumrec=();
      foreach my $rec (@l){
         $sumrec{$rec->{name}}+=$rec->{ammount};
      }
      foreach my $ola (keys(%sumrec)){
         push(@dyn,$self->getParent->InitFields(
              new kernel::Field::Float(   name       =>'ola'.$ola,
                                          label      =>$ola,
                                          group      =>'services',
                                          htmldetail =>0,
                                          onRawValue =>sub {
                                                       return($sumrec{$ola});
                                                           },
                                          dataobjattr=>'amcomputer.name'
                                      )
             ));
      }
   }
   return(@dyn);
}

sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsac"));
   return(@result) if (defined($result[0]) eq "InitERROR");

   return(1);
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
}
         

sub SystemPartOfCorrection
{
   my $self=shift;
   my $val=shift;
   my $current=shift;
   my $context=$self->Context();

   if (!defined($context->{SystemPartOfobj})){
      $context->{SystemPartOfobj}=getModuleObject($self->getParent->Config,
                                                  "tsacinv::system");
   }
   my $sys=$context->{SystemPartOfobj};

   if (defined($val) && $val==0){             # recalculate "SystemPartOf" if
      my $lassetid=$current->{lassetid};      # value is 0 and not the complete
      if ($lassetid ne ""){                   # asset is distributed to systems
         $sys->SetFilter({lassetid=>\$lassetid});
         my @l=$sys->getHashList(qw(partofassetdec));
         my $nullsys=0;
         my $sumok=0;
         foreach my $rec (@l){
            $sumok+=$rec->{partofassetdec} if ($rec->{partofassetdec}>0);
            $nullsys++ if ($rec->{partofassetdec}==0);
         }
         if ($nullsys>0){
            $val=(1-$sumok)/$nullsys;
         }
      }
   }
   if (defined($val) && $val>0){
      $val=100*$val;
   }
   return($val);
}

sub getSqlFrom
{
   my $self=shift;
   my $from=
      "amcomputer, ".
      "(select amportfolio.* from amportfolio ".
      " where amportfolio.bdelete=0) amportfolio,ammodel,".
      "(select amcostcenter.* from amcostcenter ".
      " where amcostcenter.bdelete=0) amcostcenter";

   return($from);
}

sub initSqlWhere
{
   my $self=shift;
   my $where=
      "amportfolio.lportfolioitemid=amcomputer.litemid ".
      "and amportfolio.lmodelid=ammodel.lmodelid ".
      "and amportfolio.lcostid=amcostcenter.lcostid(+) ".
      "and ammodel.name='LOGICAL SYSTEM' ".
      "and amcomputer.status<>'out of operation'";
   return($where);
}

sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");

   my $MandatorCache=$self->Cache->{Mandator}->{Cache};
   my %altbc=();
   foreach my $grpid (@mandators){
      if (defined($MandatorCache->{grpid}->{$grpid})){
         my $mc=$MandatorCache->{grpid}->{$grpid};
         if (defined($mc->{additional}) &&
             ref($mc->{additional}->{acaltbc}) eq "ARRAY"){
            map({if ($_ ne ""){$altbc{$_}=1;}} @{$mc->{additional}->{acaltbc}});
         }
      }
   }
   my @altbc=keys(%altbc);

   if (!$self->IsMemberOf("admin")){
      my @wild;
      my @fix;
      if ($#altbc!=-1){
         @wild=("\"\"");
         @fix=(undef);
         foreach my $altbc (@altbc){
            if ($altbc=~m/\*/ || $altbc=~m/"/){
               push(@wild,$altbc);
            }
            else{
               push(@fix,$altbc);
            }
         }
      }
      if ($#wild==-1 && $#fix==-1){
         @fix=("NONE");
      }
      my @addflt=();
      if ($#fix!=-1){
         push(@addflt,{altbc=>\@fix});
      }
      if ($#wild!=-1){
         foreach my $wild (@wild){
            push(@addflt,{altbc=>$wild});
         }
      }
      push(@flt,\@addflt);
   }
   return($self->SetFilter(@flt));
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
   return($self->SUPER::getDetailBlockPriority(@_),
          qw(default form location));
}  




1;
