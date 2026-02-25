; extends

; Inline: local query = --[[ sql ]] [[...]]
((comment) @_comment . (string) @injection.content
  (#match? @_comment "sql")
  (#set! injection.language "sql"))
