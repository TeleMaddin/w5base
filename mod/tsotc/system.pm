package tsotc::system;
#  W5Base Framework
#  Copyright (C) 2018  Hartmut Vogler (it@guru.de)
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
      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                group         =>'source',
                label         =>'OTC-SystemID',
                dataobjattr   =>"otc4darwin_server_vw.server_uuid"),

      new kernel::Field::RecordUrl(),

      new kernel::Field::Text(
                name          =>'name',
                sqlorder      =>'desc',
                label         =>'Systemname',
                dataobjattr   =>"server_name"),

      new kernel::Field::Text(
                name          =>'state',
                sqlorder      =>'desc',
                label         =>'System State',
                dataobjattr   =>"otc4darwin_server_vw.vm_state"),

      new kernel::Field::Email(
                name          =>'contactemail',
                label         =>'Contact email',
                dataobjattr   =>"lower(metadata.asp)"),

      new kernel::Field::Text(
                name          =>'projectname',
                label         =>'Project',
                weblinkto     =>\'tsotc::project',
                weblinkon     =>['projectid'=>'id'],
                dataobjattr   =>"otc4darwin_projects_vw.project_name"),

      new kernel::Field::Text(
                name          =>'availability_zone',
                label         =>'Availability Zone',
                dataobjattr   =>"availability_zone"),

      new kernel::Field::Text(
                name          =>'flavor_name',
                label         =>'Flavor',
                dataobjattr   =>"flavor_name"),

      new kernel::Field::Text(
                name          =>'image_name',
                label         =>'Image',
                dataobjattr   =>"image_name"),

      new kernel::Field::Text(
                name          =>'cpucount',
                label         =>'CPU-Count',
                dataobjattr   =>"vcpus"),

      new kernel::Field::Number(
                name          =>'memory',
                label         =>'Memory',
                unit          =>'MB',
                dataobjattr   =>'ram'),

      new kernel::Field::Interface(
                name          =>'projectid',
                label         =>'OTC-ProjectID',
                dataobjattr   =>'otc4darwin_server_vw.project_uuid'),

      new kernel::Field::SubList(
                name          =>'iaascontacts',
                label         =>'IaaS Contacts',
                group         =>'iaascontacts',
                vjointo       =>\'tsotc::lnksystemiaascontact',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['contact','w5contact']),

      new kernel::Field::SubList(
                name          =>'iaccontacts',
                label         =>'IaC Contacts',
                group         =>'iaccontacts',
                vjointo       =>\'tsotc::lnksystemiaccontact',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['contact','w5contact']),

      new kernel::Field::SubList(
                name          =>'ipaddresses',
                label         =>'IP-Addresses',
                group         =>'ipaddresses',
                vjointo       =>\'tsotc::ipaddress',
                vjoinon       =>['id'=>'systemid'],
                vjoindisp     =>['name',"hwaddr"]),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                timezone      =>'CET',
                dataobjattr   =>"date_created"),

      new kernel::Field::Text(
                name          =>'appl',
                htmlwidth     =>'150px',
                group         =>'source',
                label         =>'Application',
                vjointo       =>\'itil::appl',
                vjoinon       =>['appw5baseid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Text(
                name          =>'appw5baseid',
                group         =>'source',
                label         =>'Application W5BaseID',
                dataobjattr   =>'metadata.darwin_app_w5baseid'),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                timezone      =>'CET',
                dataobjattr   =>"date_updated"),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                timezone      =>'CET',
                dataobjattr   =>"otc4darwin_server_vw.db_timestamp"),

   );
   $self->setDefaultView(qw(name state projectname cpucount memory
                            id availability_zone cdate ));
   $self->setWorktable("otc4darwin_server_vw");
   return($self);
}


sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $selfasparent=$self->SelfAsParentObject();
   my $from="$worktable 
left outer join (
  select distinct ON(server_uuid) server_uuid,asp,darwin_app_w5baseid,w from (
    select * from (
      select distinct server_uuid,asp,darwin_app_w5baseid,
         (case when asp is not null then 1 else 0 end) +
         (case when darwin_app_w5baseid is not null then 1 else 0 end) as w
         from otc4darwin_ias_srv_metadata_vw
      union
         select distinct server_uuid,asp,darwin_app_w5baseid,
         (case when asp is not null then 1 else 0 end) +
         (case when darwin_app_w5baseid is not null then 1 else 0 end) as w
         from otc4darwin_iac_srv_metadata_vw 
     ) as prepremeta order by server_uuid,w desc --to get row with most notnulls
   ) as premetadata
) as metadata 
on otc4darwin_server_vw.server_uuid=metadata.server_uuid
join (  -- project_uuids scheinen auch nicht mehr eindeutig
  select distinct project_uuid,project_name
  from otc4darwin_projects_vw
) as otc4darwin_projects_vw 
on otc4darwin_server_vw.project_uuid=otc4darwin_projects_vw.project_uuid";
   return($from);
}



