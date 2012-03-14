package itil::lnkitclustsvc;
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
use itil::lib::Listedit;
@ISA=qw(itil::lib::Listedit);

sub new
{
   my $type=shift;
   my %param=@_;
   $param{MainSearchFieldLines}=3;
   my $self=bless($type->SUPER::new(%param),$type);

   

   $self->AddFields(
      new kernel::Field::Linenumber(
                name          =>'linenumber',
                label         =>'No.'),

      new kernel::Field::Id(
                name          =>'id',
                label         =>'LinkID',
                searchable    =>0,
                group         =>'source',
                dataobjattr   =>'qlnkitclustsvc.id'),
                                                 
      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'full qualified Servicename',
                readonly      =>1,
                htmlwidth     =>'250px',
                dataobjattr   =>
             "concat(itclust.fullname,'.',qlnkitclustsvc.itsvcname,if (qlnkitclustsvc.subitsvcname<>'',concat('.',qlnkitclustsvc.subitsvcname),''))"),

      new kernel::Field::TextDrop(
                name          =>'cluster',
                htmlwidth     =>'150px',
                label         =>'Cluster',
                vjointo       =>'itil::itclust',
                vjoinon       =>['clustid'=>'id'],
                vjoineditbase =>{'cistatusid'=>[1,2,3,4]},
                vjoindisp     =>'fullname'),
                                                   
      new kernel::Field::Text(
                name          =>'name',
                label         =>'Servicename',
                dataobjattr   =>'qlnkitclustsvc.itsvcname'),

      new kernel::Field::Text(
                name          =>'subname',
                htmldetail    =>0,
                htmleditwidth =>'50px',
                label         =>'sub Servicename',
                dataobjattr   =>'qlnkitclustsvc.subitsvcname'),

      new kernel::Field::Text(
                name          =>'itservid',
                htmleditwidth =>'100px',
                label         =>'ClusterserviceID',
                dataobjattr   =>'qlnkitclustsvc.itservid'),

      new kernel::Field::Textarea(
                name          =>'comments',
                searchable    =>0,
                label         =>'Comments',
                dataobjattr   =>'qlnkitclustsvc.comments'),

      new kernel::Field::SubList(
                name          =>'applications',
                label         =>'Applications',
                group         =>'applications',
                forwardSearch =>1,
                subeditmsk    =>'subedit.appl',
                vjointo       =>'itil::lnkitclustsvcappl',
                vjoinbase     =>[{applcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'itclustsvcid'],
                vjoindisp     =>['appl','applcistatus','applapplid'],
                vjoininhash   =>['appl','applcistatusid',
                                 'applapplid','applid']),

      new kernel::Field::Text(
                name          =>'applicationnames',
                label         =>'Applicationnames',
                group         =>'applications',
                htmldetail    =>0,
                searchable    =>0,
                readonly      =>1,
                vjointo       =>'itil::lnkitclustsvcappl',
                vjoinbase     =>[{applcistatusid=>"<=5"}],
                vjoinon       =>['id'=>'itclustsvcid'],
                vjoindisp     =>['appl']),

      new kernel::Field::SubList(
                name          =>'systems',
                label         =>'Systems',
                group         =>'systems',
                forwardSearch =>1,
                readonly      =>1,
                vjointo       =>'itil::system',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjoinon       =>['clustid'=>'itclustid'],
                vjoindisp     =>['name','systemid',
                                 'cistatus',
                                 'shortdesc'],
                vjoininhash   =>['system','systemsystemid','systemcistatus',
                                 'systemid']),

      new kernel::Field::SubList(
                name          =>'ipaddresses',
                label         =>'IP-Adresses',
                group         =>'ipaddresses',
                allowcleanup  =>1,
                forwardSearch =>1,
                subeditmsk    =>'subedit.system',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjointo       =>'itil::ipaddress',
                vjoinon       =>['id'=>'itclustsvcid'],
                vjoindisp     =>['webaddresstyp','name','cistatus',
                                 'dnsname','shortcomments'],
                vjoininhash   =>['id','name','addresstyp',
                                 'cistatusid',
                                 'dnsname','comments']),

      new kernel::Field::SubList(
                name          =>'ipaddresseslist',
                label         =>'IP-Adresses list',
                group         =>'ipaddresses',
                htmldetail    =>0,
                searchable    =>0,
                subeditmsk    =>'subedit.system',
                vjoinbase     =>[{cistatusid=>\"4"}],
                vjointo       =>'itil::ipaddress',
                vjoinon       =>['id'=>'itclustsvcid'],
                vjoindisp     =>['name']),

      new kernel::Field::SubList(
                name          =>'dnsnamelist',
                label         =>'DNS-Name list',
                group         =>'ipaddresses',
                htmldetail    =>0,
                subeditmsk    =>'subedit.system',
                vjoinbase     =>[{cistatusid=>\"4"}],
                vjointo       =>'itil::ipaddress',
                vjoinon       =>['id'=>'itclustsvcid'],
                vjoindisp     =>['dnsname']),


      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'qlnkitclustsvc.createuser'),
                                   
      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'Owner',
                dataobjattr   =>'qlnkitclustsvc.modifyuser'),
                                   
      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'qlnkitclustsvc.srcsys'),
                                                   
      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'qlnkitclustsvc.srcid'),
                                                   
      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Last-Load',
                dataobjattr   =>'qlnkitclustsvc.srcload'),
                                                   
      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'qlnkitclustsvc.createdate'),
                                                
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'qlnkitclustsvc.modifydate'),
                                                   
      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor',
                dataobjattr   =>'qlnkitclustsvc.editor'),
                                                  
      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'RealEditor',
                dataobjattr   =>'qlnkitclustsvc.realeditor'),

      new kernel::Field::Select(
                name          =>'clustcistatus',
                readonly      =>1,
                htmldetail    =>0,
                htmlwidth     =>'100px',
                group         =>'clustinfo',
                label         =>'Cluster CI-State',
                vjointo       =>'base::cistatus',
                vjoinon       =>['itclustcistatusid'=>'id'],
                vjoindisp     =>'name'),
                                                  
      new kernel::Field::Link(
                name          =>'itclustcistatusid',
                label         =>'Cluster CI-State',
                readonly      =>1,
                group         =>'clustinfo',
                dataobjattr   =>'itclust.cistatus'),

      new kernel::Field::Link(
                name          =>'mandatorid',
                label         =>'Mandator ID of Cluster',
                readonly      =>1,
                group         =>'clustinfo',
                dataobjattr   =>'itclust.mandator'),

      new kernel::Field::Text(
                name          =>'clustid',
                htmldetail    =>0,
                uploadable    =>0,
                label         =>'W5Base Cluster ID',
                dataobjattr   =>'qlnkitclustsvc.itclust'),

      new kernel::Field::SubList(
                name          =>'software',
                label         =>'Software',
                group         =>'software',
                subeditmsk    =>'subedit.system',
                allowcleanup  =>1,
                forwardSearch =>1,
                vjointo       =>'itil::lnksoftwaresystem',
                vjoinbase     =>[{softwarecistatusid=>"<=4"}],
                vjoinon       =>['id'=>'itclustsvcid'],
                vjoindisp     =>['software','version','quantity','comments'],
                vjoininhash   =>['softwarecistatusid','liccontractcistatusid',
                                 'liccontractid',
                                 'software','version','quantity']),
                                                   
      new kernel::Field::SubList(
                name          =>'swinstances',
                label         =>'Software instances',
                group         =>'swinstances',
                vjointo       =>'itil::swinstance',
                vjoinbase     =>[{cistatusid=>"<=5"}],
                vjoinon       =>['id'=>'itclustsid'],
                vjoindisp     =>['fullname','swnature']),

   );
   $self->setDefaultView(qw(fullname applications  cdate));
   $self->setWorktable("lnkitclustsvc");
   return($self);
}


