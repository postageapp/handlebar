This is an example document with simple {{placeholder}} values included.

Each of these {{variable}} substitutions can be either {{simple}},
{{=literal}}, {{%url_escaped}}, {{.css_escaped}}, {{$json_escaped}} or
{{&html_escaped}} depending on preference.

It's even possible to reference other {{*templates}} by name or include
the default one using {{*}}

Sometimes it's practical to define a block which can be re-used. These are
called sections:

{{@section}}
{{title}}

{{@bullet_point}}
* {{point}}
{{@/}}
{{@/section}}

{{?conditional}}
It's also possible to render sections conditionally by testing if a value
is present and true.
{{?/}}

* For avoiding interpolation, {{{three}}} or more braces can be used. The
  outer most ones are always stripped, the rest left alone.

* Entire sections can be left unprocessed by declaring {{#raw}} which will
  be terminated upon the first instance of {{#/}} if found.
