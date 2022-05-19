package itil::lnkbscomp;
#  W5Base Framework
#  Copyright (C) 2013  Hartmut Vogler (it@guru.de)
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
   my $self=bless($type->SUPER::new(%param),$type);
  
   my $dst           =[
                       'itil::systemmonipoint' =>'fullname',
                       'itil::businessservice'=>'fullname',
                       'itil::system' =>'name',
                       'itil::appl'=>'name',
                      ];

   my $vjoineditbase =[
                       {'systemcistatusid'=>'<5'},
                       {'cistatusid'=>"<5"},
                       {'cistatusid'=>"<5"},
                       {'cistatusid'=>"<5"},
                      ];

   $self->AddFields(
      new kernel::Field::Id(
                name          =>'id',
                label         =>'InterfaceComponentID',
                dataobjattr   =>'lnkbscomp.id'),

      new kernel::Field::Link(
                name          =>'businessserviceid',
                label         =>'Businessservice ID',
                dataobjattr   =>'lnkbscomp.businessservice'),

      new kernel::Field::TextDrop(
                name          =>'uppername',
                label         =>'upper Businessservice name',
                readonly      =>sub{
                   my $self=shift;
                   my $rec=shift;
                   return(1) if (defined($rec));
                   return(0);
                },
                vjointo       =>'itil::businessservice',
                vjoinon       =>['businessserviceid'=>'id'],
                vjoindisp     =>'fullname'),

      new kernel::Field::Select(
                name          =>'variant',
                label         =>'Pos',
                htmlwidth     =>'50',
                htmleditwidth =>'30px',
                allownative   =>1,
                selectfix     =>1,
                getPostibleValues=>sub{
                   my $self=shift;
                   my $current=shift;
                   my @lst;
                   my $app=$self->getParent();
                   my $businessserviceid;
                   if (defined($current)){
                      $businessserviceid=$current->{businessserviceid};
                   }
                   else{
                      $businessserviceid=Query->Param('businessserviceid');
                   }
                   if ($businessserviceid ne ""){
                      my $max=0;
                      my $op=$app->Clone();
                      $op->SetFilter({businessserviceid=>\$businessserviceid});
                      my @l=$op->getHashList(qw(sortkey variant lnkpos id));
                      foreach my $rec (@l){
                         $max=$rec->{variant} if ($rec->{variant}>$max);
                      }
                      $max++;
                      foreach(my $cc=1;$cc<=$max;$cc++){
                         push(@lst,$cc,$cc);
                      }
                   }
                   return(@lst);
                },
                dataobjattr   =>'lnkbscomp.varikey'),

      new kernel::Field::Select(
                name          =>'lnkpos',
                label         =>'Pos',
                htmlwidth     =>'50',
                allownative   =>1,
                htmleditwidth =>'30px',
                getPostibleValues=>sub{
                   my $self=shift;
                   my $current=shift;
                   my @lst;
                   my $app=$self->getParent();
                   my $businessserviceid;
                   if (defined($current)){
                      $businessserviceid=$current->{businessserviceid};
                   }
                   else{
                      $businessserviceid=Query->Param('businessserviceid');
                   }
                   if ($businessserviceid ne ""){
                      my $max=0;
                      my $op=$app->Clone();
                      $op->SetFilter({businessserviceid=>\$businessserviceid});
                      my @l=$op->getHashList(qw(sortkey variant lnkpos id));
                      foreach my $rec (@l){
                         $max=$rec->{lnkpos} if ($rec->{lnkpos}>$max);
                      }
                      $max++;
                      foreach(my $cc=1;$cc<=$max;$cc++){
                         push(@lst,$cc,$cc);
                      }
                   }
                   return(@lst);
                },
                dataobjattr   =>'lnkbscomp.lnkpos'),

      new kernel::Field::Htmlarea(
                name          =>'sortkey',
                label         =>' ',
                uivisible     =>0,
                htmlwidth     =>'50px',
                prepRawValue  =>sub{
                   my $self=shift;
                   my $d=shift;
                   my $current=shift;
                   my $app=$self->getParent();
                   my $c=$app->Context();
                   my ($variant,$lnkpos)=split(/\//,$d);
                   $d=~s/^0+//g;
                   $d=~s/\// /g;
                   $d=~s/ 0+/ /g;
                   if ($c->{lastvariant} ne $current->{variant}){
                      $d=sprintf("%-2d -->%2d",$variant,$lnkpos);
                   }
                   else{
                      $d=sprintf("%-2s +->%2d","",$lnkpos);
                   }
                   $d="<xmp>".$d."</xmp>";
                   $c->{lastvariant}=$current->{variant};
                   return($d);
                },
                dataobjattr   =>"concat(LPAD(lnkbscomp.varikey,4,'0'),".
                                "'/',".
                                "LPAD(lnkbscomp.lnkpos,4,'0'))"),

      new kernel::Field::Select(
                name          =>'objtype',
                label         =>'Component type',
                selectfix     =>1,
                default       =>'itil::businessservice',
                getPostibleValues=>sub{
                   my $self=shift;
                   my @l;
                   my @dslist=@$dst;
                   while(my $obj=shift(@dslist)){
                       shift(@dslist);
                       push(@l,$obj,$self->getParent->T($obj,$obj));
                   }
                   return(@l);
                },
                dataobjattr   =>'lnkbscomp.objtype'),

      new kernel::Field::MultiDst (
                name          =>'name',
                htmlwidth     =>'300',
                selectivetyp  =>1,
                dst           =>$dst,
                vjoineditbase =>$vjoineditbase,
                label         =>'Component',
                dsttypfield   =>'objtype',
                dstidfield    =>'obj1id'),

      new kernel::Field::Link(
                name          =>'obj1id',
                label         =>'Object1 ID',
                dataobjattr   =>'lnkbscomp.obj1id'),

      new kernel::Field::Text(
                name          =>'comments',
                label         =>'Comments',
                dataobjattr   =>'lnkbscomp.comments'),

      new kernel::Field::Textarea(
                name          =>'xcomments',
                label         =>'Comments shorted',
                uploadable    =>0,
                readonly      =>1,
                depend        =>['comments'],
                onRawValue    =>sub{
                   my $self=shift;
                   my $current=shift;
                   my $c;
                   $c.=$current->{comments};
                   return($c);
                }), 

      new kernel::Field::Creator(
                name          =>'creator',
                group         =>'source',
                label         =>'Creator',
                dataobjattr   =>'lnkbscomp.createuser'),

      new kernel::Field::Owner(
                name          =>'owner',
                group         =>'source',
                label         =>'last Editor',
                dataobjattr   =>'lnkbscomp.modifyuser'),

      new kernel::Field::Text(
                name          =>'srcsys',
                group         =>'source',
                label         =>'Source-System',
                dataobjattr   =>'lnkbscomp.srcsys'),

      new kernel::Field::Text(
                name          =>'srcid',
                group         =>'source',
                label         =>'Source-Id',
                dataobjattr   =>'lnkbscomp.srcid'),

      new kernel::Field::Date(
                name          =>'srcload',
                group         =>'source',
                label         =>'Source-Load',
                dataobjattr   =>'lnkbscomp.srcload'),

      new kernel::Field::CDate(
                name          =>'cdate',
                group         =>'source',
                label         =>'Creation-Date',
                dataobjattr   =>'lnkbscomp.createdate'),
                                  
      new kernel::Field::MDate(
                name          =>'mdate',
                group         =>'source',
                label         =>'Modification-Date',
                dataobjattr   =>'lnkbscomp.modifydate'),

      new kernel::Field::Interface(
                name          =>'replkeypri',
                group         =>'source',
                label         =>'primary sync key',
                dataobjattr   =>"lnkbscomp.modifydate"),

      new kernel::Field::Interface(
                name          =>'replkeysec',
                group         =>'source',
                label         =>'secondary sync key',
                dataobjattr   =>"lpad(lnkbscomp.id,35,'0')"),


      new kernel::Field::Editor(
                name          =>'editor',
                group         =>'source',
                label         =>'Editor Account',
                dataobjattr   =>'lnkbscomp.editor'),

      new kernel::Field::RealEditor(
                name          =>'realeditor',
                group         =>'source',
                label         =>'real Editor Account',
                dataobjattr   =>'lnkbscomp.realeditor'),
   );
   $self->setDefaultView(qw(id uppername pos name cdate editor));
   $self->setWorktable("lnkbscomp");
   return($self);
}


