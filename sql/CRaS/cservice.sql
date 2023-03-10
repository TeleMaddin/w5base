use w5base;
create table csteam (
   PRIMARY KEY (id),
   id             bigint(20) NOT NULL,
   name           varchar(255) NOT NULL,
   grp            bigint(20) NOT NULL,
   orgarea        bigint(20) NOT NULL,
   comments       longtext default NULL,
   createdate     datetime NOT NULL default '0000-00-00 00:00:00',
   modifydate     datetime NOT NULL default '0000-00-00 00:00:00',
   createuser     bigint(20) NOT NULL default '0',
   modifyuser     bigint(20) NOT NULL default '0',
   editor         varchar(100) NOT NULL default '',
   realeditor     varchar(100) NOT NULL default '',
   srcsys     varchar(100) default 'w5base',
   srcid      varchar(40) default NULL,
   srcload    datetime    default NULL,
   UNIQUE KEY `srcsys` (srcsys,srcid),UNIQUE KEY uk_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table csr (
   id             bigint(20) NOT NULL,
   name           varchar(255) NOT NULL,
   comments       longtext default NULL,
   status         varchar(40) NOT NULL,
   sslcert         blob NOT NULL,
   sslcertcommon   varchar(512) NOT NULL,
   sslcertorg      varchar(512) NOT NULL,
   applid           bigint(20) NOT NULL,
   csteam           bigint(20) NOT NULL,
   ssslcert           blob NOT NULL,
   ssslissuer         varchar(512) NOT NULL,
   ssslsubject        varchar(512) NOT NULL,
   ssslserialno       varchar(32) NOT NULL,
   ssslstartdate      datetime NOT NULL default '0000-00-00 00:00:00',
   ssslenddate        datetime NOT NULL default '0000-00-00 00:00:00',
   refno            bigint(20),
   replacedrefno    bigint(20),
   spassword        varchar(255),
   extrequest         datetime default NULL,
   signordered        datetime default NULL,
   getsignedpem       datetime default NULL,
   expnotify1     datetime default NULL,
   expnotify2     datetime default NULL,
   expnotifyleaddays  int(20),
   createdate     datetime NOT NULL default '0000-00-00 00:00:00',
   modifydate     datetime NOT NULL default '0000-00-00 00:00:00',
   createuser     bigint(20) NOT NULL default '0',
   modifyuser     bigint(20) NOT NULL default '0',
   editor         varchar(100) NOT NULL default '',
   realeditor     varchar(100) NOT NULL default '',
   srcsys     varchar(100) default 'w5base',
   srcid      varchar(40) default NULL,
   srcload    datetime    default NULL,
   PRIMARY KEY (id),UNIQUE KEY `srcsys` (srcsys,srcid),
   key `applid` (applid), 
   FOREIGN KEY fk_csteam (csteam) REFERENCES csteam (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table csr add sslaltnames longtext;
create table CRaSca (
   PRIMARY KEY (id),
   id             bigint(20) NOT NULL,
   name           varchar(20) NOT NULL,
   isdefault      int(1),   signprocess varchar(20) NOT NULL,
   valid_c        varchar(255),
   valid_o        varchar(255),
   valid_st       varchar(255),
   valid_l        varchar(255),
   comments       longtext default NULL,
   createdate     datetime NOT NULL default '0000-00-00 00:00:00',
   modifydate     datetime NOT NULL default '0000-00-00 00:00:00',
   createuser     bigint(20) NOT NULL default '0',
   modifyuser     bigint(20) NOT NULL default '0',
   editor         varchar(100) NOT NULL default '',
   realeditor     varchar(100) NOT NULL default '',
   UNIQUE KEY `name` (name), UNIQUE key `isdefault` (isdefault)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table csr add caname varchar(20) not null;
