use w5base;
set FOREIGN_KEY_CHECKS=0;
create table tag_appl (
  id           bigint(20) NOT NULL,
  refid        bigint(20) NOT NULL,
  uname        varchar(40),
  name         varchar(40) NOT NULL,
  value        varchar(1024) NOT NULL,
  comments     longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  KEY name (name),
  UNIQUE KEY `uname` (uname,refid),
  FOREIGN KEY refrecord (refid)
  REFERENCES appl (id) ON DELETE CASCADE,
  KEY refid (refid),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
create table tag_system (
  id           bigint(20) NOT NULL,
  refid        bigint(20) NOT NULL,
  uname        varchar(40),
  name         varchar(40) NOT NULL,
  value        varchar(1024) NOT NULL,
  comments     longtext    default NULL,
  createdate   datetime NOT NULL default '0000-00-00 00:00:00',
  modifydate   datetime NOT NULL default '0000-00-00 00:00:00',
  createuser   bigint(20) default NULL,
  modifyuser   bigint(20) default NULL,
  editor       varchar(100) NOT NULL default '',
  realeditor   varchar(100) NOT NULL default '',
  srcsys       varchar(100) default 'w5base',
  srcid        varchar(20) default NULL,
  srcload      datetime    default NULL,
  PRIMARY KEY  (id),
  KEY name (name),
  UNIQUE KEY `uname` (uname,refid),
  FOREIGN KEY refrecord (refid)
  REFERENCES appl (id) ON DELETE CASCADE,
  KEY refid (refid),
  UNIQUE KEY `srcsys` (srcsys,srcid)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
