module: dylan-user
copyright: this program may be freely used by anyone, for any purpose

define library icfp2001
  use common-dylan;
  use io;
end library;

define module icfp2001
  use common-dylan;
  use format-out;
  use format;
  use streams;
  use standard-io;
  use extensions, import: {report-condition};
end module;