sub Initialize
{
   my $self=shift;

   my @result=$self->AddDatabase(DB=>new kernel::database($self,"tsotc"));
   return(@result) if (defined($result[0]) && $result[0] eq "InitERROR");
   return(1) if (defined($self->{DB}));
   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   my $grp=shift;
   my %param=@_;
   return("header","default","iaascontacts","iaccontacts","ipaddresses",
          "source");
}

sub getRecordImageUrl
{
   my $self=shift;
   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
   return("../../../public/itil/load/system.jpg?".$cgi->query_string());
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

sub isQualityCheckValid
{
   my $self=shift;
   my $rec=shift;
   return(0);
}



sub getValidWebFunctions
{
   my ($self)=@_;
   return($self->SUPER::getValidWebFunctions(),
          qw(ImportSystem));
}


sub ImportSystem
{
   my $self=shift;

   my $importname=trim(Query->Param("importname"));
   if (Query->Param("DOIT")){
      if ($self->Import({importname=>$importname})){
         Query->Delete("importname");
         $self->LastMsg(OK,"system has been successfuly imported");
      }
      Query->Delete("DOIT");
   }


   print $self->HttpHeader("text/html");
   print $self->HtmlHeader(style=>['default.css','work.css',
                                   'kernel.App.Web.css'],
                           static=>{importname=>$importname},
                           body=>1,form=>1,
                           title=>"OTC System Import");
   print $self->getParsedTemplate("tmpl/minitool.system.import",{});
   print $self->HtmlBottom(body=>1,form=>1);
}


sub Import
{
   my $self=shift;
   my $param=shift;

   my $flt;
   my $importname;
   if ($param->{importname} ne ""){
      $importname=$param->{importname};
      $importname=~s/[^a-z0-9_-].*$//i; # prevent wildcard and or filters
      if ($importname ne ""){
         $flt={name=>$importname};
      }
      else{
         return(undef);
      }
   }
   else{
      msg(ERROR,"no importname specified while ".$self->Self." Import call");
      return(undef);
   }
   my $appl=getModuleObject($self->Config,"TS::appl");
   my $cloudarea=getModuleObject($self->Config,"itil::itcloudarea");

   $self->ResetFilter();
   $self->SetFilter($flt);
   my @l=$self->getHashList(qw(name cdate id contactemail availability_zone
                               projectid));
   if ($#l==-1){
      $self->LastMsg(ERROR,"Systemname not found in OTC");
      return(undef);
   }
   if ($#l>0){
      $self->LastMsg(ERROR,"Systemname not unique in OTC");
      return(undef);
   }
   my $sysrec=$l[0];
   my $w5applrec;

   if ($sysrec->{projectid} ne ""){
      msg(INFO,"try to add cloudarea to system ".$sysrec->{name});
      $cloudarea->SetFilter({srcsys=>\'tsotc::project',
                             srcid=>\$sysrec->{projectid}
      });
      my ($w5cloudarearec,$msg)=$cloudarea->getOnlyFirst(qw(ALL));
      if (defined($w5cloudarearec) &&
          $w5cloudarearec->{cistatusid} eq "4" &&
          $w5cloudarearec->{applid} ne ""){
         msg(INFO,"try to add appl ".$w5cloudarearec->{applid}.
                  " to system ".$sysrec->{name});
         $appl->SetFilter({id=>\$w5cloudarearec->{applid}});
         my ($apprec,$msg)=$appl->getOnlyFirst(qw(ALL));
         if (defined($apprec) && 
             in_array([qw(2 3 4)],$apprec->{cistatusid})){
            $w5applrec=$apprec;
         }
      }
   }
   my $sys=getModuleObject($self->Config,"TS::system");

   $sys->SetFilter({srcsys=>\'OTC',srcid=>\$sysrec->{id}});
   my ($w5sysrec,$msg)=$sys->getOnlyFirst(qw(ALL));
   if (!defined($w5sysrec)){
      $sys->ResetFilter();
      $sys->SetFilter($flt);
      ($w5sysrec,$msg)=$sys->getOnlyFirst(qw(ALL));
   }
   my $identifyby;
   if (defined($w5sysrec)){
      if (uc($w5sysrec->{srcsys}) eq "OTC"){
         if ($w5sysrec->{cistatusid} ne "4" &&
             $w5sysrec->{srcid} eq $sysrec->{id}){ # das Teil war schon mal da
            # das bekommen wir sp�ter geregelt     # und scheint nur im
         }                                         # falschen Status
         else{
            my $msg=sprintf(
                       $self->T("Systemname '%s' already imported in W5Base"),
                       $w5sysrec->{name});
            if ($w5sysrec->{srcid} ne "" &&
                $sysrec->{id} ne "" &&
                $w5sysrec->{srcid} ne $sysrec->{id}){
               my $qc=getModuleObject($self->Config,"base::qrule");
               $qc->setParent($sys);
               $qc->nativQualityCheck($sys->getQualityCheckCompat($w5sysrec),
                                      $w5sysrec);
               $sys->ResetFilter();
               $sys->SetFilter($flt);
               my ($w5sysrec2)=$sys->getOnlyFirst(qw(ALL));
               if (defined($w5sysrec2)){
                  $msg=sprintf(
                          $self->T("Systemname '%s' already imported with ".
                                   "different ids '%s' - '%s'"),
                          $w5sysrec->{name},$w5sysrec->{srcid},$sysrec->{id});
               }
               else{
                  $msg=undef;
                  $w5sysrec=undef;
               }
            }
            if (defined($msg)){
               $self->LastMsg(ERROR,$msg);
               return(undef);
            }
         }
      }
   }
   if (defined($w5sysrec)){
      if ($w5sysrec->{srcsys} ne "OTC" &&
          lc($w5sysrec->{srcsys}) ne "w5base" &&
          $w5sysrec->{srcsys} ne ""){
         $self->LastMsg(ERROR,"name colision - systemname $w5sysrec->{name} ".
                              "already in use. Import failed");
         return(undef);
      }
   }
   my $curdataboss;
   if (defined($w5sysrec)){
      $curdataboss=$w5sysrec->{databossid};
      my %newrec=();
      my $userid;


      if ($self->isDataInputFromUserFrontend() &&   # only admins (and databoss)
                                                    # can force
          !$self->IsMemberOf("admin")) {            # reimport over webrontend
         $userid=$self->getCurrentUserId();         # if record already exists
         if ($w5sysrec->{cistatusid}<6 && $w5sysrec->{cistatusid}>2){
            if ($userid ne $w5sysrec->{databossid}){
               $self->LastMsg(ERROR,
                              "reimport only posible by current databoss");
               if (!$self->isDataInputFromUserFrontend()){
                  msg(ERROR,"fail to import $sysrec->{name} with ".
                            "id $sysrec->{id}");
               }
               return(undef);
            }
         }
      }
      if ($w5sysrec->{cistatusid} ne "4"){
         $newrec{cistatusid}="4";
      }
      if ($w5sysrec->{srcsys} ne "OTC"){
         $newrec{srcsys}="OTC";
      }
      if ($w5sysrec->{srcid} ne $sysrec->{id}){
         $newrec{srcid}=$sysrec->{id};
      }
      if ($w5sysrec->{systemtype} ne "standard"){
         $newrec{systemtype}="standard";
      }
      if ($w5sysrec->{osrelease} eq ""){
         $newrec{osrelease}="other";
      }
      if (defined($w5applrec) &&
          ($w5sysrec->{isprod}==0) &&
          ($w5sysrec->{istest}==0) &&
          ($w5sysrec->{isdevel}==0) &&
          ($w5sysrec->{iseducation}==0) &&
          ($w5sysrec->{isapprovtest}==0) &&
          ($w5sysrec->{isreference}==0) &&
          ($w5sysrec->{iscbreakdown}==0)) { # alter Datensatz - aber kein opmode
         if ($w5applrec->{opmode} eq "prod"){   # dann nehmen wir halt die
            $newrec{isprod}=1;                  # Anwendungsdaten
         }
         elsif ($w5applrec->{opmode} eq "test"){
            $newrec{istest}=1;
         }
         elsif ($w5applrec->{opmode} eq "devel"){
            $newrec{isdevel}=1;
         }
         elsif ($w5applrec->{opmode} eq "education"){
            $newrec{iseducation}=1;
         }
         elsif ($w5applrec->{opmode} eq "approvtest"){
            $newrec{isapprovtest}=1;
         }
         elsif ($w5applrec->{opmode} eq "reference"){
            $newrec{isreference}=1;
         }
         elsif ($w5applrec->{opmode} eq "cbreakdown"){
            $newrec{iscbreakdown}=1;
         }
     }
      if (defined($w5applrec) && $w5applrec->{conumber} ne "" &&
          $w5applrec->{conumber} ne $sysrec->{conumber}){
         $newrec{conumber}=$w5applrec->{conumber};
      }

      my $foundsystemclass=0;
      foreach my $v (qw(isapplserver isworkstation isinfrastruct 
                        isprinter isbackupsrv isdatabasesrv 
                        iswebserver ismailserver isrouter 
                        isnetswitch isterminalsrv isnas
                        isclusternode)){
         if ($w5sysrec->{$v}==1){
            $foundsystemclass++;
         }
      }
      if (!$foundsystemclass){
         $newrec{isapplserver}="1"; 
      }
      if ($sys->ValidatedUpdateRecord($w5sysrec,\%newrec,
                                      {id=>\$w5sysrec->{id}})) {
         $identifyby=$w5sysrec->{id};
      }
   }
   else{
      msg(INFO,"try to import new with databoss $curdataboss ...");
      # check 1: Assigmenen Group registered
      #if ($sysrec->{lassignmentid} eq ""){
      #   $self->LastMsg(ERROR,"SystemID has no Assignment Group");
      #   return(undef);
      #}
      # check 2: Assingment Group active
      #my $acgroup=getModuleObject($self->Config,"tsacinv::group");
      #$acgroup->SetFilter({lgroupid=>\$sysrec->{lassignmentid}});
      #my ($acgrouprec,$msg)=$acgroup->getOnlyFirst(qw(supervisoremail));
      #if (!defined($acgrouprec)){
      #   $self->LastMsg(ERROR,"Can't find Assignment Group of system");
      #   return(undef);
      #}
      # check 3: Supervisor registered
      #if ($acgrouprec->{supervisoremail} eq ""){
      #   $self->LastMsg(ERROR,"incomplet Supervisor at Assignment Group");
      #   return(undef);
      #}
      #}

      # final: do the insert operation
      my $newrec={name=>$sysrec->{name},
                  srcid=>$sysrec->{id},
                  srcsys=>'OTC',
                  osrelease=>'other',
                  allowifupdate=>1,
                  cistatusid=>4};

      my $user=getModuleObject($self->Config,"base::user");
      if ($self->isDataInputFromUserFrontend()){
         $newrec->{databossid}=$self->getCurrentUserId();
         $curdataboss=$newrec->{databossid};
      }
      else{
         my $importname=$sysrec->{contactemail};
         my @l;
         if ($importname ne ""){
            $user->SetFilter({cistatusid=>[4], emails=>$importname});
            @l=$user->getHashList(qw(ALL));
         }
         if ($#l==0){
            $newrec->{databossid}=$l[0]->{userid};
            $curdataboss=$newrec->{databossid};
         }
         else{
            if ($self->isDataInputFromUserFrontend()){
               $self->LastMsg(ERROR,"can not find databoss contact record");
            }
            else{
               #msg(WARN,"invalid databoss contact rec for ".
               #          $sysrec->{contactemail});
               if (defined($w5applrec) && $w5applrec->{databossid} ne ""){
                  msg(INFO,"using databoss from application ".
                           $w5applrec->{name});
                  $newrec->{databossid}=$w5applrec->{databossid};
                  $curdataboss=$newrec->{databossid};
               }
            }
            if (!defined($curdataboss)){
               msg(ERROR,"unable to import system '$sysrec->{name}' ".
                         "without databoss");
               return();
            }
         }
      }
      if (!exists($newrec->{mandatorid})){
         my @m=$user->getMandatorsOf($newrec->{databossid},
                                     ["write","direct"]);
         if ($#m==-1){
            # no writeable mandator for new databoss
            if ($self->isDataInputFromUserFrontend()){
               $self->LastMsg(ERROR,"can not find a writeable mandator");
               return();
            }
         }
         $newrec->{mandatorid}=$m[0];
      }
      if (!exists($newrec->{mandatorid})){
         if (defined($w5applrec) && $w5applrec->{mandatorid} ne ""){
            $newrec->{mandatorid}=$w5applrec->{mandatorid};
         }
      }


      if ($newrec->{mandatorid} eq ""){
         $self->LastMsg(ERROR,"can't get mandator for import of ".
                        "OTC System $sysrec->{name}");
         return();
      }
      if (defined($w5applrec)){
         if ($w5applrec->{conumber} ne ""){
            $newrec->{conumber}=$w5applrec->{conumber};
         }
         if ($w5applrec->{acinmassignmentgroupid} ne ""){
            $newrec->{acinmassignmentgroupid}=
                $w5applrec->{acinmassignmentgroupid};
         }
         $newrec->{isapplserver}=1;  # per Default, all is an applicationserver
         if ($w5applrec->{opmode} eq "prod"){
            $newrec->{isprod}=1;
         }
         elsif ($w5applrec->{opmode} eq "test"){
            $newrec->{istest}=1;
         }
         elsif ($w5applrec->{opmode} eq "devel"){
            $newrec->{isdevel}=1;
         }
         elsif ($w5applrec->{opmode} eq "education"){
            $newrec->{iseducation}=1;
         }
         elsif ($w5applrec->{opmode} eq "approvtest"){
            $newrec->{isapprovtest}=1;
         }
         elsif ($w5applrec->{opmode} eq "reference"){
            $newrec->{isreference}=1;
         }
         elsif ($w5applrec->{opmode} eq "cbreakdown"){
            $newrec->{iscbreakdown}=1;
         }
      }
      $identifyby=$sys->ValidatedInsertRecord($newrec);
   }
   if (defined($identifyby) && $identifyby!=0){
      if (defined($w5applrec)){
         { # create application relation
            my $lnkapplsys=getModuleObject($self->Config,"itil::lnkapplsystem");
            $lnkapplsys->SetFilter({
               systemid=>\$identifyby,
               applid=>\$w5applrec->{id}
            });
            my ($lnkrec)=$lnkapplsys->getOnlyFirst(qw(ALL));
            if (!defined($lnkrec)){
               $lnkapplsys->ValidatedInsertRecord({
                  systemid=>$identifyby,
                  applid=>$w5applrec->{id}
               });
            }
         }
         { # add addition write contacts
           my %addwr=();
           foreach my $fld (qw(tsmid tsm2id opmid opm2id applmgrid databossid)){
              if ($w5applrec->{$fld} ne "" && 
                  $w5applrec->{$fld} ne $curdataboss){
                 $addwr{$w5applrec->{$fld}}++;
              }
           }
           my $lnkcontact=getModuleObject($self->Config,"base::lnkcontact");
           $lnkcontact->SetFilter({
              refid=>\$identifyby,
              parentobj=>[$sys->SelfAsParentObject()],
           });
           my @cur=$lnkcontact->getHashList(qw(ALL));
           $lnkcontact->ResetFilter();
           foreach my $userid (keys(%addwr)){
              my @old=grep({
                 $_->{target} eq 'base::user' &&
                 $_->{targetid} eq $userid
              } @cur);
              if ($#old==-1){
                 $lnkcontact->ValidatedInsertRecord({
                    target=>'base::user',
                    targetid=>$userid,
                    roles=>['write'],
                    refid=>$identifyby,
                    comments=>"inherited by application",
                    parentobj=>$sys->SelfAsParentObject()
                 });   
              }
              else{
                 my @curroles=$old[0]->{roles};
                 if (ref($curroles[0]) eq "ARRAY"){
                    @curroles=@{$curroles[0]};
                 }
                 if (!in_array(\@curroles,"write")){
                    $lnkcontact->ValidatedUpdateRecord($old[0],{
                       roles=>[@curroles,'write'],
                    },{id=>\$old[0]->{id}});   
                 }
              }
           }
         }
      }
      if ($self->LastMsg()==0){  # do qulity checks only if all is ok
         $sys->ResetFilter();
         $sys->SetFilter({'id'=>\$identifyby});
         my ($rec,$msg)=$sys->getOnlyFirst(qw(ALL));
         if (defined($rec)){
            my %checksession;
            my $qc=getModuleObject($self->Config,"base::qrule");
            $qc->setParent($sys);
            $checksession{autocorrect}=$rec->{allowifupdate};
            $qc->nativQualityCheck($sys->getQualityCheckCompat($rec),$rec,
                                   \%checksession);
         }
      }
   }
   return($identifyby);
}

1;