#sub getRecordImageUrl
#{
#   my $self=shift;
#   my $cgi=new CGI({HTTP_ACCEPT_LANGUAGE=>$ENV{HTTP_ACCEPT_LANGUAGE}});
#   return("../../../public/itil/load/lnkitclustsvc.jpg?".$cgi->query_string());
#}
         

sub getSqlFrom
{
   my $self=shift;
   my $from="lnkitclustsvc qlnkitclustsvc  ".
            "left outer join itclust ".
            "on qlnkitclustsvc.itclust=itclust.id";
   return($from);
}


sub SecureSetFilter
{
   my $self=shift;
   my @flt=@_;

   if (!$self->isDirectFilter(@flt) &&
       !$self->IsMemberOf([qw(admin w5base.itil.read)],
                          "RMember")){
      my @mandators=$self->getMandatorsOf($ENV{REMOTE_USER},"read");
      push(@flt,[
                 {mandatorid=>\@mandators},
                ]);
   }
   return($self->SetFilter(@flt));
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
   my $origrec=shift;

   if (exists($newrec->{itservid})){
      if ($newrec->{itservid} eq ""){
         $newrec->{itservid}=undef;
      }
   }

   if ($self->isDataInputFromUserFrontend() && !$self->IsMemberOf("admin")){
      my $itclustid=effVal($oldrec,$newrec,"clustid");
      if (!$self->isWriteOnClusterValid($itclustid)){
         $self->LastMsg(ERROR,"no write access to specified cluster");
         return(undef);
      }
   }
   my $name=effVal($oldrec,$newrec,"name");
   if ($name eq "" ||
       haveSpecialChar($name)){
      $self->LastMsg(ERROR,"invalid service name");
      return(0);
   }

   



   return(1);
}


sub isViewValid
{
   my $self=shift;
   my $rec=shift;
   return("header","default") if (!defined($rec));
   return("ALL");
}



sub isWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $itclustid=effVal($oldrec,$newrec,"clustid");

   return("default") if (!defined($oldrec) && !defined($newrec));
   return("default","applications","ipaddresses","software") if ($self->IsMemberOf("admin"));
   return("default","applications","ipaddresses","software") if ($self->isWriteOnClusterValid($itclustid));
   return(undef);
}


sub isWriteOnClusterValid
{
   my $self=shift;
   my $itclustid=shift;

   if ($itclustid ne ""){
      my $c=getModuleObject($self->Config,"itil::itclust");
      $c->SetFilter({id=>\$itclustid});
      my ($cl,$msg)=$c->getOnlyFirst(qw(ALL));
      my @g=$c->isWriteValid($cl);
      if (grep(/^(ALL|services)$/,@g)){
         return(1);
      }
   }
   return(0);
}

sub getDetailBlockPriority
{
   my $self=shift;
   return(qw(header default applications 
             ipaddresses systems
             misc clustinfo software swinstances source));
}

sub ValidateDelete
{
   my $self=shift;
   my $rec=shift;
   my $lock=0;

   if ($lock>0 ||
       $#{$rec->{swinstances}}!=-1){
      $self->LastMsg(ERROR,
          "delete only posible, if there are no ".
          "software instance relations");
      return(0);
   }

   return(1);
}









1;
