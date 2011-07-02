Summary: RPC::Smart AppCom perl Modules at /apps
Name: apps-perlmod-RPC-Smart-RH56
Version: 1.00
Release: 1
License: GPL
Group: Applications/Web
Source:  RPC-Smart-1.0.tar.gz
Distribution: RedHat 5.6 AppCom Linux
Vendor: T-Systems
Packager: Vogler Hartmut <hartmut.vogler@t-systems.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl >= 1:5.6.1
Autoreq: 0

%description
Perl Module RPC::Smart installed at /apps/perlmod
This installation can be used in AppCom enviroments 
(or similar cluster enviroments) with rpm --dbpath /apps/rpm

%prep
rm -rf $RPM_BUILD_DIR/RPC-Smart-1.0
zcat $RPM_SOURCE_DIR/RPC-Smart-1.0.tar.gz | tar -xvf -

%build
cd $RPM_BUILD_DIR/RPC-Smart-1.0
%{__perl} Makefile.PL PREFIX=/apps/perlmod
make

%install
rm -rf $RPM_BUILD_ROOT
cd $RPM_BUILD_DIR/RPC-Smart-1.0
pwd
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
chmod -R u+w $RPM_BUILD_ROOT/*


%check || :
cd $RPM_BUILD_DIR/RPC-Smart-1.0
#make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
/apps/perlmod/lib/perl5/site_perl/5.8.8/RPC/Smart.pm
/apps/perlmod/lib/perl5/site_perl/5.8.8/RPC/Smart/*.pm
