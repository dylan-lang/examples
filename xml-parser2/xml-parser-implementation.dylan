module: xml-parser-implementation
synopsis: Implements a META parser for XML 1.0
author: Andreas Bogk <andreas@andreas.org>, based on work by Chris Double
translated-into-a-library-by: Douglas M. Auclair, doug@cotilliongroup.com
copyright: LGPL


/*
 * 
 * This library implements a parser for XML 1.0, using the META parser
 * technique.
 * 
 * Source for the specification was:
 * 
 *   http://www.w3.org/TR/2000/REC-xml-20001006
 * 
 * The parse-foo clauses contain a numeric reference to the associated
 * production in the specification.
 *
 * prerequisit:  the meta library (currently at gd/examples/meta/)
 * 
 * Useful for the understanding of this parser:
 *
 *   http://linux.rice.edu/~rahul/hbaker/Prag-Parse.html
 *
 */

// forward declarations

//    [13]    PubidChar        ::=    #x20 | #xD | #xA | [a-zA-Z0-9] | [-'()+,./:=?;!*#@$_%]
//    
// I really wonder if this isn't abuse of the Dylan type system...
//
define constant <ascii-letter> = 
    one-of('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
           'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
           'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
           'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z');

define constant <digit> = 
    one-of('0', '1', '2', '3', '4', '5', '6', '7', '8', '9');
define constant <letter> = <ascii-letter>;