sub Validate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $origrec=shift;

   if (!$self->checkWriteValid($oldrec,$newrec)){
      $self->LastMsg(ERROR,"no access");
      return(0);
   }
   if (effVal($oldrec,$newrec,"obj1id") eq ""){
      $self->LastMsg(ERROR,"no primary element specified");
      return(0);
   }
   my $businessserviceid=effVal($oldrec,$newrec,"businessserviceid");
   my $objtype=effVal($oldrec,$newrec,"objtype");
   if ($objtype eq "itil::businessservice"){
      for(my $r=1;$r<=3;$r++){
         my $idfld="obj${r}id";
         my $id=effVal($oldrec,$newrec,$idfld);
         if ($id eq $businessserviceid){
            $self->LastMsg(ERROR,"a business service an not contain herself");
            return(0);
         }
      }
   }



   return(1);
}

sub SecureValidate
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   return(1);
}

sub isWriteValid
{
   my $self=shift;
   my $rec=shift;

   #return(undef);
   return("default") if (!defined($rec));
   return("default") if ($self->checkWriteValid($rec));
   return(undef);
}


sub FinishWrite
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;
   my $bak=$self->SUPER::FinishWrite($oldrec,$newrec);

   my $op=$self->Clone();
   my $businessserviceid=effVal($oldrec,$newrec,"businessserviceid");

   $op->SetFilter({businessserviceid=>\$businessserviceid});
   my @l=$op->getHashList(qw(sortkey variant lnkpos id));
   my @oplist;

   my @u;
   foreach my $r (@l){
      push(@u,{id=>$r->{id},variant=>$r->{variant},
               lnkpos=>$r->{lnkpos},sortkey=>$r->{sortkey}});
   }

   my $variant=0;
   my $lnkpos=0;


   for(my $c=0;$c<=$#u;$c++){
      if ($u[$c]->{variant}==$variant+1){
         $variant++;
         $lnkpos=0;
      }
      $lnkpos++;
      if ($u[$c]->{variant} ne $variant){
         $u[$c]->{variant}=$variant;
      }
      if ($u[$c]->{lnkpos} ne $lnkpos){
         $u[$c]->{lnkpos}=$lnkpos;
      }
   }
   for(my $c=0;$c<=$#u;$c++){
      #printf STDERR ("lnkpos %s -> %s\n",$l[$c]->{lnkpos},$u[$c]->{lnkpos});
      #printf STDERR ("variant %s -> %s\n",$l[$c]->{variant},$u[$c]->{variant});
      if (($u[$c]->{lnkpos}!=$l[$c]->{lnkpos}) ||
          ($u[$c]->{variant}!=$l[$c]->{variant})){
         my $bk=$op->UpdateRecord({
             variant=>$u[$c]->{variant},
             lnkpos=>$u[$c]->{lnkpos}
         },{id=>\$u[$c]->{id}});
         msg(INFO,"renum lnkbscom $bk");
      }
   }



#print STDERR Dumper(\@l);
#print STDERR Dumper(\@u);



   return($bak);
}


sub checkWriteValid
{
   my $self=shift;
   my $oldrec=shift;
   my $newrec=shift;

   my $bsid=effVal($oldrec,$newrec,"businessserviceid");

   return(undef) if ($bsid eq "");

   my $lnkobj=getModuleObject($self->Config,"itil::businessservice");
   if ($lnkobj){
      $lnkobj->SetFilter(id=>\$bsid);
      my ($aclrec,$msg)=$lnkobj->getOnlyFirst(qw(ALL)); 
      if (defined($aclrec)){
         my @grplist=$lnkobj->isWriteValid($aclrec);
         if (grep(/^servicecomp$/,@grplist) ||
             grep(/^ALL$/,@grplist)){
            return(1);
         }
      }
      return(0);
   }

   return(0);
}

sub SelfAsParentObject    # this method is needed because existing derevations
{
   return("itil::lnkbscomp");
}





1;
