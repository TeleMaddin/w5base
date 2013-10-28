package itil::appl;
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
use kernel::App::Web::InterviewLink;
use kernel::DataObj::DB;
use kernel::Field;
use kernel::CIStatusTools;
use kernel::MandatorDataACL;
use finance::costcenter;
use kernel::Scene;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB 
        kernel::App::Web::InterviewLink kernel::CIStatusTools
        kernel::MandatorDataACL);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=4 if (!exists($param{MainSearchFieldLines}));
   my $self=bless($type->SUPER::new(%param),$type);
   my $haveitsemexp="costcenter.itsem is not null ".
                    "or costcenter.itsemteam is not null ".
                    "or costcenter.itsem2 is not null";

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                searchable    =>0,
                label         =>'W5BaseID',
                dataobjattr   =>'appl.id'),

      new kernel::Field::RecordUrl(),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                htmlwidth     =>'250px',
                label         =>'Name',
                dataobjattr   =>'appl.name'),

      new kernel::Field::Mandator(),

      new kernel::Field::Interface(
                name          =>'mandatorid',
                dataobjattr   =>'appl.mandator'),

      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                label         =>'CI-State',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Databoss(),

      new kernel::Field::Link(
                name          =>'databossid',
                dataobjattr   =>'appl.databoss'),

      new kernel::Field::TextDrop(
                name          =>'sememail',
                label         =>'Customer Business Manager E-Mail',
                searchable    =>0,
                group         =>'finance',
                htmldetail    =>0,
                uploadable    =>0,
                vjointo       =>'base::user',
                vjoinon       =>['semid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::Link(
                name          =>'servicesupportid',
                dataobjattr   =>'appl.servicesupport'),

      new kernel::Field::Text(
                name          =>'conumber',
                htmleditwidth =>'150px',
                htmlwidth     =>'100px',
                label         =>'Costcenter',
                weblinkto     =>'itil::costcenter',
                weblinkon     =>['conumber'=>'name'],
                dataobjattr   =>'appl.conumber'),

      new kernel::Field::Text(
                name          =>'conodenumber',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                label         =>'Costcenter-Number',
                vjointo       =>'itil::costcenter',
                vjoinon       =>['conumber'=>'name'],
                vjoindisp     =>'conodenumber'),

      new kernel::Field::Text(
                name          =>'allconumbers',
                label         =>'all reference Costcenters',
                readonly      =>1,
                searchable    =>0,
                htmldetail    =>0,
                depend        =>['conumber','systems'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my %co;
                   $co{$current->{conumber}}++;
                   my $fo=$self->getParent->getField("systems");
                   my $sl=$fo->RawValue($current);
                   $sl=[] if (ref($sl) ne "ARRAY");
                   my $s=getModuleObject($self->getParent->Config,
                                         "itil::system");
                   
                   my $fl={id=>[map({$_->{systemid}} @{$sl})]};
                   $s->SetFilter($fl);
                   foreach my $srec ($s->getHashList(qw(conumber))){
                      $co{$srec->{conumber}}++ if ($srec->{conumber} ne "");
                   }
                   return([sort(keys(%co))]);
                }),
       
                


                


      new kernel::Field::Text(
                name          =>'applid',
                htmlwidth     =>'100px',
                htmleditwidth =>'150px',
                label         =>'Application ID',
                dataobjattr   =>'appl.applid'),

      new kernel::Field::Group(
                name          =>'itsemteam',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(1);
                   }
                   return(0);
                },
                group         =>'itsem',
                readonly      =>1,
                label         =>'IT Servicemanagement Team',
                translation   =>'finance::costcenter',
                vjoinon       =>'itsemteamid'),

      new kernel::Field::Link(
                name          =>'itsemteamid',
                group         =>'itsem',
                dataobjattr   =>'costcenter.itsemteam'),

      new kernel::Field::TextDrop(
                name          =>'itsem',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(1);
                   }
                   return(0);
                },
                group         =>'itsem',
                label         =>'IT Servicemanager',
                translation   =>'finance::costcenter',
                readonly      =>1,
                vjointo       =>'base::user',
                vjoinon       =>['itsemid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'itsemid',
                group         =>'itsem',
                dataobjattr   =>'costcenter.itsem'),

      new kernel::Field::TextDrop(
                name          =>'itsem2',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(1);
                   }
                   return(0);
                },
                group         =>'itsem',
                readonly      =>1,
                translation   =>'finance::costcenter',
                label         =>'Deputy IT Servicemanager',
                vjointo       =>'base::user',
                vjoinon       =>['itsem2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Interface(
                name          =>'itsem2id',
                group         =>'itsem',
                dataobjattr   =>'costcenter.itsem2'),



      new kernel::Field::Group(
                name          =>'responseteam',
                group         =>'finance',
                label         =>'CBM Team',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(0);
                   }
                   return(1);
                },
                vjoinon       =>'responseteamid'),

      new itil::appl::Link(
                name          =>'responseteamid',
                wrdataobjattr =>'appl.responseteam',
                dataobjattr   =>"if ($haveitsemexp,".
                                "costcenter.itsemteam,appl.responseteam)"),

      new kernel::Field::Contact(
                name          =>'sem',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                group         =>'finance',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(0);
                   }
                   return(1);
                },
                label         =>'Customer Business Manager',
                vjoinon       =>'semid'),

      new kernel::Field::TextDrop(
                name          =>'sememail',
                group         =>'finance',
                label         =>'Customer Business Manager E-Mail',
                searchable    =>0,
                htmldetail    =>0,
                uploadable    =>0,
                vjointo       =>'base::user',
                vjoinon       =>['semid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'sem2email',
                group         =>'finance',
                label         =>'Deputy Customer Business Manager E-Mail',
                searchable    =>0,
                htmldetail    =>0,
                uploadable    =>0,
                vjointo       =>'base::user',
                vjoinon       =>['sem2id'=>'userid'],
                vjoindisp     =>'email'),

      new itil::appl::Link(
                name          =>'semid',
                wrdataobjattr =>'appl.sem',
                dataobjattr   =>"if ($haveitsemexp,".
                                "costcenter.itsem,appl.sem)"),

      new kernel::Field::Group(
                name          =>'businessteam',
                group         =>'technical',
                label         =>'Business Team',
                vjoinon       =>'businessteamid'),

      new kernel::Field::TextDrop(
                name          =>'businessdepart',
                htmlwidth     =>'300px',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                group         =>'technical',
                label         =>'Business Department',
                vjointo       =>'base::grp',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['businessdepartid'=>'grpid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Link(
                name          =>'businessdepartid',
                searchable    =>0,
                readonly      =>1,
                label         =>'Business Department ID',
                group         =>'technical',
                depend        =>['businessteamid'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $businessteamid=$current->{businessteamid};
                   if ($businessteamid ne ""){
                      my $grp=getModuleObject($self->getParent->Config,
                                              "base::grp");
                      my $businessdepartid=
                         $grp->getParentGroupIdByType($businessteamid,"depart");
                      return($businessdepartid);
                   }
                   return(undef);
                }),

      new kernel::Field::Contact(
                name          =>'tsm',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                group         =>'technical',
                label         =>'Technical Solution Manager',
                vjoinon       =>'tsmid'),

      new kernel::Field::Contact(
                name          =>'opm',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                group         =>'opmgmt',
                label         =>'Operation Manager',
                vjoinon       =>'opmid'),

      new kernel::Field::SubList(
                name          =>'directlicenses',
                label         =>'direct linked Licenses',
                group         =>'licenses',
                allowcleanup  =>1,
                vjointo       =>'itil::lnklicappl',
                vjoinbase     =>[{liccontractcistatusid=>"<=4"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['liccontract','quantity','comments']),

      new kernel::Field::SubList(
                name          =>'swinstances',
                label         =>'Software instances',
                group         =>'swinstances',
                vjointo       =>'itil::swinstance',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['fullname','swnature']),

      new kernel::Field::SubList(
                name          =>'services',
                label         =>'Cluster services',
                group         =>'services',
                vjointo       =>'itil::lnkitclustsvcappl',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['itclustsvc']),

      new kernel::Field::SubList(
                name          =>'businessservices',
                label         =>'provided Businessservices',
                readonly      =>1,
                group         =>'businessservices',
                vjointo       =>'itil::businessservice',
                vjoinon       =>['id'=>'servicecompapplid'],
                vjoindisp     =>['fullname']),

      new kernel::Field::Text(
                name          =>'businessteambossid',
                group         =>'technical',
                label         =>'Business Team Boss ID',
                onRawValue    =>\&getTeamBossID,
                readonly      =>1,
                uivisible     =>0,
                depend        =>['businessteamid']),

      new kernel::Field::Text(
                name          =>'businessteamboss',
                group         =>'technical',
                label         =>'Business Team Boss',
                onRawValue    =>\&getTeamBoss,
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                depend        =>['businessteambossid']),

      new kernel::Field::Text(
                name          =>'businessteambossemail',
                searchable    =>0,
                group         =>'technical',
                label         =>'Business Team Boss EMail',
                onRawValue    =>\&getTeamBossEMail,
                htmldetail    =>0,
                readonly      =>1,
                depend        =>['businessteambossid']),

      new kernel::Field::TextDrop(
                name          =>'tsmemail',
                group         =>'technical',
                label         =>'Technical Solution Manager E-Mail',
                vjointo       =>'base::user',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::TextDrop(
                name          =>'tsmphone',
                group         =>'technical',
                label         =>'Technical Solution Manager Office-Phone',
                vjointo       =>'base::user',
                htmlwidth     =>'200px',
                nowrap        =>1,
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'office_phone'),

      new kernel::Field::TextDrop(
                name          =>'tsmmobile',
                group         =>'technical',
                label         =>'Technical Solution Manager Mobile-Phone',
                vjointo       =>'base::user',
                htmlwidth     =>'200px',
                htmldetail    =>0,
                nowrap        =>1,
                readonly      =>1,
                searchable    =>0,
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'office_mobile'),

      new kernel::Field::TextDrop(
                name          =>'tsmposix',
                group         =>'technical',
                label         =>'Technical Solution Manager POSIX',
                vjointo       =>'base::user',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjoinon       =>['tsmid'=>'userid'],
                vjoindisp     =>'posix'),

      new kernel::Field::Link(
                name          =>'tsmid',
                group         =>'technical',
                dataobjattr   =>'appl.tsm'),

      new kernel::Field::Link(
                name          =>'opmid',
                group         =>'opmgmt',
                dataobjattr   =>'appl.opm'),


      new kernel::Field::TextDrop(
                name          =>'delmgr',
                group         =>'delmgmt',
                readonly      =>1,
                label         =>'Service Delivery Manager',
                translation   =>'finance::costcenter',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(0);
                   }
                   return(1);
                },
                vjointo       =>'base::user',
                vjoinon       =>['delmgrid'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::TextDrop(
                name          =>'delmgr2',
                group         =>'delmgmt',
                readonly      =>1,
                label         =>'Deputy Service Delivery Manager',
                translation   =>'finance::costcenter',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(0);
                   }
                   return(1);
                },
                vjointo       =>'base::user',
                vjoinon       =>['delmgr2id'=>'userid'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Group(
                name          =>'delmgrteam',
                group         =>'delmgmt',
                readonly      =>1,
                translation   =>'finance::costcenter',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(0);
                   }
                   return(1);
                },
                label         =>'Service Delivery-Management Team',
                vjoinon       =>'delmgrteamid'),


      new kernel::Field::Link(
                name          =>'delmgrteamid',
                readonly      =>1,
                dataobjattr   =>"if ($haveitsemexp,".
                                "costcenter.itsemteam,costcenter.delmgrteam)"),

      new kernel::Field::Link(
                name          =>'delmgrid',
                readonly      =>1,
                dataobjattr   =>"if ($haveitsemexp,".
                                "costcenter.itsem,costcenter.delmgr)"),

      new kernel::Field::Link(
                name          =>'delmgr2id',
                readonly      =>1,
                dataobjattr   =>"if ($haveitsemexp,".
                                "costcenter.itsem2,costcenter.delmgr2)"),

      new kernel::Field::Link(
                name          =>'haveitsem',
                readonly      =>1,
                selectfix     =>1,
                dataobjattr   =>"if ($haveitsemexp,1,0)"),

      new kernel::Field::Group(
                name          =>'customer',
                group         =>'customer',
                SoftValidate  =>1,
                label         =>'Customer',
                vjoinon       =>'customerid'),

      new kernel::Field::Link( 
                name          =>'customerid',
                dataobjattr   =>'appl.customer'),

      new kernel::Field::Contact(
                name          =>'sem2',
                AllowEmpty    =>1,
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                group         =>'finance',
                htmldetail    =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   if (defined($param{current}) &&
                       $param{current}->{haveitsem}){
                      return(0);
                   }
                   return(1);
                },
                label         =>'Deputy Customer Business Manager',
                vjoinon       =>'sem2id'),

      new itil::appl::Link(
                name          =>'sem2id',
                dataobjattr   =>"if ($haveitsemexp,".
                                "costcenter.itsem2,appl.sem2)",
                wrdataobjattr =>'appl.sem2'),


      new kernel::Field::Contact(
                name          =>'tsm2',
                AllowEmpty    =>1,
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                group         =>'technical',
                label         =>'Deputy Technical Solution Manager',
                vjoinon       =>'tsm2id'),

      new kernel::Field::Contact(
                name          =>'opm2',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                AllowEmpty    =>1,
                group         =>'opmgmt',
                label         =>'Deputy Operation Manager',
                vjoinon       =>'opm2id'),

      new kernel::Field::TextDrop(
                name          =>'tsm2email',
                group         =>'technical',
                label         =>'Deputy Technical Solution Manager E-Mail',
                vjointo       =>'base::user',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjoinon       =>['tsm2id'=>'userid'],
                vjoindisp     =>'email'),

      new kernel::Field::Link(
                name          =>'tsm2id',
                group         =>'technical',
                dataobjattr   =>'appl.tsm2'),

      new kernel::Field::Link(
                name          =>'opm2id',
                group         =>'opmgmt',
                dataobjattr   =>'appl.opm2'),

      new kernel::Field::Select(
                name          =>'customerprio',
                group         =>'customer',
                label         =>'Customers Application Prioritiy',
                value         =>['1','2','3'],
                default       =>'2',
                htmleditwidth =>'50px',
                dataobjattr   =>'appl.customerprio'),

      new kernel::Field::Select(
                name          =>'criticality',
                group         =>'customer',
                label         =>'Criticality',
                allowempty    =>1,
                value         =>['CRnone','CRlow','CRmedium','CRhigh',
                                 'CRcritical'],
                htmleditwidth =>'100px',
                dataobjattr   =>'appl.criticality'),

      new kernel::Field::Text(
                name          =>'mgmtitemgroup',
                group         =>'customer',
                label         =>'central managed CI groups',
                vjointo       =>'itil::lnkmgmtitemgroup',
                searchable    =>1,
                htmldetail    =>1,
                readonly      =>1,
                vjoinbase     =>{'lnkfrom'=>'<now',
                                 'lnkto'=>'>now OR [EMPTY]',
                                 'grouptype'=>\'PCONTROL',
                                 'mgmtitemgroupcistatusid'=>\'4'},
                weblinkto     =>'NONE',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>'mgmtitemgroup'),

      new kernel::Field::Text(
                name          =>'reportinglabel',
                group         =>'customer',
                label         =>'Reporting Label',
                vjointo       =>'itil::lnkmgmtitemgroup',
                searchable    =>0,
                htmldetail    =>0,
                readonly      =>1,
                vjoinbase     =>{'lnkfrom'=>'<now',
                                 'lnkto'=>'>now OR [EMPTY]',
                                 'grouptype'=>\'RLABEL',
                                 'mgmtitemgroupcistatusid'=>\'4'},
                weblinkto     =>'NONE',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>'mgmtitemgroup'),

      new kernel::Field::Contact(
                name          =>'applowner',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                AllowEmpty    =>1,
                group         =>'customer',
                label         =>'Application Owner',
                vjoinon       =>'applownerid'),

      new kernel::Field::Link(
                name          =>'applownerid',
                group         =>'customer',
                dataobjattr   =>'appl.applowner'),

      new kernel::Field::Contact(
                name          =>'applmgr',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                AllowEmpty    =>1,
                group         =>'customer',
                label         =>'Application Manager',
                vjoinon       =>'applmgrid'),

      new kernel::Field::Interface(
                name          =>'applmgrid',
                group         =>'customer',
                dataobjattr   =>'appl.applmgr'),

      new kernel::Field::Contact(
                name          =>'applmgr2',
                vjoineditbase =>{'cistatusid'=>[3,4,5],
                                 'usertyp'=>[qw(extern user)]},
                AllowEmpty    =>1,
                group         =>'customer',
                label         =>'Deputy Application Manager',
                vjoinon       =>'applmgr2id'),

      new kernel::Field::Interface(
                name          =>'applmgr2id',
                group         =>'customer',
                dataobjattr   =>'appl.applmgr2'),

      new kernel::Field::Text(
                name          =>'itnormodel',
                group         =>'customer',
                label         =>'NOR Model to use',
                searchable    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $app=$self->getParent();
                   my $UC=$self->getParent->Cache->{User}->{Cache};
                   if ($UC->{$ENV{REMOTE_USER}}->{rec}->{dateofvsnfd} ne ""){
                      return(1);
                   }
                   return(0);
                },
                vjoinon       =>['itnormodelid'=>'id'],
                vjointo       =>'itil::itnormodel',
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'itnormodelid',
                group         =>'customer',
                label         =>'NOR ModelID',
                dataobjattr   =>'if (appladv.itnormodel is null,'.
                                '0,appladv.itnormodel)'),

      new kernel::Field::Select(
                name          =>'avgusercount',
                group         =>'customer',
                label         =>'average user count',
                allowempty    =>1,
                value         =>['10','50','100','250',
                                 '500','800','1000','1500','2000','2500','3000',
                                 '4000','5000','7500','10000','12500','15000',
                                 '20000','50000','100000','1000000','10000000'],
                htmleditwidth =>'100px',
                dataobjattr   =>'appl.avgusercount'),

      new kernel::Field::Select(
                name          =>'namedusercount',
                group         =>'customer',
                label         =>'named user count',
                allowempty    =>1,
                value         =>['10','50','100','250',
                                 '500','800','1000','1500','2000','2500','3000',
                                 '4000','5000','7500','10000','12500','15000',
                                 '20000','50000','100000','1000000','10000000'],
                htmleditwidth =>'100px',
                dataobjattr   =>'appl.namedusercount'),

      new kernel::Field::Select(
                name          =>'secstate',
                group         =>'customer',
                label         =>'Security state',
                uivisible     =>sub{
                   my $self=shift;
                   if ($self->getParent->IsMemberOf("admin")){
                      return(1);
                   }
                   return(0);
                },
                allowempty    =>1,
                value         =>['','vsnfd'],
                transprefix   =>'SECST.',
                dataobjattr   =>'appl.secstate'),

      new kernel::Field::Link(
                name          =>'businessteamid',
                dataobjattr   =>'appl.businessteam'),

      new kernel::Field::SubList(
                name          =>'custcontracts',
                label         =>'Customer Contracts',
                group         =>'custcontracts',
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkapplcustcontract',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['custcontract','custcontractcistatus',
                                 'fraction'],
                vjoinbase     =>[{custcontractcistatusid=>'<=5'}],
                vjoininhash   =>['custcontractid','custcontractcistatusid',
                                 'modules',
                                 'custcontract','custcontractname']),

      new kernel::Field::SubList(
                name          =>'interfaces',
                label         =>'Interfaces',
                group         =>'interfaces',
                forwardSearch =>1,
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkapplappl',
                vjoinbase     =>[{toapplcistatus=>"<=5",cistatusid=>"<=5"}],
                vjoinon       =>['id'=>'fromapplid'],
                vjoindisp     =>['toappl','contype','conproto','conmode'],
                vjoininhash   =>['toappl','contype','conproto','conmode',
                                 'toapplid', 'comments']),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                forwardSearch =>1,
                allowcleanup  =>1,
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{systemcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['system','systemsystemid',
                                 'reltyp','systemcistatus',
                                 'shortdesc'],
                vjoininhash   =>['system','systemsystemid','systemcistatus',
                                 'systemid','id']),

      new kernel::Field::SubList(
                name          =>'systemnames',
                label         =>'active systemnames',
                group         =>'systems',
                htmldetail    =>0,
                readonly      =>1,
                htmlwidth     =>'130px',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{systemcistatusid=>"4"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['system']),

      new kernel::Field::SubList(
                name          =>'systemids',
                label         =>'active systemids',
                group         =>'systems',
                htmldetail    =>0,
                readonly      =>1,
                htmlwidth     =>'130px',
                vjointo       =>'itil::lnkapplsystem',
                vjoinbase     =>[{systemcistatusid=>"4"}],
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['systemsystemid']),

      new kernel::Field::Number(
                name          =>'systemcount',
                label         =>'system count',
                group         =>'systems',
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                depend        =>['systems'],
                onRawValue    =>\&calculateSysCount),

      new kernel::Field::Number(
                name          =>'systemslogicalcpucount',
                label         =>'log cpucount',
                group         =>'systems',
                htmldetail    =>0,
                readonly      =>1,
                searchable    =>0,
                depend        =>['id'],
                onRawValue    =>\&calculateLogicalCpuCount),

      new kernel::Field::Number(
                name          =>'systemsrelphyscpucount',
                label         =>'relative phys. cpucount',
                group         =>'systems',
                htmldetail    =>0,
                precision     =>2,
                readonly      =>1,
                searchable    =>0,
                depend        =>['id'],
                onRawValue    =>\&calculateRelPhysCpuCount),

      new kernel::Field::Select(
               name          =>'opmode',
                #group         =>'misc',
                label         =>'primary operation mode',
                transprefix   =>'opmode.',
                value         =>['',
                                 'prod',
                                 'pilot',
                                 'test',
                                 'devel',
                                 'education',
                                'approvtest',
                                'reference',
                                 'cbreakdown'],  # see also opmode at system
                htmleditwidth =>'200px',
               dataobjattr   =>'appl.opmode'),
      new kernel::Field::Text(
                name          =>'applgroup',
                label         =>'Application Group',
                dataobjattr   =>'appl.applgroup'),

      new kernel::Field::Textarea(
                name          =>'description',
                label         =>'Application Description',
                dataobjattr   =>'appl.description'),

      new kernel::Field::Textarea(
                name          =>'currentvers',
                label         =>'Application Version',
                dataobjattr   =>'appl.currentvers'),

      new kernel::Field::Boolean(
                name          =>'allowifupdate',
                group         =>'control',
                label         =>'allow automatic updates by interfaces',
                dataobjattr   =>'appl.allowifupdate'),

      new kernel::Field::Boolean(
                name          =>'sodefinition',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'Application switch-over behaviour defined',
                selectfix     =>1,
                dataobjattr   =>'appl.sodefinition'),

      new kernel::Field::Boolean(
                name          =>'isnosysappl',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'Application has no system components',
                dataobjattr   =>'appl.is_applwithnosys'),

      new kernel::Field::Boolean(
                name          =>'isnoifaceappl',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'Application has no interfaces',
                dataobjattr   =>'appl.is_applwithnoiface'),

      new kernel::Field::Boolean(
                name          =>'isnotarchrelevant',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'Application is not architecture relevant',
                dataobjattr   =>'appl.isnotarchrelevant'),

      new kernel::Field::Boolean(
                name          =>'allowdevrequest',
                group         =>'control',
                searchable    =>0,
                htmleditwidth =>'30%',
                label         =>'allow developer request workflows',
                container     =>'additional'),

      new kernel::Field::Boolean(
                name          =>'allowbusinesreq',
                group         =>'control',
                searchable    =>0,
                htmleditwidth =>'30%',
                label         =>'allow business request workflows',
                container     =>'additional'),

      new kernel::Field::Select(
                name          =>'eventlang',
                group         =>'control',
                htmleditwidth =>'30%',
                value         =>['en','de','en-de','de-en'],
                label         =>'default language for eventinformations',
                dataobjattr   =>'appl.eventlang'),


      new kernel::Field::Boolean(
                name          =>'issoxappl',
                group         =>'control',
                htmleditwidth =>'30%',
                label         =>'Application is mangaged by rules of SOX',
                dataobjattr   =>'appl.is_soxcontroll'),

      new kernel::Field::Text(
                name          =>'mon1url',
                group         =>'control',
                htmldetail    =>0,
                label         =>'Monitoring URL1',
                dataobjattr   =>'appl.mon1url'),

      new kernel::Field::Text(
                name          =>'mon2url',
                group         =>'control',
                htmldetail    =>0,
                label         =>'Monitoring URL2',
                dataobjattr   =>'appl.mon2url'),

      new kernel::Field::TextDrop(
                name          =>'servicesupport',
                label         =>'Service&Support Class',
                group         =>'monisla',
                vjointo       =>'itil::servicesupport',
                vjoineditbase =>{'cistatusid'=>[3,4]},
                vjoinon       =>['servicesupportid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Select(
                name          =>'slacontroltoolname',
                group         =>'monisla',
                label         =>'SLA control tool type',
                allowempty    =>1,
                weblinkto     =>"none",
                vjointo       =>'base::itemizedlist',
                vjoinbase     =>{
                   selectlabel=>\'itil::appl::slacontroltool',
                },
                vjoineditbase =>{
                   selectlabel=>\'itil::appl::slacontroltool',
                   cistatusid=>\'4'
                },
                vjoinon       =>['slacontroltool'=>'name'],
                vjoindisp     =>'displaylabel',
                htmleditwidth =>'200px'),

      new kernel::Field::Link(
                name          =>'slacontroltool',
                group         =>'monisla',
                label         =>'SLA control tool type',
                dataobjattr   =>'appl.slacontroltool'),

      new kernel::Field::Number(
                name          =>'slacontravail',
                group         =>'monisla',
                htmlwidth     =>'100px',
                precision     =>5,
                unit          =>'%',
                searchable    =>0,
                label         =>'SLA availibility guaranted by contract',
                dataobjattr   =>'appl.slacontravail'),

      new kernel::Field::Select(
                name          =>'slacontrbase',
                group         =>'monisla',
                label         =>'SLA availibility calculation base',
                transprefix   =>'slabase.',
                searchable    =>0,
                value         =>['',
                                 'month',
                                 'year'],
                htmleditwidth =>'100px',
                dataobjattr   =>'appl.slacontrbase'),

      new kernel::Field::Select(
                name          =>'applbasemoniname',
                group         =>'monisla',
                label         =>'Application base monitoring',
                allowempty    =>1,
                weblinkto     =>"none",
                vjointo       =>'base::itemizedlist',
                vjoinbase     =>{
                   selectlabel=>\'itil::appl::applbasemoni',
                },
                vjoineditbase =>{
                   selectlabel=>\'itil::appl::applbasemoni',
                   cistatusid=>\'4'
                },
                vjoinon       =>['applbasemoni'=>'name'],
                vjoindisp     =>'displaylabel',
                htmleditwidth =>'200px'),

      new kernel::Field::Link(
                name          =>'applbasemoni',
                group         =>'monisla',
                label         =>'Application base monitoring',
                dataobjattr   =>'appl.applbasemoni'),


      new kernel::Field::Select(
                name          =>'applbasemonistatus',
                group         =>'monisla',
                label         =>'Application base monitoring status',
                transprefix   =>'monistatus.',
                value         =>['',
                                 'NOMONI',
                                 'MONISIMPLE',
                                 'MONIAUTOIN'],
                htmleditwidth =>'280px',
                dataobjattr   =>'appl.applbasemonistatus'),

      new kernel::Field::Group(
                name          =>'applbasemoniteam',
                group         =>'monisla',
                label         =>'Application base monitoring resonsible Team',
                vjoinon       =>'applbasemoniteamid'),

      new kernel::Field::Link(
                name          =>'applbasemoniteamid',
                group         =>'monisla',
                label         =>'Application base monitoring resonsible TeamID',
                dataobjattr   =>'appl.applbasemoniteam'),

      new kernel::Field::Text(
                name          =>'kwords',
                group         =>'misc',
                label         =>'Keywords',
                dataobjattr   =>'appl.kwords'),

      new kernel::Field::Text(
                name          =>'swdepot',
                group         =>'misc',
                label         =>'Software-Depot path',
                dataobjattr   =>'appl.swdepot'),

      new kernel::Field::Textarea(
                name          =>'maintwindow',
                group         =>'misc',
                searchable    =>0, 
                label         =>'Maintenance Window',
                dataobjattr   =>'appl.maintwindow'),

      new kernel::Field::Textarea(
                name          =>'comments',
                group         =>'misc',
                label         =>'Comments',
                searchable    =>0, 
                dataobjattr   =>'appl.comments'),

      new kernel::Field::Textarea(
                name          =>'socomments',
                group         =>'socomments',
                label         =>'comments to switch-over behaviour',
                searchable    =>0, 
                dataobjattr   =>'appl.socomments'),

      new kernel::Field::Number(
                name          =>'soslanumdrtests',
                label         =>'SLA number Desaster-Recovery tests per year',
                group         =>'sodrgroup',
                htmleditwidth =>'120',
                searchable    =>0,
                dataobjattr   =>'appl.soslanumdrtests'),

      new kernel::Field::Number(
                name          =>'sosladrduration',
                label         =>'SLA planned Desaster-Recovery duration',
                group         =>'sodrgroup',
                unit          =>'min',
                searchable    =>0,
                dataobjattr   =>'appl.sosladrduration'),

      new kernel::Field::WorkflowLink(
                name          =>'olastdrtestwf',
                AllowEmpty    =>1,
                label         =>'last Desaster-Recovery test (CHM-WorkflowID)',
                group         =>'sodrgroup',
                vjoinon       =>'olastdrtestwfid'),

      new kernel::Field::Link(
                name          =>'olastdrtestwfid',
                label         =>'last Desaster-Recovery test (CHM-WorkflowID)',
                group         =>'sodrgroup',
                searchable    =>0,
                dataobjattr   =>'appl.solastdrtestwf'),

      new kernel::Field::Date(
                name          =>'solastdrdate',
                label         =>'last Desaster-Recovery test (WorkflowEnd)',
                readonly      =>1,
                dayonly       =>1,
                group         =>'sodrgroup',
                vjointo       =>'base::workflow',
                vjoinon       =>['olastdrtestwfid'=>'id'],
                vjoindisp     =>'eventend',
                searchable    =>0),

      new kernel::Field::Date(
                name          =>'temp_solastdrdate',
                label         =>'last Desaster-Recovery test date (temp)',
                group         =>'sodrgroup',
                searchable    =>0,
                dayonly       =>1,
                dataobjattr   =>'appl.solastdrdate'),

      new kernel::Field::Number(
                name          =>'soslaclustduration',
                label         =>'SLA maximum cluster service '.
                                'take over duration',
                group         =>'soclustgroup',
                searchable    =>0,
                unit          =>'min',
                dataobjattr   =>'appl.soslaclustduration'),

      new kernel::Field::WorkflowLink(
                name          =>'solastclusttestwf',
                label         =>'last Cluster-Service switch '.
                                'test (CHM-WorkflowID)',
                AllowEmpty    =>1,
                group         =>'soclustgroup',
                vjoinon       =>'solastclusttestwfid'),

      new kernel::Field::Link(
                name          =>'solastclusttestwfid',
                htmleditwidth =>'120',
                label         =>'last Cluster-Service switch test (WorkflowID)',
                group         =>'soclustgroup',
                searchable    =>0,
                dataobjattr   =>'appl.solastclusttestwf'),

      new kernel::Field::Date(
                name          =>'solastclustswdate',
                label         =>'last Cluster-Service switch test (WorkflowEnd)',
                group         =>'soclustgroup',
                vjointo       =>'base::workflow',
                vjoinon       =>['solastclusttestwfid'=>'id'],
                vjoindisp     =>'eventend',
                dayonly       =>1,
                readonly      =>1,
                searchable    =>0),

      new kernel::Field::Date(
                name          =>'temp_solastclustswdate',
                label         =>'last Cluster-Service switch date (temp)',
                group         =>'soclustgroup',
                searchable    =>0,
                dayonly       =>1,
                dataobjattr   =>'appl.solastclustswdate'),

      new kernel::Field::FileList(
                name          =>'attachments',
                label         =>'Attachments',
                parentobj     =>'itil::appl',
                group         =>'attachments'),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                htmldetail    =>0,
                uivisible     =>sub{
                   my $self=shift;
                   my $mode=shift;
                   my %param=@_;
                   my $rec=$param{current};
                   if (!defined($rec->{$self->Name()})){
                      return(0);
                   }
                   return(1);
                },
                dataobjattr   =>'appl.additional'),

      new kernel::Field::ContactLnk(
                name          =>'contacts',
                label         =>'Contacts',
                group         =>'contacts'),

      new kernel::Field::PhoneLnk(
                name          =>'phonenumbers',
                searchable    =>0,
                label         =>'Phonenumbers',
                group         =>'phonenumbers',
                vjoinbase     =>[{'parentobj'=>\'itil::appl'}],
                subeditmsk    =>'subedit'),

      new kernel::Field::Text(
                name          =>'customerapplicationname',
                htmldetail    =>0,
                readonly      =>1,
                group         =>'customer',
                label         =>'nameing of application by customer',
                dataobjattr   =>"if (itcrmappl.name is null or ".
                                "itcrmappl.name='',appl.name,itcrmappl.name)"),

      new kernel::Field::Text(
                name          =>'customerapplicationid',
                htmldetail    =>0,
                readonly      =>1,
                group         =>'customer',
                label         =>'ID of application by customer',
                dataobjattr   =>"if (itcrmappl.custapplid is null or ".
                                "itcrmappl.custapplid='',appl.applid,".
                                "itcrmappl.custapplid)"),

      new kernel::Field::SubList(
                name          =>'oncallphones',
                searchable    =>0,
                htmldetail    =>0,
                uivisible     =>1,
                readonly      =>1,
                label         =>'oncall Phonenumbers',
                group         =>'phonenumbers',
                vjoinbase     =>[{'parentobj'=>\'itil::appl'}],
                vjointo       =>'base::phonenumber',
                vjoinon       =>['id'=>'refid'],
                vjoinbase     =>{'rawname'=>'phoneRB'},
                vjoindisp     =>['phonenumber','shortedcomments']),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'appl.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'appl.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                history       =>0,
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'appl.srcload'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"appl.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(appl.id,35,'0')"),

      new kernel::Field::SubList(
                name          =>'accountnumbers',
                label         =>'Account numbers',
                group         =>'accountnumbers',
                allowcleanup  =>1,
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkaccountingno',
                vjoinon       =>['id'=>'applid'],
                vjoindisp     =>['name','cdate','comments']),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Creation-Date',
                dataobjattr   =>'appl.createdate'),
                                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>'appl.modifydate'),

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'appl.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'appl.modifyuser'),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'appl.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'appl.realeditor'),

      new kernel::Field::Link(
                name          =>'sectarget',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.target'),

      new kernel::Field::Link(
                name          =>'sectargetid',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.targetid'),

      new kernel::Field::Link(
                name          =>'secroles',
                noselect      =>'1',
                dataobjattr   =>'lnkcontact.croles'),

      new kernel::Field::XMLInterface(
                name          =>'itemsummary',
                label         =>'total Config-Item Summary',
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $parrent=$self->getParent();
                   my $summary={};
                   my $bk=0;
                   if ($parrent->can("ItemSummary")){
                      $bk=$parrent->ItemSummary($current,$summary);
                   }
                   if ($bk){
                      $summary->{xmlstate}="valid";
                      return({xmlroot=>$summary}); 
                   }
                   return({xmlroot=>{xmlstate=>"invalid"}});
                }),

      new kernel::Field::Email(
                name          =>'wfdataeventnotifytargets',
                label         =>'WF:event notification customer info targets',
                htmldetail    =>0,
                searchable    =>0,
                uploadable    =>0,
                group         =>'workflowbasedata',
                onRawValue    =>\&getWfEventNotifyTargets),
      new kernel::Field::Interview(),
      new kernel::Field::QualityText(),
      new kernel::Field::IssueState(),
      new kernel::Field::QualityState(),
      new kernel::Field::QualityOk(),
      new kernel::Field::QualityLastDate(
                dataobjattr   =>'appl.lastqcheck'),
      new kernel::Field::QualityResponseArea()
   );
   $self->AddGroup("external",translation=>'itil::appl');
   $self->{history}=[qw(insert modify delete)];
   $self->{workflowlink}={ workflowkey=>[id=>'affectedapplicationid']
                         };
   $self->{use_distinct}=1;
   $self->{PhoneLnkUsage}=\&PhoneUsage;
   $self->setDefaultView(qw(name mandator cistatus mdate));
   $self->setWorktable("appl");
   return($self);
}


