package itil::appldoc;
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
use kernel::App::Web;
use kernel::DataObj::DB;
use kernel::Field;
use kernel::CIStatusTools;
@ISA=qw(kernel::App::Web::Listedit kernel::DataObj::DB kernel::CIStatusTools);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   my ($worktable,$workdb)=$self->getWorktable();
   $self->{doclabel}="DOC-" if (!defined($self->{doclabel}));
   my $doclabel=$self->{doclabel};

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                sqlorder      =>'desc',
                label         =>'W5BaseID',
                dataobjattr   =>"$worktable.id"),
                                                  
      new kernel::Field::Link(
                name          =>'srcparentid',
                selectfix     =>1,
                label         =>'Source Parent W5BaseID',
                dataobjattr   =>'appl.id'),
                                                  
      new kernel::Field::Link(
                name          =>'parentid',
                selectfix     =>1,
                label         =>'Parent W5BaseID',
                dataobjattr   =>"$worktable.appl"),
                                                  
      new kernel::Field::Text(
                name          =>'name',
                readonly      =>1,
                label         =>'Applicationname',
                dataobjattr   =>'appl.name'),

      new kernel::Field::Select(
                name          =>'dstate',           # NULL = empty join
                label         =>'Document state',   # 10   = empty record
                value         =>[10,20,30],         # 20   = edit record
                default       =>'10',               # 30   = archived record
                readonly      =>1,
                transprefix   =>'dstate.',
                dataobjattr   =>"$worktable.dstate"),
                                                  
      new kernel::Field::Link(
                name          =>'dstateid',
                selectfix     =>1,
                label         =>'Derive State ID',
                dataobjattr   =>"$worktable.dstate"),
                                                  
      new kernel::Field::Boolean(
                name          =>'iscurrent',
                selectfix     =>1,
                htmldetail    =>0,
                readonly      =>1,
                selectsearch  =>[['"1" [LEER]',$self->T('yes - show only current')],
                                 ['',$self->T('no - show all')]],
                label         =>'is current',
                dataobjattr   =>"$worktable.iscurrent"),
                                                  
      new kernel::Field::Interface(
                name          =>'rawiscurrent',
                selectfix     =>1,
                readonly      =>1,
                label         =>'raw is current',
                dataobjattr   =>"$worktable.iscurrent"),
                                                  
      new kernel::Field::Select(
                name          =>'cistatus',
                htmleditwidth =>'40%',
                readonly      =>1,
                label         =>'Application CI-State',
                vjoineditbase =>{id=>">0"},
                vjointo       =>'base::cistatus',
                vjoinon       =>['cistatusid'=>'id'],
                vjoindisp     =>'name'),

      new kernel::Field::Link(
                name          =>'cistatusid',
                label         =>'CI-StateID',
                dataobjattr   =>'appl.cistatus'),

      new kernel::Field::Mandator(
                readonly      =>1),

      new kernel::Field::Link(
                name          =>'mandatorid',
                dataobjattr   =>'appl.mandator'),

      new kernel::Field::Link(
                name          =>'semid',
                group         =>'sem',
                dataobjattr   =>'appl.sem'),

      new kernel::Field::Link(
                name          =>'sem2id',
                group         =>'sem',
                dataobjattr   =>'appl.sem2'),

      new kernel::Field::Link(
                name          =>'conumber',
                label         =>'CO-Number',
                dataobjattr   =>'appl.conumber'),

      new kernel::Field::Import( $self,
                vjointo       =>'itil::costcenter',
                vjoinon       =>['conumber'=>'name'],
                dontrename    =>1,
                group         =>'delmgmt',
                fields        =>[qw(delmgrid delmgr2id
                                    delmgrteamid)]),

      new kernel::Field::Container(
                name          =>'additional',
                label         =>'Additionalinformations',
                dataobjattr   =>"$worktable.additional"),

      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                sqlorder      =>'desc',
                label         =>'Modification-Date',
                dataobjattr   =>"$worktable.modifydate"),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>"$worktable.modifyuser"),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                searchable    =>'0',
                label         =>'Owner',
                dataobjattr   =>"$worktable.modifyuser"),

      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                searchable    =>'0',
                label         =>'Editor',
                dataobjattr   =>"$worktable.editor"),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                searchable    =>'0',
                label         =>'RealEditor',
                dataobjattr   =>"$worktable.realeditor"),

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

      new kernel::Field::Link(
                name          =>'docdate',
                dataobjattr   =>"$worktable.docdate"),

      new kernel::Field::Text(
                name          =>'fullname',
                readonly      =>1,
                htmldetail    =>0,
                label         =>'Documentname',
                dataobjattr   =>
                   "if ($worktable.dstate is null or $worktable.dstate<=10,".
                   "concat('$doclabel',appl.name,'-',substr(now(),1,7)),".
                   "concat('$doclabel',appl.name,'-',".
                           "substr($worktable.docdate,1,7)))"),

   );
   my $fo=$self->getField("iscurrent");
   delete($fo->{default});
   $self->{use_distinct}=1;
   $self->setDefaultView(qw(fullname cistatus mandator dstate editor mdate));
   return($self);
}


sub handleRawValueAutogenField
{
   my $self=shift;
   my $current=shift;
   my $app=$self->getParent();
   if (defined($current) &&
       $current->{srcparentid} ne ""){
      if ($current->{dstateid}<=10){  # autogen field value
         my $r=$app->autoFillGetResultCache($self->{name},
                                             $current->{srcparentid});
         return($r) if (defined($r));
         return($app->autoFillAutogenField($self,$current));
      }
      my $r=$self->resolvContainerEntryFromCurrent($current);
      return($r);
   }
   return("NONE"); 
}

