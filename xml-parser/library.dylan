module: dylan-user

define library xml-parser
  use common-dylan;
  use anaphora;
  use multimap;
  use meta;
  use io;

  export xml-parser;
end library;

define module xml-parser
  create parse-document;

  create <document>, <element>, <attribute>, <xml>, <processing-instruction>,
    <entity-reference>, <add-parents>, <char-reference>, <comment>, <tag>,
    <char-string>, <dtd>, <internal-entity>, <external-entity>,
    text, text-setter, name, name-setter, name-with-proper-capitalization,
    root, char;

  create entity-value, attributes, attributes-setter,
    attribute-value, attribute-value-setter,
    node-children, node-children-setter, 
    element-parent, element-parent-setter,
    collect-elements, make-element, sys-id, pub-id, sys/pub,
    internal-declarations, internal-declarations-setter,
    expansion, expansion-setter, comment, comment-setter;

  // for printing
  create <printing>, xml-name,
    *xml-depth*, *open-the-tag*, *close-the-tag*, *ampersand*, *printer-state*;

    // for iteration
  create node-iterator, prepare-document;
  create transform, transform-document, before-transform, <xform-state>;
end module xml-parser;

define module interface
  use common-dylan;
  use streams;
  use format;

  use meta;
  use xml-parser;

  export
    <reference>, <attributes>, <node-mixin>, <external-mixin>,
    after-open, before-close, $hex-digit, $version-number, trim-string;
end module interface;

define module transform
  use common-dylan, exclude: {format-to-string };
  use streams;
  use format;
  use standard-io;
  use xml-parser;
  use interface;
end module transform;

define module printing
  use common-dylan;
  use streams;
  use format;
  use print;
  use anaphora;

  use xml-parser;

  use interface;
  use transform;
end module printing;

define module collect
  use common-dylan;
  use streams;
  use format;
  use anaphora;
  use xml-parser, rename: { attribute-value => value,
                           attribute-value-setter => value-setter };
  use interface;
end module collect;

define module %productions
  use common-dylan, exclude: { format-to-string };
  use standard-io;
  use format-out;
  use streams;
  use format;
  use multimap;
  use print;

  use meta;
  use interface;
  use xml-parser;
end module %productions;
