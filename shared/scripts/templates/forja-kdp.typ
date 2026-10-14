// Plantilla genérica orientada a KDP para los PDF de Forja. Los valores los
// suministra scripts/build-pdf.ps1 para reutilizar la plantilla por formato.

#let horizontalrule = align(center, text(fill: rgb("888888"), size: 0.9em, "* * *"))

// Propiedades del PDF desde el frontmatter (ADR 0038). El autor debe ser texto
// plano; Pandoc lo entrega como contenido, así que se convierte.
#let content-to-string = (content) => {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(content-to-string).join("")
  } else if content.has("body") {
    content-to-string(content.body)
  } else if content == [ ] {
    " "
  }
}
#set document(
  $if(title)$title: [$title$],$endif$
  $if(author)$author: ($for(author)$content-to-string([$author$]),$endfor$),$endif$
)

#set page(
  width: $if(page-width)$$page-width$$else$6in$endif$,
  height: $if(page-height)$$page-height$$else$9in$endif$,
  margin: (
    inside: $if(inner-margin)$$inner-margin$$else$0.875in$endif$,
    outside: $if(outer-margin)$$outer-margin$$else$0.5in$endif$,
    top: $if(top-margin)$$top-margin$$else$0.5in$endif$,
    bottom: $if(bottom-margin)$$bottom-margin$$else$0.5in$endif$,
  ),
  numbering: "1",
  number-align: center,
)

#set text(
  font: ("Georgia", "Times New Roman"),
  size: $if(font-size)$$font-size$$else$9.5pt$endif$,
  lang: "$if(lang)$$lang$$else$es$endif$",
  hyphenate: true,
)

#set par(
  leading: 0.9em,
  spacing: 0.6em,
  first-line-indent: 1.2em,
  justify: true,
)

#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  v(2em)
  align(center)[
    #text(size: 1.45em, weight: "bold")[#it.body]
  ]
  v(1em)
}

#show heading.where(level: 2): it => {
  v(0.8em)
  text(size: 1.15em, weight: "semibold")[#it.body]
  v(0.4em)
}

#show heading: it => {
  it
  set par(first-line-indent: 0pt)
}

$if(title)$
#align(center)[
  #v(2in)
  #text(size: 1.8em, weight: "bold")[$title$]
  $if(subtitle)$
  #v(0.6em)
  #text(size: 0.9em, style: "italic")[$subtitle$]
  $endif$
  $if(author)$
  #v(0.8em)
  #text(size: 1em)[$author$]
  $endif$
]
// El texto (o el índice) empieza en página impar, tras el dorso en blanco.
#pagebreak(to: "odd")
$endif$

$if(toc)$
#outline(
  title: [Índice],
  depth: 1,
  indent: auto,
)
$endif$

$body$
