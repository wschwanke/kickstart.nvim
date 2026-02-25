; extends

; const query = /* sql */ `...`
(lexical_declaration
  (variable_declarator
    value: (template_string) @injection.content)
  (#lua-match? @injection.content "^`%s*%-%-")
  (#set! injection.language "sql")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.include-children))

; /* sql */ before template string (inline or above)
((comment) @_comment
  .
  (template_string) @injection.content
  (#lua-match? @_comment "/[*]%s*sql%s*[*]/")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.include-children)
  (#set! injection.language "sql"))

((comment) @_comment
  .
  (lexical_declaration
    (variable_declarator
      value: (template_string) @injection.content))
  (#lua-match? @_comment "/[*]%s*sql%s*[*]/")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.include-children)
  (#set! injection.language "sql"))

; /* graphql */
((comment) @_comment
  .
  (template_string) @injection.content
  (#lua-match? @_comment "/[*]%s*graphql%s*[*]/")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.include-children)
  (#set! injection.language "graphql"))

((comment) @_comment
  .
  (lexical_declaration
    (variable_declarator
      value: (template_string) @injection.content))
  (#lua-match? @_comment "/[*]%s*graphql%s*[*]/")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.include-children)
  (#set! injection.language "graphql"))

; /* html */
((comment) @_comment
  .
  (template_string) @injection.content
  (#lua-match? @_comment "/[*]%s*html%s*[*]/")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.include-children)
  (#set! injection.language "html"))

; /* css */
((comment) @_comment
  .
  (template_string) @injection.content
  (#lua-match? @_comment "/[*]%s*css%s*[*]/")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.include-children)
  (#set! injection.language "css"))