define constant <pub-id-char-without-quotes> =
  type-union(<ascii-letter>, <digit>, 
             one-of(as(<character>, #x20), as(<character>, #xa), as(<character>, #xd),
                    '-', '(', ')', '+', ',', '.', '/', ':', '=',
                    '?', ';', '!', '*', '#', '@', '$', '_', '%'));

define constant <pub-id-char> =
  type-union(<pub-id-char-without-quotes>, singleton('\''));
//    [26]    VersionNum     ::=    ([a-zA-Z0-9_.:] | '-')+
//
define constant <version-number> =
  type-union(<ascii-letter>, <digit>, one-of('_', '.', ':', '-'));

define method parse-s(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c);
// DOUG   [type(<space>, c), loop(type(<space>, c))];
    [loop(type(<space>, c))];
    values(index, #t);
  end with-meta-syntax;  
end method parse-s;


//    [25]    Eq             ::=    S? '=' S?
//
define method parse-eq(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, space);
    [parse-s(space), 
     '=',
     parse-s(space)];
    values(index, #t);
  end with-meta-syntax;
end method parse-eq;

define method parse-version-num(string, #key start = 0, end: stop)
  with-collector into-vector version-string, collect: collect;
    with-meta-syntax parse-string (string, start: start, pos: index)
      variables(c);
      [loop([type(<version-number>, c), do(collect(c))])];
      values(index, as(<string>, version-string));
    end with-meta-syntax;
  end with-collector;
end method parse-version-num;

//    [24]    VersionInfo    ::=    S 'version' Eq ("'" VersionNum "'" | '"' VersionNum '"')/* */
//
define method parse-version-info(string, #key start = 0, end: stop)
    with-meta-syntax parse-string (string, start: start, pos: index)
      variables(c, space, eq, version-num);
      [parse-s(space),
       "version",
       parse-eq(eq),
       {['\'',
         parse-version-num(version-num),
         '\''],
        ['"',
         parse-version-num(version-num),
         '"']}];
      values(index, #t);
    end with-meta-syntax;
end method parse-version-info;

//    [23]    XMLDecl        ::=    '<?xml' VersionInfo EncodingDecl? SDDecl? S? '?>'
//
define method parse-xml-decl(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, version-info, encoding-decl, sd-decl, space);
    ["<?xml",
     parse-version-info(version-info),     
// DOUG     {parse-encoding-decl(encoding-info), []},
// DOUG     {parse-sd-decl(sd-decl), []},
     parse-s(space),
     "?>"];
    values(index, #t);
  end with-meta-syntax;
end method parse-xml-decl;

// Comments

//    [15]    Comment    ::=    '<!--' ((Char - '-') | ('-' (Char - '-')))* '-->'
//    
define method parse-comment(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c);
    ["<!--", loop({["-->", finish()], type(<char>, c)})];
    values(index, #t);
  end with-meta-syntax;  
end method parse-comment;


// Processing Instructions

//    [17]    PITarget    ::=    Name - (('X' | 'x') ('M' | 'm') ('L' | 'l'))
//
// Doesn't currently check whether the name is not xml. Shouldn't
// matter (fingers crossed).
//
define method parse-pi-target(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, name);
    [parse-name(name)];
    values(index, #t);
  end with-meta-syntax;  
end method parse-pi-target;

//    [16]    PI          ::=    '<?' PITarget (S (Char* - (Char* '?>' Char*)))? '?>'
//
define method parse-pi(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, target, space);
    ["<?", parse-pi-target(target), parse-s(space), 
     loop({["?>", finish()], type(<char>, c)})];
    values(index, #t);
  end with-meta-syntax;  
end method parse-pi;

//    [27]    Misc           ::=    Comment | PI | S
//    
define method parse-misc(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, comment, pi, s);
    {parse-comment(comment),
     parse-pi(pi),
     parse-s(s)};
    values(index, #t);
  end with-meta-syntax;
end method parse-misc;


//    [28a]    DeclSep        ::=    PEReference | S                                                                 [WFC: PE Between Declarations]
//                                                                                                                   /* */
//
define method parse-decl-sep(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, pe-reference, s);
    {
// DOUG  parse-pe-reference(pe-reference),
     parse-s(s)};
    values(index, #t);
  end with-meta-syntax;
end method parse-decl-sep;

//    [50]    seq         ::=    '(' S? cp ( S? ',' S? cp )* S? ')'      /* */
//                                                                       [VC: Proper Group/PE Nesting]
//    
define method parse-seq(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, s, cp);
      ["(",
       {parse-s(s), []},
       parse-cp(cp),
       loop([{parse-s(s), []},
             ",",
             {parse-s(s), []},
             parse-cp(cp)]),
       {parse-s(s), []},
       ")"];
    values(index, #t);
  end with-meta-syntax;
end method parse-seq;

//    [48]    cp          ::=    (Name | choice | seq) ('?' | '*' | '+')?
//
define method parse-cp(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, name, choice, seq);
      [{parse-name(name), parse-choice(choice), parse-seq(seq)}, 
       {{"?", "*", "+"}, []}];
    values(index, #t);
  end with-meta-syntax;
end method parse-cp;

//    [49]    choice      ::=    '(' S? cp ( S? '|' S? cp )+ S? ')'      /* */
//                                                                       /* */
//                                                                       [VC: Proper Group/PE Nesting]
define method parse-choice(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, s, cp);
      ["(",
       {parse-s(s), []},
       parse-cp(cp),
       {parse-s(s), []},
       "|",
       {parse-s(s), []},
       parse-cp(cp),
       loop([{parse-s(s), []},
             "|",
             {parse-s(s), []},
             parse-cp(cp)]),
       {parse-s(s), []},
       ")"];
    values(index, #t);
  end with-meta-syntax;
end method parse-choice;

// Element-content Models
// 
//    [47]    children    ::=    (choice | seq) ('?' | '*' | '+')?
//
define method parse-children(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, choice, seq);
      [{parse-choice(choice), parse-seq(seq)}, 
       {{"?", "*", "+"}, []}];
    values(index, #t);
  end with-meta-syntax;
end method parse-children;

//    [46]    contentspec    ::=    'EMPTY' | 'ANY' | Mixed | children
//    
define method parse-contentspec(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, mixed, children);
    {"EMPTY", "ANY", parse-mixed(mixed), parse-children(children)};
    values(index, #t);
  end with-meta-syntax;
end method parse-contentspec;

// Mixed-content Declaration
// 
//    [51]    Mixed    ::=    '(' S? '#PCDATA' (S? '|' S? Name)* S? ')*'
//                            | '(' S? '#PCDATA' S? ')'                  [VC: Proper Group/PE Nesting]
//                                                                       [VC: No Duplicate Types]
//    
define method parse-mixed(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, s, name);
      {["(",
        {parse-s(s), []},
        "#PCDATA",
        loop([{parse-s(s), []},
              "|",
              {parse-s(s), []},
              parse-name(name)]),
        {parse-s(s), []},
        ")*"],
       ["(",
        {parse-s(s), []},
        "#PCDATA",
        {parse-s(s), []},
        ")"]};
    values(index, #t);
  end with-meta-syntax;
end method parse-mixed;

// Element Type Declaration
// 
//    [45]    elementdecl    ::=    '<!ELEMENT' S Name S contentspec S? '>' [VC: Unique Element Type Declaration]
//
define method parse-elementdecl(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, name, spec, s);
    ["<!ELEMENT",
     parse-s(s), 
     parse-name(name),
     parse-contentspec(spec),
     {parse-s(s), []},
     "/>"];
    values(index, #t);
  end with-meta-syntax;
end method parse-elementdecl;

//    [55]    StringType       ::=    'CDATA'
//
define method parse-string-type(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    ["CDATA"];
    values(index, #t);
  end with-meta-syntax;
end method parse-string-type;

//    [56]    TokenizedType    ::=    'ID'                                        [VC: ID]
//                                                                                [VC: One ID per Element Type]
//                                                                                [VC: ID Attribute Default]
//                                    | 'IDREF'                                   [VC: IDREF]
//                                    | 'IDREFS'                                  [VC: IDREF]
//                                    | 'ENTITY'                                  [VC: Entity Name]
//                                    | 'ENTITIES'                                [VC: Entity Name]
//                                    | 'NMTOKEN'                                 [VC: Name Token]
//                                    | 'NMTOKENS'                                [VC: Name Token]
//    
define method parse-tokenized-type(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    {"ID", "IDREF", "IDREFS", "ENTITY", "ENTITIES", "NMTOKEN", "NMTOKENS"};
    values(index, #t);
  end with-meta-syntax;
end method parse-tokenized-type;

// Attribute Types
// 
//    [54]    AttType          ::=    StringType | TokenizedType | EnumeratedType
//
define method parse-att-type(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(string-type, tokenized-type, enumerated-type);
      {parse-string-type(string-type), parse-tokenized-type(tokenized-type), parse-enumerated-type(enumerated-type)};
    values(index, #t);
  end with-meta-syntax;
end method parse-att-type;

//    [53]    AttDef         ::=    S Name S AttType S DefaultDecl
//    
define method parse-att-def(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(s, name, att-type, default-decl);
      [parse-s(s), parse-name(name), 
       parse-s(s), parse-att-type(att-type), 
       parse-s(s), parse-default-decl(default-decl)];
    values(index, #t);
  end with-meta-syntax;
end method parse-att-def;

// Attribute-list Declaration
// 
//    [52]    AttlistDecl    ::=    '<!ATTLIST' S Name AttDef* S? '>'
//
define method parse-attlist-decl(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, s, name, att-def);
      {["<!ATTLIST",
        parse-s(s),
        parse-name(name),
        loop(parse-att-def(att-def)),
        {parse-s(s), []},
        ">"]};
    values(index, #t);
  end with-meta-syntax;
end method parse-attlist-decl;

//    [29]     markupdecl     ::=    elementdecl | AttlistDecl | EntityDecl | NotationDecl | PI | Comment            [VC: Proper Declaration/PE Nesting]
//                                                                                                                   [WFC: PEs in Internal Subset]
//    
define method parse-markupdecl(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, decl);
    {parse-elementdecl(decl),
     parse-attlist-decl(decl),
 // DOUG    parse-entity-decl(decl),
// DOUG     parse-notation-decl(decl),
     parse-pi(decl),
     parse-comment(decl)};
    values(index, #t);
  end with-meta-syntax;
end method parse-markupdecl;

// Document Type Definition
// 
//    [28]     doctypedecl    ::=    '<!DOCTYPE' S Name (S ExternalID)? S? ('[' (markupdecl | DeclSep)* ']' S?)? '>' [VC: Root Element Type]
//                                                                                                                   [WFC: External Subset]
//                                                                                                                   /* */
define method parse-doctypedecl(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, s, name, id, markup, decl-sep);
    ["<!DOCTYPE", parse-s(s), parse-name(name),
 // DOUG    {[parse-s(s), parse-external-id(id)], []},
     {parse-s(s), []},
     {['[', loop({parse-markupdecl(markup), parse-decl-sep(decl-sep)}), {parse-s(s), []}], []},
     ">"];
    values(index, #t);
  end with-meta-syntax;
end method parse-doctypedecl;

// Prolog
// 
//    [22]    prolog         ::=    XMLDecl? Misc* (doctypedecl Misc*)?
//
define method parse-prolog(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, decl, misc, doctype);
    [{parse-xml-decl(decl), []}, 
     loop(parse-misc(misc)),
     {[parse-doctypedecl(doctype),
       loop(parse-misc(misc))], []}]; 
    values(index, #t);
  end with-meta-syntax;  
end method parse-prolog;

define method parse-xml-attribute(string, #key start = 0, end: stop)
  local method is-not-single-quote?(char :: <character>)
      char ~= '\'';
  end method is-not-single-quote?;

  local method is-not-double-quote?(char :: <character>)
      char ~= '"';
  end method is-not-double-quote?;

  with-collector into-vector attribute, collect: collect;
    with-meta-syntax parse-string (string, start: start, pos: index)
      variables(c, space, eq, version-num);
       {['\'',
         [[test(is-not-single-quote?, c), do(collect(c))], loop([test(is-not-single-quote?, c), do(collect(c))])],
         '\''],
        ['"',
         [[test(is-not-double-quote?, c), do(collect(c))], loop([test(is-not-double-quote?, c), do(collect(c))])],
         '"']};
      values(index, as(<string>, attribute));
    end with-meta-syntax;
  end with-collector;
end method parse-xml-attribute;

//    [41]    Attribute    ::=    Name Eq AttValue               [VC: Attribute Value Type]
//                                                               [WFC: No External Entity References]
//                                                               [WFC: No < in Attribute Values]
//    
define method parse-attribute(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, name, eq, attribute-value);
    [parse-name(name),
     parse-eq(eq),
     parse-xml-attribute(attribute-value)
    ];
    values(index, pair(name, attribute-value));
  end with-meta-syntax;
end method parse-attribute;

// Tags for Empty Elements
// 
//    [44]    EmptyElemTag    ::=    '<' Name (S Attribute)* S? '/>' [WFC: Unique Att Spec]
//
// This is not optimal because we parse the whole tag data twice if it
// is not an empty-elem-tag. Need to unify this with [39].
define method parse-empty-elem-tag(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, name, attribute, s);
    ["<",
     parse-name(name),
     loop([parse-s(s), parse-attribute(attribute)]),
     {parse-s(s), []},
     "/>"];
    values(index, #t);
  end with-meta-syntax;
end method parse-empty-elem-tag;


// Start-tag
// 
//    [40]    STag         ::=    '<' Name (S Attribute)* S? '>' [WFC: Unique Att Spec]
//
define method parse-stag(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, name, attribute, s);
    ["<",
     parse-name(name),
     loop([parse-s(s), parse-attribute(attribute)]),
     {parse-s(s), []},
     ">"];
    values(index, #t);
  end with-meta-syntax;
end method parse-stag;

// End-tag
// 
//    [42]    ETag    ::=    '</' Name S? '>'
//    
define method parse-etag(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, s, name, eq, attribute-value);
    ["</", parse-name(name), {parse-s(s), []}, ">"];
    values(index, #t);
  end with-meta-syntax;
end method parse-etag;


// Content of Elements
// 
//    [43]    content    ::=    CharData? ((element | Reference | CDSect | PI | Comment) CharData?)* /* */
//    
define method parse-content(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, data, elemnt, reference, cd-sect, pi, comment);
      [{parse-char-data(data), []},
       loop([{parse-element(elemnt), // DOUG parse-reference(reference), 
              parse-cd-sect(cd-sect), parse-pi(pi), parse-comment(comment)},
             {parse-char-data(data), []}])];
      values(index, #t);
  end with-meta-syntax;
end method parse-content;


// Element
// 
//    [39]    element    ::=    EmptyElemTag
//                              | STag content ETag [WFC: Element Type Match]
//                                                  [VC: Element Valid]
//    
define method parse-element(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, empty-tag, stag, content, etag);
    {parse-empty-elem-tag(empty-tag),
     [parse-stag(stag), parse-content(content), parse-etag(etag)]};
    values(index, #t);
  end with-meta-syntax;
end method parse-element;


// Document
// 
//    [1]    document    ::=    prolog element Misc*
//    
define method parse-document(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(prolog, elemnt, misc);
    [parse-prolog(prolog), parse-element(elemnt), loop(parse-misc(misc))];
    values(index, #t);
  end with-meta-syntax;
end method parse-document;


// Character Range
//
//    [2]    Char    ::=    #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF] /* any Unicode character, excluding the surrogate blocks,
//    FFFE, and FFFF. */
//    
// FIXME: we're cheating here, by using UFT8 and just allowing anything.
//

define constant <char> = <character>;


// White Space
//
//    [3]    S    ::=    (#x20 | #x9 | #xD | #xA)+
//    
define constant <space> =
  one-of(as(<character>, #x20), as(<character>, #x9), as(<character>, #xd),
         as(<character>, #x0a));


// Names and Tokens
// 
//    [4]    NameChar    ::=    Letter | Digit | '.' | '-' | '_' | ':' | CombiningChar | Extender
//
define constant <name-char> = type-union(<letter>, <digit>, one-of('.', '-', '_', ':')); // , <combining-char>, <extender>));

//    [5]    Name        ::=    (Letter | '_' | ':') (NameChar)*
//
define method parse-name(string, #key start = 0, end: stop)
  with-collector into-vector name, collect: collect;
    with-meta-syntax parse-string (string, start: start, pos: index)
      variables(c);
      [[{type(<letter>, c), '_', ':'}, do(collect(c))],
       loop([type(<name-char>, c), do(collect(c))])];
      values(index, as(<string>, name));
    end with-meta-syntax;
  end with-collector;
end method parse-name;

//    [6]    Names       ::=    Name (S Name)*
//
define method parse-names(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(name, s);
    [parse-name(name), loop([parse-s(s), parse-name(name)])];
    values(index, #t);
  end with-meta-syntax;  
end method parse-names;

//    [7]    Nmtoken     ::=    (NameChar)+
//
define method parse-nmtoken(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c);
    [type(<name-char>, c), loop(type(<name-char>, c))];
    values(index, #t);
  end with-meta-syntax;  
end method parse-nmtoken;

//    [8]    Nmtokens    ::=    Nmtoken (S Nmtoken)*
//    
define method parse-nmtokens(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(token, s);
    [parse-nmtoken(token), loop([parse-s(s), parse-nmtoken(token)])];
    values(index, #t);
  end with-meta-syntax;  
end method parse-nmtokens;


// Literals
//
//    [9]     EntityValue      ::=    '"' ([^%&"] | PEReference | Reference)* '"'
//                                    |  "'" ([^%&'] | PEReference | Reference)* "'"
//

define constant in-set? = member?;  // just for symmetry

define method not-in-set?(character, set)
  ~ member?(character, set);
end method not-in-set?;

define method parse-entity-value(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, reference);
    {['"',
      loop({(not-in-set?(c, "%&\""))}), 
// DOUG            parse-pe-reference(reference), 
// DOUG            parse-reference(reference)}),
      '"'],
     ['\'',
      loop({(not-in-set?(c, "%&'"))}), 
// DOUG            parse-pe-reference(reference), 
// DOUG            parse-reference(reference)}),
      '\'']};
    values(index, #t);
  end with-meta-syntax;  
end method parse-entity-value;

//    [10]    AttValue         ::=    '"' ([^<&"] | Reference)* '"'
//                                    |  "'" ([^<&'] | Reference)* "'"
//
define method parse-att-value(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, reference);
    {['"',
      loop({(not-in-set?(c, "<&\""))}), 
// DOUG            parse-reference(reference)}),
      '"'],
     ['\'',
      loop({(not-in-set?(c, "<&'"))}),
// DOUG            parse-reference(reference)}),
      '\'']};
    values(index, #t);
  end with-meta-syntax;  
end method parse-att-value;

//    [11]    SystemLiteral    ::=    ('"' [^"]* '"') | ("'" [^']* "'")
//
define method parse-system-literal(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c);
    {['"',
      loop((not-in-set?(c, "\""))), 
      '"'],
     ['\'',
      loop((not-in-set?(c, "'"))), 
      '\'']};
    values(index, #t);
  end with-meta-syntax;  
end method parse-system-literal;

//    [12]    PubidLiteral     ::=    '"' PubidChar* '"' | "'" (PubidChar - "'")* "'"
//
define method parse-pubid-literal(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c);
    {['"',
      loop(type(<pub-id-char>, c)), 
      '"'],
     ['\'',
      loop(type(<pub-id-char-without-quotes>, c)), 
      '\'']};
    values(index, #t);
  end with-meta-syntax;  
end method parse-pubid-literal;

// Character Data
//
//    [14]    CharData    ::=    [^<&]* - ([^<&]* ']]>' [^<&]*)
//    

// Now this is not very coherent to me. The section in the
// specification talks about CharData being used by the CDATA section,
// where in fact CDATA has it's own rule for matching characters
// [20]. So I don't see why ']]>' shouldn't be allowed, and I'm taking
// the liberty to implement this as
//
//    [14a]   CharData    ::=    [^<&]*
//
// which should be good enough (i.e., parses all compliant XML files,
// but fails to detect some non-compliancies).
//                                                --andreas
//
define method parse-char-data(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c);
    [loop((not-in-set?(c, "<&")))];
    values(index, #t);
  end with-meta-syntax;  
end method parse-char-data;

// CDATA Sections
// 
//    [18]    CDSect     ::=    CDStart CData CDEnd
//    [19]    CDStart    ::=    '<![CDATA['
//    [20]    CData      ::=    (Char* - (Char* ']]>' Char*))
//    [21]    CDEnd      ::=    ']]>'
//    
// Now here we require multi-byte lookahead. Great. And we need to
// rearrange things a little because we have no equivalent to the
// - operator. Basically, we're construcing our own non-greedy
// loop operator here.                        --andreas
//                      
define method parse-cd-sect(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c);
    ["<![CDATA[", loop({["]]>", finish()], type(<char>, c)})];
    values(index, #t);
  end with-meta-syntax;  
end method parse-cd-sect;

// External Subset
// 
//    [30]    extSubset        ::=    TextDecl? extSubsetDecl
//
define method parse-ext-subset(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, text-decl, subset-decl);
    [
// DOUG {parse-text-decl(text-decl), []},
     parse-ext-subset-decl(subset-decl)];
    values(index, #t);
  end with-meta-syntax;
end method parse-ext-subset;

//    [31]    extSubsetDecl    ::=    ( markupdecl | conditionalSect | DeclSep)* /* */
//    
define method parse-ext-subset-decl(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, markup-decl, sect, decl-sep);
    [loop({parse-markupdecl(markup-decl), 
           parse-conditional-sect(sect),
           parse-decl-sep(decl-sep)})];
    values(index, #t);
  end with-meta-syntax;
end method parse-ext-subset-decl;


// Standalone Document Declaration
// 
//    [32]    SDDecl    ::=    S 'standalone' Eq (("'" ('yes' | 'no') "'") | ('"' ('yes' | 'no') '"')) [VC: Standalone Document Declaration]
//    
define method parse-sd-decl(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, space, eq);
    [parse-s(space),
     "standalone",
     parse-eq(eq),
     {['\'',
       {"yes", "no"},
       '\''],
      ['"',
       {"yes", "no"},
       '"']}];
    values(index, #t);
  end with-meta-syntax;
end method parse-sd-decl;


//    (Productions 33 through 38 have been removed.)

// Enumerated Attribute Types
// 
//    [57]    EnumeratedType    ::=    NotationType | Enumeration
//
define method parse-enumerated-type(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(notation-type, enumeration);
    { parse-notation-type(notation-type), parse-enumeration(enumeration) };
    values(index, #t);
  end with-meta-syntax;
end method parse-enumerated-type;


//    [58]    NotationType      ::=    'NOTATION' S '(' S? Name (S? '|' S? Name)* S? ')' [VC: Notation Attributes]
//                                                                                       [VC: One Notation Per Element Type]
//                                                                                       [VC: No Notation on Empty Element]
//
define method parse-notation-type(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(s, name);
    ["NOTATION", parse-s(s), "(", {parse-s(s),[]},
     parse-name(name),
     loop([{parse-s(s),[]}, "|", {parse-s(s),[]}, parse-name(name)]),
     {parse-s(s),[]}, ")"];
    values(index, #t);
  end with-meta-syntax;
end method parse-notation-type;


//    [59]    Enumeration       ::=    '(' S? Nmtoken (S? '|' S? Nmtoken)* S? ')'        [VC: Enumeration]
//    
define method parse-enumeration(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(s, nmtoken);
    ["(", {parse-s(s),[]},
     parse-nmtoken(nmtoken),
     loop([{parse-s(s),[]}, "|", {parse-s(s),[]}, parse-nmtoken(nmtoken)]),
     {parse-s(s),[]}, ")"];
    values(index, #t);
  end with-meta-syntax;
end method parse-enumeration;


// Attribute Defaults
// 
//    [60]    DefaultDecl    ::=    '#REQUIRED' | '#IMPLIED'
//                                  | (('#FIXED' S)? AttValue) [VC: Required Attribute]
//                                                             [VC: Attribute Default Legal]
//                                                             [WFC: No < in Attribute Values]
//                                                             [VC: Fixed Attribute Default]
//
define method parse-default-decl(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(s, att-value);
    { "#REQUIRED", "#IMPLIED", 
     [{["#FIXED", parse-s(s)], []}, parse-att-value(att-value)]};
    values(index, #t);
  end with-meta-syntax;
end method parse-default-decl;

    
// Conditional Section
// 
//    [61]    conditionalSect       ::=    includeSect | ignoreSect
//
define method parse-conditional-sect(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(include-sect, ignore-sect);
    {parse-include-sect(include-sect), parse-ignore-sect(ignore-sect)};
    values(index, #t);
  end with-meta-syntax;
end method parse-conditional-sect;

//    [62]    includeSect           ::=    '<![' S? 'INCLUDE' S? '[' extSubsetDecl ']]>'      /* */
//                                                                                            [VC: Proper Conditional Section/PE Nesting]
define method parse-include-sect(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(s, subset-decl);
    ["<![", {parse-s(s), []}, 
     "INCLUDE", {parse-s(s), []}, 
     "[", parse-ext-subset-decl(subset-decl), "]]>"];
    values(index, #t);
  end with-meta-syntax;
end method parse-include-sect;


//    [63]    ignoreSect            ::=    '<![' S? 'IGNORE' S? '[' ignoreSectContents* ']]>' /* */
//                                                                                            [VC: Proper Conditional Section/PE Nesting]
define method parse-ignore-sect(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(s, ignore-sect);
    ["<![", {parse-s(s), []}, 
     "IGNORE", {parse-s(s), []}, 
     "[", loop(parse-ignore-sect-contents(ignore-sect)), "]]>"];
    values(index, #t);
  end with-meta-syntax;
end method parse-ignore-sect;


//    [64]    ignoreSectContents    ::=    Ignore ('<![' ignoreSectContents ']]>' Ignore)*
//    [65]    Ignore                ::=    Char* - (Char* ('<![' | ']]>') Char*)
//
// They are doing it again.
define method parse-ignore-sect-contents(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(ignore, ignore-sect);
    [parse-ignore(ignore),
     loop(["<![", loop(parse-ignore-sect-contents(ignore-sect)), "]]>", parse-ignore(ignore)])];
    values(index, #t);
  end with-meta-syntax;
end method parse-ignore-sect-contents;

//    
define method parse-ignore(string, #key start = 0, end: stop)
//  with-meta-syntax parse-string (string, start: start, pos: index)
  //  variables(ignore, ignore-sect);

    values(start, #t);  // DOUG changed index to start
  // end with-meta-syntax;
end method parse-ignore;

// Character Reference
// 
//    [66]    CharRef    ::=    '&#' [0-9]+ ';'
//                              | '&#x' [0-9a-fA-F]+ ';' [WFC: Legal Character]
//    
// Entity Reference
// 
//    [67]    Reference      ::=    EntityRef | CharRef
//    [68]    EntityRef      ::=    '&' Name ';'       [WFC: Entity Declared]
//                                                     [VC: Entity Declared]
//                                                     [WFC: Parsed Entity]
//                                                     [WFC: No Recursion]
//    [69]    PEReference    ::=    '%' Name ';'       [VC: Entity Declared]
//                                                     [WFC: No Recursion]
//                                                     [WFC: In DTD]
//    
// Entity Declaration
// 
//    [70]    EntityDecl    ::=    GEDecl | PEDecl
//    [71]    GEDecl        ::=    '<!ENTITY' S Name S EntityDef S? '>'
//    [72]    PEDecl        ::=    '<!ENTITY' S '%' S Name S PEDef S? '>'
//    [73]    EntityDef     ::=    EntityValue | (ExternalID NDataDecl?)
//    [74]    PEDef         ::=    EntityValue | ExternalID
//    
// External Entity Declaration
// 
//    [75]    ExternalID    ::=    'SYSTEM' S SystemLiteral
//                                 | 'PUBLIC' S PubidLiteral S SystemLiteral
//    [76]    NDataDecl     ::=    S 'NDATA' S Name                          [VC: Notation Declared]
//    
// Text Declaration
// 
//    [77]    TextDecl    ::=    '<?xml' VersionInfo? EncodingDecl S? '?>'
//    
// Well-Formed External Parsed Entity
// 
//    [78]    extParsedEnt    ::=    TextDecl? content
//    
// Encoding Declaration
// 
//    [80]    EncodingDecl    ::=    S 'encoding' Eq ('"' EncName '"' | "'" EncName "'" )
//    [81]    EncName         ::=    [A-Za-z] ([A-Za-z0-9._] | '-')*                      /* Encoding name contains only Latin characters */
//    
// Notation Declarations
// 
//    [82]    NotationDecl    ::=    '<!NOTATION' S Name S (ExternalID | PublicID) S? '>' [VC: Unique Notation Name]
//    [83]    PublicID        ::=    'PUBLIC' S PubidLiteral
//    
// Characters
// 
//    [84]    Letter    ::=    BaseChar | Ideographic
//    [85]    BaseChar    ::=    [#x0041-#x005A] | [#x0061-#x007A] | [#x00C0-#x00D6] | [#x00D8-#x00F6] | [#x00F8-#x00FF] | [#x0100-#x0131] | [#x0134-#x013E]
//    | [#x0141-#x0148] | [#x014A-#x017E] | [#x0180-#x01C3] | [#x01CD-#x01F0] | [#x01F4-#x01F5] | [#x01FA-#x0217] | [#x0250-#x02A8] | [#x02BB-#x02C1]
//    | #x0386 | [#x0388-#x038A] | #x038C | [#x038E-#x03A1] | [#x03A3-#x03CE] | [#x03D0-#x03D6] | #x03DA | #x03DC | #x03DE | #x03E0 | [#x03E2-#x03F3]
//    | [#x0401-#x040C] | [#x040E-#x044F] | [#x0451-#x045C] | [#x045E-#x0481] | [#x0490-#x04C4] | [#x04C7-#x04C8] | [#x04CB-#x04CC] | [#x04D0-#x04EB]
//    | [#x04EE-#x04F5] | [#x04F8-#x04F9] | [#x0531-#x0556] | #x0559 | [#x0561-#x0586] | [#x05D0-#x05EA] | [#x05F0-#x05F2] | [#x0621-#x063A]
//    | [#x0641-#x064A] | [#x0671-#x06B7] | [#x06BA-#x06BE] | [#x06C0-#x06CE] | [#x06D0-#x06D3] | #x06D5 | [#x06E5-#x06E6] | [#x0905-#x0939] | #x093D
//    | [#x0958-#x0961] | [#x0985-#x098C] | [#x098F-#x0990] | [#x0993-#x09A8] | [#x09AA-#x09B0] | #x09B2 | [#x09B6-#x09B9] | [#x09DC-#x09DD]
//    | [#x09DF-#x09E1] | [#x09F0-#x09F1] | [#x0A05-#x0A0A] | [#x0A0F-#x0A10] | [#x0A13-#x0A28] | [#x0A2A-#x0A30] | [#x0A32-#x0A33] | [#x0A35-#x0A36]
//    | [#x0A38-#x0A39] | [#x0A59-#x0A5C] | #x0A5E | [#x0A72-#x0A74] | [#x0A85-#x0A8B] | #x0A8D | [#x0A8F-#x0A91] | [#x0A93-#x0AA8] | [#x0AAA-#x0AB0]
//    | [#x0AB2-#x0AB3] | [#x0AB5-#x0AB9] | #x0ABD | #x0AE0 | [#x0B05-#x0B0C] | [#x0B0F-#x0B10] | [#x0B13-#x0B28] | [#x0B2A-#x0B30] | [#x0B32-#x0B33]
//    | [#x0B36-#x0B39] | #x0B3D | [#x0B5C-#x0B5D] | [#x0B5F-#x0B61] | [#x0B85-#x0B8A] | [#x0B8E-#x0B90] | [#x0B92-#x0B95] | [#x0B99-#x0B9A] | #x0B9C
//    | [#x0B9E-#x0B9F] | [#x0BA3-#x0BA4] | [#x0BA8-#x0BAA] | [#x0BAE-#x0BB5] | [#x0BB7-#x0BB9] | [#x0C05-#x0C0C] | [#x0C0E-#x0C10] | [#x0C12-#x0C28]
//    | [#x0C2A-#x0C33] | [#x0C35-#x0C39] | [#x0C60-#x0C61] | [#x0C85-#x0C8C] | [#x0C8E-#x0C90] | [#x0C92-#x0CA8] | [#x0CAA-#x0CB3] | [#x0CB5-#x0CB9]
//    | #x0CDE | [#x0CE0-#x0CE1] | [#x0D05-#x0D0C] | [#x0D0E-#x0D10] | [#x0D12-#x0D28] | [#x0D2A-#x0D39] | [#x0D60-#x0D61] | [#x0E01-#x0E2E] | #x0E30
//    | [#x0E32-#x0E33] | [#x0E40-#x0E45] | [#x0E81-#x0E82] | #x0E84 | [#x0E87-#x0E88] | #x0E8A | #x0E8D | [#x0E94-#x0E97] | [#x0E99-#x0E9F]
//    | [#x0EA1-#x0EA3] | #x0EA5 | #x0EA7 | [#x0EAA-#x0EAB] | [#x0EAD-#x0EAE] | #x0EB0 | [#x0EB2-#x0EB3] | #x0EBD | [#x0EC0-#x0EC4] | [#x0F40-#x0F47]
//    | [#x0F49-#x0F69] | [#x10A0-#x10C5] | [#x10D0-#x10F6] | #x1100 | [#x1102-#x1103] | [#x1105-#x1107] | #x1109 | [#x110B-#x110C] | [#x110E-#x1112]
//    | #x113C | #x113E | #x1140 | #x114C | #x114E | #x1150 | [#x1154-#x1155] | #x1159 | [#x115F-#x1161] | #x1163 | #x1165 | #x1167 | #x1169
//    | [#x116D-#x116E] | [#x1172-#x1173] | #x1175 | #x119E | #x11A8 | #x11AB | [#x11AE-#x11AF] | [#x11B7-#x11B8] | #x11BA | [#x11BC-#x11C2] | #x11EB
//    | #x11F0 | #x11F9 | [#x1E00-#x1E9B] | [#x1EA0-#x1EF9] | [#x1F00-#x1F15] | [#x1F18-#x1F1D] | [#x1F20-#x1F45] | [#x1F48-#x1F4D] | [#x1F50-#x1F57]
//    | #x1F59 | #x1F5B | #x1F5D | [#x1F5F-#x1F7D] | [#x1F80-#x1FB4] | [#x1FB6-#x1FBC] | #x1FBE | [#x1FC2-#x1FC4] | [#x1FC6-#x1FCC] | [#x1FD0-#x1FD3]
//    | [#x1FD6-#x1FDB] | [#x1FE0-#x1FEC] | [#x1FF2-#x1FF4] | [#x1FF6-#x1FFC] | #x2126 | [#x212A-#x212B] | #x212E | [#x2180-#x2182] | [#x3041-#x3094]
//    | [#x30A1-#x30FA] | [#x3105-#x312C] | [#xAC00-#xD7A3]
//    [86]    Ideographic    ::=    [#x4E00-#x9FA5] | #x3007 | [#x3021-#x3029]
//    [87]    CombiningChar    ::=    [#x0300-#x0345] | [#x0360-#x0361] | [#x0483-#x0486] | [#x0591-#x05A1] | [#x05A3-#x05B9] | [#x05BB-#x05BD] | #x05BF
//    | [#x05C1-#x05C2] | #x05C4 | [#x064B-#x0652] | #x0670 | [#x06D6-#x06DC] | [#x06DD-#x06DF] | [#x06E0-#x06E4] | [#x06E7-#x06E8] | [#x06EA-#x06ED]
//    | [#x0901-#x0903] | #x093C | [#x093E-#x094C] | #x094D | [#x0951-#x0954] | [#x0962-#x0963] | [#x0981-#x0983] | #x09BC | #x09BE | #x09BF
//    | [#x09C0-#x09C4] | [#x09C7-#x09C8] | [#x09CB-#x09CD] | #x09D7 | [#x09E2-#x09E3] | #x0A02 | #x0A3C | #x0A3E | #x0A3F | [#x0A40-#x0A42]
//    | [#x0A47-#x0A48] | [#x0A4B-#x0A4D] | [#x0A70-#x0A71] | [#x0A81-#x0A83] | #x0ABC | [#x0ABE-#x0AC5] | [#x0AC7-#x0AC9] | [#x0ACB-#x0ACD]
//    | [#x0B01-#x0B03] | #x0B3C | [#x0B3E-#x0B43] | [#x0B47-#x0B48] | [#x0B4B-#x0B4D] | [#x0B56-#x0B57] | [#x0B82-#x0B83] | [#x0BBE-#x0BC2]
//    | [#x0BC6-#x0BC8] | [#x0BCA-#x0BCD] | #x0BD7 | [#x0C01-#x0C03] | [#x0C3E-#x0C44] | [#x0C46-#x0C48] | [#x0C4A-#x0C4D] | [#x0C55-#x0C56]
//    | [#x0C82-#x0C83] | [#x0CBE-#x0CC4] | [#x0CC6-#x0CC8] | [#x0CCA-#x0CCD] | [#x0CD5-#x0CD6] | [#x0D02-#x0D03] | [#x0D3E-#x0D43] | [#x0D46-#x0D48]
//    | [#x0D4A-#x0D4D] | #x0D57 | #x0E31 | [#x0E34-#x0E3A] | [#x0E47-#x0E4E] | #x0EB1 | [#x0EB4-#x0EB9] | [#x0EBB-#x0EBC] | [#x0EC8-#x0ECD]
//    | [#x0F18-#x0F19] | #x0F35 | #x0F37 | #x0F39 | #x0F3E | #x0F3F | [#x0F71-#x0F84] | [#x0F86-#x0F8B] | [#x0F90-#x0F95] | #x0F97 | [#x0F99-#x0FAD]
//    | [#x0FB1-#x0FB7] | #x0FB9 | [#x20D0-#x20DC] | #x20E1 | [#x302A-#x302F] | #x3099 | #x309A
//    [88]    Digit    ::=    [#x0030-#x0039] | [#x0660-#x0669] | [#x06F0-#x06F9] | [#x0966-#x096F] | [#x09E6-#x09EF] | [#x0A66-#x0A6F] | [#x0AE6-#x0AEF]
//    | [#x0B66-#x0B6F] | [#x0BE7-#x0BEF] | [#x0C66-#x0C6F] | [#x0CE6-#x0CEF] | [#x0D66-#x0D6F] | [#x0E50-#x0E59] | [#x0ED0-#x0ED9] | [#x0F20-#x0F29]
//    [89]    Extender    ::=    #x00B7 | #x02D0 | #x02D1 | #x0387 | #x0640 | #x0E46 | #x0EC6 | #x3005 | [#x3031-#x3035] | [#x309D-#x309E] | [#x30FC-#x30FE]
//    
// 
/***** DOUG
define method parse-document(string, #key start = 0, end: stop)
  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(prolog, elemnt, misc);
    values(index, #t);
  end with-meta-syntax;
end method parse-document;

*****/

define method parse-encoding-info(string, #key start = 0, end: stop)
  local method is-not-single-quote?(char :: <character>)
      char ~= '\'';
  end method is-not-single-quote?;

  local method is-not-double-quote?(char :: <character>)
      char ~= '"';
  end method is-not-double-quote?;

  with-meta-syntax parse-string (string, start: start, pos: index)
    variables(c, space, eq, version-num);
    ["encoding",
     parse-eq(eq),
     {['\'',
       [test(is-not-single-quote?, c), loop(test(is-not-single-quote?, c))],
       '\''],
      ['"',
       [test(is-not-double-quote?, c), loop(test(is-not-double-quote?, c))],
       '"']}];
    values(index, #t);
  end with-meta-syntax;
end method parse-encoding-info;


define method parse-xml-attributes (string, #key start = 0, end: stop)
  with-collector into-table attribute-table = make(<table>), collect: collect;
    with-meta-syntax parse-string (string, start: start, pos: index)
      variables(attribute-name, eq, attribute-value, space);
      {loop([parse-name(attribute-name),
             parse-eq(eq),
             parse-xml-attribute(attribute-value),
             loop(parse-s(space)),
             do(collect(attribute-name, attribute-value))]),
       []};
      values(index, attribute-table);
    end with-meta-syntax;
  end with-collector;
end method parse-xml-attributes;

define method parse-xml-element-start(builder :: <xml-builder>, 
    string, #key start = 0, end: stop)
  let attributes = make(<table>);
  with-meta-syntax parse-string (string, start: start, pos: index)
 // DOUG   variables(c, element-name, attributes, space, embedded-end-tag);
    variables(c, element-name, space, embedded-end-tag);
    ["<",
     parse-name(element-name),
 // DOUG   loop(parse-s(space)),
 // DOUG   parse-xml-attributes(attributes),
     {["/", yes!(embedded-end-tag)], []},
     ">"];
    let tag :: <xml-element> = make(<xml-element>, 
       name: element-name, attributes: attributes);
    start-element(builder, tag);
    if(embedded-end-tag)
      end-element(builder, tag);
    end if;
    values(index, tag);
  end with-meta-syntax;
end method parse-xml-element-start;