sub ItemSummary
{
   my $self=shift;
   my $current=shift;
   my $summary=shift;

   my $o=getModuleObject($self->Config,$self->Self);
   $o->SetFilter({id=>\$current->{id}});
   my ($rec,$msg)=$o->getOnlyFirst("systems");
   Dumper($rec);
   $summary->{systems}=$rec->{systems};
   return(1) if ($o->Ping());
}


sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}

sub getFieldObjsByView
{
   my $self=shift;
   my $view=shift;
   my %param=@_;

   my @l=$self->SUPER::getFieldObjsByView($view,%param);

   # 
   # hack to prevent display of "itnormodel" in outputs other then
   # Standard-Detail
   # 
   if (defined($param{current}) && exists($param{current}->{itnormodel})){
      if ($param{output} ne "kernel::Output::HtmlDetail"){
         if (!$self->IsMemberOf("admin")){
            @l=grep({$_->{name} ne "itnormodel"} @l);
         }
      }
   }


   return(@l);
}


sub InterviewPartners
{
   my $self=shift;
   my $rec=shift;


   return(''=>$self->T("Databoss"),
          'INTERVApplicationMgr'   =>'ApplicationManager',
          'INTERVSystemTechContact'=>'TechnicalContact') if (!defined($rec));
   my %g=();
   $g{''}=[$rec->{'databossid'}] if (exists($rec->{'databossid'}) &&
                                     $rec->{'databossid'} ne "");
   my @amgr=();
   push(@amgr,$rec->{applmgrid}) if ($rec->{applmgrid} ne "");
   push(@amgr,$rec->{applmgr2id}) if ($rec->{applmgr2id} ne "");
   $g{'INTERVApplicationMgr'}=\@amgr if ($#amgr!=-1);

   my @tsm=();
   push(@tsm,$rec->{tsmid}) if ($rec->{tsmid} ne "");
   push(@tsm,$rec->{tsm2id}) if ($rec->{tsm2id} ne "");
   $g{'INTERVSystemTechContact'}=\@tsm if ($#tsm!=-1);

   return(%g);
}


# 
#  Sub: getTeamBossID
#
#  Calculates the userid of the business team boss.
#
#  Parameters:
#
#     rec        - current record
#
#  Returns:
#
#     array refernce - the list of  userids of team bosses.
#
sub getTeamBossID
{
   my $self=shift;
   my $current=shift;
   my $teamfieldname=$self->{depend}->[0];
   my $teamfield=$self->getParent->getField($teamfieldname);
   my $teamid=$teamfield->RawValue($current);
   my @teambossid=();
   if ($teamid ne ""){
      my $lnk=getModuleObject($self->getParent->Config,
                              "base::lnkgrpuser");
      $lnk->SetFilter({grpid=>\$teamid,
                       nativroles=>'RBoss'});
      foreach my $rec ($lnk->getHashList("userid")){
         if ($rec->{userid} ne ""){
            push(@teambossid,$rec->{userid});
         }
      }
   }
   return(\@teambossid);
}


sub getTeamBoss
{
   my $self=shift;
   my $current=shift;
   my $teambossfieldname=$self->{depend}->[0];
   my $teambossfield=$self->getParent->getField($teambossfieldname);
   my $teambossid=$teambossfield->RawValue($current);
   my @teamboss;
   if ($teambossid ne "" && ref($teambossid) eq "ARRAY" && $#{$teambossid}>-1){
      my $user=getModuleObject($self->getParent->Config,"base::user");
      $user->SetFilter({userid=>$teambossid});
      foreach my $rec ($user->getHashList("fullname")){
         if ($rec->{fullname} ne ""){
            push(@teamboss,$rec->{fullname});
         }
      }
   }
   return(\@teamboss);
}

sub getTeamBossEMail
{
   my $self=shift;
   my $current=shift;
   my $teambossfieldname=$self->{depend}->[0];
   my $teambossfield=$self->getParent->getField($teambossfieldname);
   my $teambossid=$teambossfield->RawValue($current);
   my @teamboss;
   if ($teambossid ne "" && ref($teambossid) eq "ARRAY" && $#{$teambossid}>-1){
      my $user=getModuleObject($self->getParent->Config,"base::user");
      $user->SetFilter({userid=>$teambossid});
      foreach my $rec ($user->getHashList("email")){
         if ($rec->{email} ne ""){
            push(@teamboss,$rec->{email});
         }
      }
   }
   return(\@teamboss);
}



sub calculateLogicalCpuCount
{
   my $self=shift;
   my $current=shift;
   my $applid=$current->{id};

   my $l=getModuleObject($self->getParent->Config(),"itil::lnkapplsystem");
   $l->SetFilter({applid=>\$applid,systemcistatusid=>[qw(3 4 5)]});

   my $cpucount;
   foreach my $lrec ($l->getHashList(qw(logicalcpucount))){
      $cpucount+=$lrec->{logicalcpucount};
   }
   return($cpucount);
}

sub calculateRelPhysCpuCount
{
   my $self=shift;
   my $current=shift;
   my $applid=$current->{id};

   my $l=getModuleObject($self->getParent->Config(),"itil::lnkapplsystem");
   $l->SetFilter({applid=>\$applid,systemcistatusid=>[qw(3 4 5)]});

   my $cpucount;
   foreach my $lrec ($l->getHashList(qw(relphysicalcpucount))){
      $cpucount+=$lrec->{relphysicalcpucount};
   }
   return($cpucount);
}

sub calculateSysCount
{
   my $self=shift;
   my $current=shift;
   my $sysfld=$self->getParent->getField("systems");
   my $s=$sysfld->RawValue($current);
   return(0) if (!ref($s) eq "ARRAY");
   return($#{$s}+1);
}



sub getWfEventNotifyTargets     # calculates the target email addresses
{                               # for an customer information in
   my $self=shift;              # itil::workflow::eventnotify
   my $current=shift;
   my $emailto={};

   my $applid=$current->{id};
   my $ia=getModuleObject($self->getParent->Config,"base::infoabo");
   my $appl=getModuleObject($self->getParent->Config,"itil::appl");
   $appl->SetFilter({id=>\$applid});


   my @byfunc;
   my @byorg;
   my @team;
   my %allcustgrp;
   foreach my $rec ($appl->getHashList(qw(semid sem2id tsmid tsm2id delmgrid
                                          opmid 
                                          responseteamid customerid 
                                          businessteamid))){
      foreach my $v (qw(semid sem2id tsmid tsm2id delmgrid opmid)){
         my $fo=$appl->getField($v);
         my $userid=$appl->getField($v)->RawValue($rec);
         push(@byfunc,$userid) if ($userid ne "" && $userid>0);
      }
      foreach my $v (qw(responseteamid businessteamid)){
         my $grpid=$rec->{$v};
         push(@team,$grpid) if ($grpid>0);
      }
      if ($rec->{customerid}!=0){
         $self->getParent->LoadGroups(\%allcustgrp,"up",
                                      $rec->{customerid});
         
      }
   }
   if (keys(%allcustgrp)){
      $ia->LoadTargets($emailto,'base::grp',\'eventnotify',
                                [keys(%allcustgrp)]);
   }
   $ia->LoadTargets($emailto,'*::appl *::custappl',\'eventnotify',
                             $applid);
   $ia->LoadTargets($emailto,'base::staticinfoabo',\'eventnotify',
                             '100000002',\@byfunc,default=>1);

   my $grp=getModuleObject($self->getParent->Config,"base::grp");
   for(my $level=0;$level<=100;$level++){
      my @nextlevel=();
      $grp->ResetFilter();
      $grp->SetFilter({grpid=>\@team});
      foreach my $rec ($grp->getHashList(qw(users parentid))){ 
         push(@nextlevel,$rec->{parentid}) if ($rec->{parentid}>0);
         if (ref($rec->{users}) eq "ARRAY"){
            foreach my $user (@{$rec->{users}}){
               if (ref($user->{roles}) eq "ARRAY" &&
                   (grep(/^RBoss$/,@{$user->{roles}}) ||
                    grep(/^RBoss2$/,@{$user->{roles}}))){
                  push(@byorg,$user->{userid});
               }
            }
         }
  #       print STDERR Dumper($rec);
      }
      if ($#nextlevel!=-1){
         @team=@nextlevel;
      }
      else{
         last;
      }
   }
  # print STDERR "byorg=".Dumper(\@byorg);
   $ia->LoadTargets($emailto,'base::staticinfoabo',\'STEVeventinfobyorg',
                             '100000001',\@byorg,default=>1);



   return([sort(keys(%$emailto))]);
}


sub PhoneUsage
{
   my $self=shift;
   my $current=shift;
   my @codes=qw(phoneRB phoneMVD phoneMISC phoneDEV);
   my @l;
   foreach my $code (@codes){
      push(@l,$code,$self->T($code));
   }
   return(@l);

}


sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/appl.jpg?".$cgi->query_string());
}

#sub getRecordWatermarkUrl
#{
#   my $self=shift;
#   my $rec=shift;
#   if ($rec->{secstate} eq "vsnfd"){
#      my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#      return("../../../public/itil/load/HtmlDetail.watermark.vsnfd.jpg?".
#             $cgi->query_string());
#   }
#   return(undef);
#}




sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();
   my $from="$worktable left outer join lnkcontact ".
            "on lnkcontact.parentobj='$selfasparent' ".
            "and $worktable.id=lnkcontact.refid ".
            "left outer join appladv on (appl.id=appladv.appl and ".
            "appladv.isactive=1) ".
            "left outer join itcrmappl on appl.id=itcrmappl.id ".
            "left outer join costcenter on appl.conumber=costcenter.name";

   return($from);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (
      #!$self->isDirectFilter(@flt) && 
       !$self->IsMemberOf([qw(admin w5base.itil.appl.read w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                          [orgRoles(),qw(RMember RCFManager RCFManager2 
                                         RAuditor RMonitor)],"both");
      my @grpids=keys(%grps);

      my $userid=$self->getCurrentUserId();
      my @addflt=(
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"}
                );
      if ($ENV{REMOTE_USER} ne "anonymous"){
         push(@addflt,
                    {mandatorid=>\@mandators},
                    {databossid=>\$userid},
                    {semid=>\$userid},       {sem2id=>\$userid},
                    {tsmid=>\$userid},       {tsm2id=>\$userid},
                    {opmid=>\$userid},       {opm2id=>\$userid},
                    {delmgrid=>\$userid},    {delmgr2id=>\$userid},
                    {businessteamid=>\@grpids},
                    {responseteamid=>\@grpids}
                   );
      }
      push(@flt,\@addflt);
      
   }
   return($self->SetFilter(@flt));
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::appl");
}
         

sub SecureValidate
{
   return(kernel::DataObj::SecureValidate(@_));
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $name=trim(effVal($oldrec,$newrec,"name"));
   
   if (length($name)<3 || haveSpecialChar($name) ||
       ($name=~m/^\d+$/)){   # only numbers as application name is not ok!
      $self->LastMsg(ERROR,
           sprintf($self->T("invalid application name '%s' specified"),$name));
      return(0);
   }
   if (exists($newrec->{name}) && $newrec->{name} ne $name){
      $newrec->{name}=$name;
   }
   if ((my $swdepot=effVal($oldrec,$newrec,"swdepot")) ne ""){
      if (!($swdepot=~m#^(https|http)://[a-z0-9A-Z_/.:]/[a-z0-9A-Z_/.]*$#) &&
          !($swdepot=~m#^[a-z0-9A-Z_/.]+:/[a-z0-9A-Z_/.]*$#)){
         $self->LastMsg(ERROR,"invalid swdepot path spec");
         return(0);
      }
   }

   if (defined($newrec->{slacontravail})){
      if ($newrec->{slacontravail}>100 || $newrec->{slacontravail}<0){
         my $fo=$self->getField("slacontravail");
         my $msg=sprintf($self->T("value of '%s' is not allowed"),$fo->Label());
         $self->LastMsg(ERROR,$msg);
         return(0);
      }
   }
   if (exists($newrec->{conumber}) && $newrec->{conumber} ne ""){
      if (!$self->finance::costcenter::ValidateCONumber(
          $self->SelfAsParentObject,"conumber", $oldrec,$newrec)){
         $self->LastMsg(ERROR,
             $self->T("invalid number format '\%s' specified",
                      "finance::costcenter"),$newrec->{conumber});
         return(0);
      }
   }
   foreach my $v (qw(avgusercount namedusercount)){
      $newrec->{$v}=undef if (exists($newrec->{$v}) && $newrec->{$v} eq "");
   }

   ########################################################################
   # standard security handling
   #
   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      my $userid=$self->getCurrentUserId();
      if (!defined($oldrec)){
         if (!defined($newrec->{databossid}) ||
             $newrec->{databossid}==0){
            my $userid=$self->getCurrentUserId();
            $newrec->{databossid}=$userid;
         }
      }
      if (defined($newrec->{databossid}) &&
          $newrec->{databossid}!=$userid &&
          $newrec->{databossid}!=$oldrec->{databossid}){
         $self->LastMsg(ERROR,"you are not authorized to set other persons ".
                              "as databoss");
         return(0);
      }
   }
   ########################################################################
   if (defined($newrec->{applid})){
      $newrec->{applid}=trim($newrec->{applid});
   }
   if (effVal($oldrec,$newrec,"applid")=~m/^\s*$/){
      $newrec->{applid}=undef;
   }
   ########################################################################
   if (!defined($oldrec) && !exists($newrec->{eventlang})){
      $newrec->{eventlang}=$self->Lang(); 
   }

   return(0) if (!$self->HandleCIStatusModification($oldrec,$newrec,"name"));
   return(1);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   $self->NotifyOnCIStatusChange($oldrec,$newrec);
   $self->NotifyAddOrRemoveObject($oldrec,$newrec,"name",
                                  "STEVapplchanged",100000003);
   return($bak);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   my @all=qw(accountnumbers history default applapplgroup applgroup
              attachments contacts control custcontracts customer delmgmt
              finance interfaces licenses monisla qc external itsem
              misc opmgmt phonenumbers services businessservices architect
              soclustgroup socomments sodrgroup source swinstances systems
              technical workflowbasedata header inmchm interview efforts);
   if (!$rec->{sodefinition}){
      @all=grep(!/^(socomments|soclustgroup|sodrgroup)$/,@all);
   }

   return(@all);
}


sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   my $userid=$self->getCurrentUserId();

   my @databossedit=qw(default interfaces finance opmgmt technical contacts misc
                       systems attachments accountnumbers interview
                       customer control phonenumbers monisla architect
                       sodrgroup soclustgroup socomments);
   if (!defined($rec)){
      return(@databossedit);
   }
   else{
      if ($rec->{haveitsem}){
         @databossedit=grep(!/^finance$/,@databossedit);
      }
      if ($self->IsMemberOf("admin")){
         return(@databossedit);
      }
      if ($rec->{databossid}==$userid){
         return($self->expandByDataACL($rec->{mandatorid},@databossedit));
      }
      if (defined($rec->{contacts}) && ref($rec->{contacts}) eq "ARRAY"){
         my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                                     ["RMember"],"both");
         my @grpids=keys(%grps);
         foreach my $contact (@{$rec->{contacts}}){
            if ($contact->{target} eq "base::user" &&
                $contact->{targetid} ne $userid){
               next;
            }
            if ($contact->{target} eq "base::grp"){
               my $grpid=$contact->{targetid};
               next if (!grep(/^$grpid$/,@grpids));
            }
            my @roles=($contact->{roles});
            @roles=@{$contact->{roles}} if (ref($contact->{roles}) eq "ARRAY");
            if (grep(/^write$/,@roles)){
               return($self->expandByDataACL($rec->{mandatorid},@databossedit));
            }
         }
      }
      if ($rec->{mandatorid}!=0 && 
         $self->IsMemberOf($rec->{mandatorid},["RDataAdmin",
                                               "RCFManager",
                                               "RCFManager2"],
                           "down")){
         return($self->expandByDataACL($rec->{mandatorid},@databossedit));
      }
      if ($rec->{businessteamid}!=0 && 
         $self->IsMemberOf($rec->{businessteamid},["RCFManager",
                                                   "RCFManager2"],
                           "down")){
         return($self->expandByDataACL($rec->{mandatorid},@databossedit));
      }
      if ($rec->{responseteamid}!=0 && 
         $self->IsMemberOf($rec->{responseteamid},["RCFManager",
                                                   "RCFManager2"],
                           "down")){
         return($self->expandByDataACL($rec->{mandatorid},@databossedit));
      }
   }
   return($self->expandByDataACL($rec->{mandatorid}));
}

sub FinishDelete
{
   my $self=shift;
   my $oldrec=shift;
   my $bak=$self->SUPER::FinishDelete($oldrec);

   my $refobj=getModuleObject($self->Config,"itil::lnkapplcustcontract");
   if (defined($refobj)){
      my $idname=$self->IdField->Name();
      my $id=$oldrec->{$idname};
      $refobj->SetFilter({'appl'=>\$id});
      $refobj->SetCurrentView(qw(ALL));
      $refobj->ForeachFilteredRecord(sub{
                         $refobj->ValidatedDeleteRecord($_);
                      });
   }
   my $refobj=getModuleObject($self->Config,"itil::lnkapplappl");
   if (defined($refobj)){
      my $idname=$self->IdField->Name();
      my $id=$oldrec->{$idname};
      $refobj->SetFilter({'fromapplid'=>\$id});
      $refobj->SetCurrentView(qw(ALL));
      $refobj->ForeachFilteredRecord(sub{
                         $refobj->ValidatedDeleteRecord($_);
                      });
   }
   $self->NotifyAddOrRemoveObject($oldrec,undef,"name",
                                  "STEVapplchanged",100000003);
   return($bak);
}

sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;
   my $lock=0;

   my $refobj=getModuleObject($self->Config,"itil::lnkapplappl");
   if (defined($refobj)){
      my $idname=$self->IdField->Name();
      my $id=$rec->{$idname};
      $refobj->SetFilter({'toapplid'=>\$id});
      $lock++ if ($refobj->CountRecords()>0);
   }
   if ($lock>0 ||
       $#{$rec->{systems}}!=-1 ||
       $#{$rec->{services}}!=-1 ||
       $#{$rec->{swinstances}}!=-1 ||
       $#{$rec->{custcontracts}}!=-1){
      $self->LastMsg(ERROR,
          "delete only posible, if there are no system, ".
          "software instance and contract relations");
      return(0);
   }

   return(1);
}



sub getDetailBlockPriority
{
   my $self=shift;
   return(
          qw(header default itsem finance technical opmgmt delmgmt 
             architect customer custcontracts 
             contacts phonenumbers 
             interfaces systems swinstances services businessservices monisla
             misc attachments control 
             sodrgroup soclustgroup socomments accountnumbers licenses 
             external source));
}

sub HandleInfoAboSubscribe
{
   my $self=shift;
   my $id=Query->Param("CurrentIdToEdit");
   my $ia=$self->getPersistentModuleObject("base::infoabo");
   if ($id ne ""){
      $self->ResetFilter();
      $self->SetFilter({id=>\$id});
      my ($rec,$msg)=$self->getOnlyFirst(qw(name));
      print($ia->WinHandleInfoAboSubscribe({},
                      $self->SelfAsParentObject(),$id,$rec->{name},
                      "base::staticinfoabo",undef,undef));
   }
   else{
      print($self->noAccess());
   }
}


#sub getHtmlDetailPages
#{
#   my $self=shift;
#   my ($p,$rec)=@_;
#
#   my @l=$self->SUPER::getHtmlDetailPages($p,$rec);
#   if (defined($rec)){
#      push(@l,"OPInfo"=>$self->T("OperatorInfo"));
#   }
#   return(@l);
#}


#sub getHtmlDetailPageContent
#{
#   my $self=shift;
#   my ($p,$rec)=@_;
#
#   my $page;
#   my $idname=$self->IdField->Name();
#   my $idval=$rec->{$idname};
#
#   return($self->SUPER::getHtmlDetailPageContent($p,$rec)) if ($p ne "OPInfo");
#
#   if ($p eq "OPInfo"){
#      Query->Param("$idname"=>$idval);
#      $idval="NONE" if ($idval eq "");
#
#      my $q=new kernel::cgi({});
#      $q->Param("$idname"=>$idval);
#      my $urlparam=$q->QueryString();
#      $page.="<iframe class=HtmlDetailPage name=HtmlDetailPage ".
#            "src=\"OPInfo?$urlparam\"></iframe>";
#   }
#   $page.=$self->HtmlPersistentVariables($idname);
#   return($page);
#}

sub getValidWebFunctions
{
   my $self=shift;

   return($self->SUPER::getValidWebFunctions(@_),"Scene");
}



sub SceneHeader
{
   my $self=shift;
   my @js;
   foreach my $l (qw(lib/raphael.js lib/jquery-1.8.1.min.js 
                     lib/jquery-ui-1.8.23.custom.min.js 
                     lib/jquery.layout.js lib/jquery.autoresize.js 
                     lib/jquery-touch_punch.js lib/jquery.contextmenu.js 
                     lib/rgbcolor.js lib/canvg.js lib/Class.js 
                     lib/json2.js src/draw2d.js)){
      push(@js,"../../../../../static/draw2d/".$l);

   }

}


sub Scene
{
   my $self=shift;

   print $self->HttpHeader();
   print $self->HtmlHeader(title=>"Scene",
      style=>['../../../../../static/draw2d/css/contextmenu.css',
             ]);

   #######################################################################
   my $path;
   if (defined(Query->Param("FunctionPath"))){
      $path=Query->Param("FunctionPath");
   }
   $path=~s/\///;
   my ($id,$scene)=split(/\//,$path);
   my $dataobj=$self->Self();
   #######################################################################


   my $s=new kernel::Scene("gfx_holder");
   print $s->htmlBootstrap();
   print $s->htmlContainer();

   $s->addShape("defid","draw2d.shape.node.Start",50,50);
   $s->addShape("defid","draw2d.shape.node.End",150,150);
   $s->addShape("defid","draw2d.shape.basic.Rectangle",250,150);

   print $s->renderedScene();
   print $self->HtmlBottom(body=>1);
}

sub HtmlPublicDetail   # for display record in QuickFinder or with no access
{
   my $self=shift;
   my $rec=shift;
   my $header=shift;   # create a header with fullname or name

   my $htmlresult="";
   if ($header){
      $htmlresult.="<table style='margin:5px'>\n";
      $htmlresult.="<tr><td colspan=2 align=center><h1>";
      $htmlresult.=$self->findtemplvar({current=>$rec,mode=>"Html"},
                                      "name","formated");
      $htmlresult.="</h1></td></tr>";
   }
   else{
      $htmlresult.="<table>\n";
   }
   my @l=qw(sem sem2 delmgr delmgr2 tsm tsm2 databoss businessteam systemnames);
   foreach my $v (@l){
      if ($v eq "systemnames"){
         my $name=$self->getField($v)->Label();
         my $data;
         if (ref($rec->{$v}) eq "ARRAY"){
            $data=join("; ",sort(map({$_->{system}} @{$rec->{$v}})));
            if ($data ne ""){
               $htmlresult.="<tr><td nowrap valign=top width=1%>$name:</td>".
                            "<td valign=top>$data</td></tr>\n";
            }
         }
      }
      elsif ($rec->{$v} ne ""){
         my $name=$self->getField($v)->Label();
         my $data=$self->findtemplvar({current=>$rec,mode=>"Html"},
                                      $v,"formated");
         $htmlresult.="<tr><td nowrap valign=top width=1%>$name:</td>".
                      "<td valign=top>$data</td></tr>\n";
      }
   }

   if (my $pn=$self->getField("phonenumbers")){
      $htmlresult.=$pn->FormatForHtmlPublicDetail($rec,["phoneRB"]);
   }
   $htmlresult.="</table>\n";
   if ($rec->{description} ne ""){
      my $desclabel=$self->getField("description")->Label();
      my $desc=$rec->{description};
      $desc=~s/\n/<br>\n/g;

      $htmlresult.="<table><tr><td>".
                   "<div style=\"height:60px;overflow:auto;color:gray\">".
                   "\n<font color=black>$desclabel:</font><div>\n$desc".
                   "</div></div>\n</td></tr></table>";
   }
   return($htmlresult);

}


#############################################################################

package itil::appl::Link;

use strict;
use vars qw(@ISA);
@ISA    = qw(kernel::Field::Link);


sub new
{
   my $type=shift;
   my $self={@_};
   $self=bless($type->SUPER::new(%$self),$type);
   return($self);
}

sub getBackendName     # returns the name/function to place in select
{
   my $self=shift;
   my $mode=shift;
   my $db=shift;

   return($self->{wrdataobjattr}) if ($mode eq "update" || $mode eq "insert");

   return($self->SUPER::getBackendName($mode,$db));
}









1;
