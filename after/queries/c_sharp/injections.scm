; extends

; Inline: var query = /* sql */ @"..." or $"..." or """..."""
((comment) @_comment . (verbatim_string_literal) @injection.content
  (#match? @_comment "sql")
  (#set! injection.language "sql"))

((comment) @_comment . (raw_string_literal) @injection.content
  (#match? @_comment "sql")
  (#set! injection.language "sql"))

((comment) @_comment . (interpolated_string_expression) @injection.content
  (#match? @_comment "sql")
  (#set! injection.language "sql"))
