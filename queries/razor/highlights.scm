;; inherits: c_sharp

[
  (razor_comment)
  (html_comment)
] @comment @spell (#set! "priority" 200)

[
  "at_page"
  "at_using"
  "at_model"
  "at_rendermode"
  "at_inject"
  "at_implements"
  "at_layout"
  "at_inherits"
  "at_attribute"
  "at_typeparam"
  "at_namespace"
  "at_preservewhitespace"
  "at_block"
  "at_at_escape"
  "at_colon_transition"
] @constant.macro (#set! "priority" 200)

[
  "at_lock"
  "at_section"
] @keyword (#set! "priority" 200)

[
  "at_if"
  "at_switch"
] @keyword.conditional (#set! "priority" 200)

[
  "at_for"
  "at_foreach"
  "at_while"
  "at_do"
] @keyword.repeat (#set! "priority" 200)

[
  "at_try"
  "catch"
  "finally"
] @keyword.exception (#set! "priority" 200)

[
  "at_implicit"
  "at_explicit"
] @variable (#set! "priority" 200)

"at_await" @keyword.coroutine (#set! "priority" 200)

(razor_rendermode) @property (#set! "priority" 200)

(razor_attribute_name) @function (#set! "priority" 200)
