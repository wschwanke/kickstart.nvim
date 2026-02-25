; extends

; Inline: query := /* sql */ `...`
((comment) @_comment . (raw_string_literal) @injection.content
  (#match? @_comment "sql")
  (#set! injection.language "sql"))

; Above: // sql
;        query := `...`
((comment) @_comment .
  (short_var_declaration
    right: (expression_list
      (raw_string_literal) @injection.content))
  (#match? @_comment "sql")
  (#set! injection.language "sql"))

((comment) @_comment .
  (var_declaration
    (var_spec
      value: (expression_list
        (raw_string_literal) @injection.content)))
  (#match? @_comment "sql")
  (#set! injection.language "sql"))