sub autoFillAddResultCache
{
   my $self=shift;

   my $c=$self->Cache();
   $c->{autoFillCache}={} if (!exists($c->{autoFillCache}));

   while(my $p=shift){
      my $name=shift(@$p);
      my $val=shift(@$p);
      my $id=shift(@$p);
      $id="" if (!defined($id));

      if (!exists($c->{autoFillCache}->{"C$id"})){
         $c->{autoFillCache}->{"C$id"}={};
      }
      my $C=$c->{autoFillCache}->{"C$id"};
      $C->{$name}={} if (!exists($C->{$name}));
     
      if (ref($val) eq "ARRAY"){
         map({$C->{$name}->{$_}++} @$val);
      }
      else{
         $C->{$name}->{$val}++;
      }
   }
}

sub autoFillGetResultCache
{
   my $self=shift;
   my $name=shift;
   my $id=shift;
   $id="" if (!defined($id));

   my $c=$self->Cache();
   $c->{autoFillCache}={} if (!exists($c->{autoFillCache}));

   foreach my $useid ($id,""){
      if (exists($c->{autoFillCache}->{"C$useid"})){
         if (exists($c->{autoFillCache}->{"C$useid"}->{$name})){
            return([sort(keys(%{$c->{autoFillCache}->{"C$useid"}->{$name}}))]);
         }
      }
   }
   return(undef);
}

sub autoFillAutogenField
{
   my $self=shift;
   my $fld=shift;
   my $current=shift;

   my $r=$self->autoFillGetResultCache($fld->{name},$current->{srcparentid});

   return($r);
}



sub preProcessReadedRecord
{
   my $self=shift;
   my $rec=shift;

   if (!defined($rec->{id}) && $rec->{srcparentid} ne ""){
      my $o=$self->Clone();
      my ($id)=$o->ValidatedInsertRecord({parentid=>$rec->{srcparentid},
                                          iscurrent=>1});
      $rec->{id}=$id;
   }
   return(undef);
}



sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->IsMemberOf("admin")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      my %grps=$self->getGroupsOf($ENV{REMOTE_USER},
                              [orgRoles(),qw(RCFManager RCFManager2)],"both");
      my @grpids=keys(%grps);
      my $userid=$self->getCurrentUserId();
      push(@flt,[
                 {mandatorid=>\@mandators},
                 {semid=>$userid},
                 {sectargetid=>\$userid,sectarget=>\'base::user',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"},
                 {sectargetid=>\@grpids,sectarget=>\'base::grp',
                  secroles=>"*roles=?write?=roles* *roles=?privread?=roles* ".
                            "*roles=?read?=roles*"},
                 {sem2id=>$userid}
                ]);
   }
   return($self->SetFilter(@flt));
}



sub initSearchQuery
{
   my $self=shift;
   if (!defined(Query->Param("search_cistatus"))){
     Query->Param("search_cistatus"=>
                  "\"!".$self->T("CI-Status(6)","base::cistatus")."\"");
   }
}



sub getSqlFrom
{
   my $self=shift;
   my $mode=shift;
   my @flt=@_;
   my ($worktable,$workdb)=$self->getWorktable();
   my $from="";

   $from.="appl left outer join $worktable ".
          "on appl.id=$worktable.appl ".
          "left outer join lnkcontact ".
          "on lnkcontact.parentobj in ('itil::appl') ".
          "and appl.id=lnkcontact.refid ";

   return($from);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   if (defined($oldrec)){
      $newrec->{dstate}=20;
      $newrec->{iscurrent}=1;
      if ($oldrec->{dstate} eq "10"){  # ensure that ALL default values will
         my ($worktable,$workdb)=$self->getWorktable(); # be written!
         my @fieldlist=$self->getFieldObjsByView([qw(ALL)],
                                                 oldrec=>$oldrec,
                                                 opmode=>'validateFields');
         foreach my $fobj (@fieldlist){
            if ($fobj->{container} eq "additional" &&
                !exists($newrec->{$fobj->{name}})){
               $newrec->{$fobj->{name}}=effVal($oldrec,$newrec,$fobj->{name});
            }
         }
      }
   }
   if (effVal($oldrec,$newrec,"dstate")>10 &&
       effVal($oldrec,$newrec,"dstate")<30 ){ # nur im verankert modes setzen
      my $tz=$self->UserTimezone();
      my ($year, $month)=$self->Today_and_Now($tz);
      $newrec->{docdate}=sprintf("%04d-%02d",$year,$month);
   }
      
   return(1);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;
   if ($rec->{dstate}<30){
      return(qw(default));
   }
   return();
}

sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   if ($rec->{dstate}>10){
      return(qw(header default source));
   }
   return("header","default");
}

sub isDeleteValid
{
   my $self=shift;
   my $rec=shift;

   return(0) if ($rec->{dstate}<30);
   return(1);
}



sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);
   if (effChanged($oldrec,$newrec,"dstate")){
      if ($oldrec->{dstate} eq "10" && $newrec->{dstate} eq "20"){
         my $o=$self->Clone();
         $o->UpdateRecord({dstate=>30,
                           iscurrent=>0},{parentid=>$oldrec->{parentid},
                                          dstateid=>"!30",
                                          id=>"!$oldrec->{id}"});
         $o->ValidatedInsertRecord({parentid=>$oldrec->{parentid}});
      }
   }
   if ($newrec->{dstate} eq "20"){
      my $o=$self->Clone();
      $o->UpdateRecord({iscurrent=>0},{parentid=>$oldrec->{parentid},
                                       id=>"!$oldrec->{id}"});
   }
   if ($newrec->{dstate} eq "30"){
      my $o=$self->Clone();
      $o->UpdateRecord({iscurrent=>1},{parentid=>$oldrec->{parentid},
                                       dstateid=>\'10'});
   }
   return($bak);
}





1;
