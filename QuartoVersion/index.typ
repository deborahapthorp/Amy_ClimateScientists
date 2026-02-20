// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}

//#assert(sys.version.at(1) >= 11 or sys.version.at(0) > 0, message: "This template requires Typst Version 0.11.0 or higher. The version of Quarto you are using uses Typst version is " + str(sys.version.at(0)) + "." + str(sys.version.at(1)) + "." + str(sys.version.at(2)) + ". You will need to upgrade to Quarto 1.5 or higher to use apaquarto-typst.")

// counts how many appendixes there are
#let appendixcounter = counter("appendix")
// make latex logo
// https://github.com/typst/typst/discussions/1732#discussioncomment-11286036
#let TeX = {
  set text(font: "New Computer Modern",)
  let t = "T"
  let e = text(baseline: 0.22em, "E")
  let x = "X"
  box(t + h(-0.14em) + e + h(-0.14em) + x)
}

#let LaTeX = {
  set text(font: "New Computer Modern")
  let l = "L"
  let a = text(baseline: -0.35em, size: 0.66em, "A")
  box(l + h(-0.32em) + a + h(-0.13em) + TeX)
}

#let firstlineindent=0.5in

// documentmode: man
#let man(
  title: none,
  runninghead: none,
  margin: (x: 1in, y: 1in),
  paper: "us-letter",
  font: ("Times", "Times New Roman"),
  fontsize: 12pt,
  leading: 18pt,
  spacing: 18pt,
  firstlineindent: 0.5in,
  toc: false,
  lang: "en",
  cols: 1,
  numbersections: false,
  numberdepth: 3,
  first-page: 1,
  suppresstitlepage: false,
  doc,
) = {

  if suppresstitlepage {counter(page).update(first-page)}

  set page(
    margin: margin,
    paper: paper,
    header-ascent: 50%,
    header: grid(
      columns: (9fr, 1fr),
      align(left)[#upper[#runninghead]],
      align(right)[#context counter(page).display()]
    )
  )
  

  

 

  set table(    
    stroke: (x, y) => (
        top: if y <= 1 { 0.5pt } else { 0pt },
        bottom: .5pt,
      )
  )

  set par(
    justify: false, 
    leading: leading,
    first-line-indent: firstlineindent
  )

  // Also "leading" space between paragraphs
  set block(spacing: spacing, above: spacing, below: spacing)

  set text(
    font: font,
    size: fontsize,
    lang: lang
  )
  
  show link: set text(blue)
  show "al.'s": "al.\u{2019}s"

  show quote: set pad(x: 0.5in)
  show quote: set par(leading: leading)
  show quote: set block(spacing: spacing, above: spacing, below: spacing)
  // show LaTeX
  show "TeX": TeX
  show "LaTeX": LaTeX

  // format figure captions
  show figure.where(kind: "quarto-float-fig"): it => block(width: 100%, breakable: false)[
    #if int(appendixcounter.display().at(0)) > 0 [
      #heading(level: 2, outlined: false)[#it.supplement #appendixcounter.display("A")#it.counter.display()]
    ] else [
      #heading(level: 2, outlined: false)[#it.supplement #it.counter.display()]
    ]
    #align(left)[#par[#emph[#it.caption.body]]]
    #align(center)[#it.body]
  ]
  
  // format table captions
  show figure.where(kind: "quarto-float-tbl"): it => block(width: 100%, breakable: false)[#align(left)[
  
    #if int(appendixcounter.display().at(0)) > 0 [
      #heading(level: 2, outlined: false, numbering: none)[#it.supplement #appendixcounter.display("A")#it.counter.display()]
    ] else [
      #heading(level: 2, outlined: false, numbering: none)[#it.supplement #it.counter.display()]
    ]
    #par[#emph[#it.caption.body]]
    #block[#it.body]
  ]]
  
    set heading(numbering: "1.1")
    
    show heading: set text(size: fontsize)


 // Redefine headings up to level 5 
  show heading.where(
    level: 1
  ): it => block(width: 100%, below: leading, above: leading)[
    #set align(center)
    #if(numbersections and it.outlined and numberdepth > 0 and counter(heading).get().at(0) > 0) [#counter(heading).display()] #it.body
  ]
  
  show heading.where(
    level: 2
  ): it => block(width: 100%, below: leading, above: leading)[
    #set align(left)
    #if(numbersections and it.outlined and numberdepth > 1 and counter(heading).get().at(0) > 0) [#counter(heading).display()] #it.body
  ]
  
  show heading.where(
    level: 3
  ): it => block(width: 100%, below: leading, above: leading)[
    #set align(left)
    #set text(style: "italic")
    #if(numbersections and it.outlined and numberdepth > 2 and counter(heading).get().at(0) > 0) [#counter(heading).display()] #it.body
  ]

  show heading.where(
    level: 4
  ): it => text(
    weight: "bold",
    it.body
  )

  show heading.where(
    level: 5
  ): it => text(
    weight: "bold",
    style: "italic",
    it.body
  )
  
  

  if cols == 1 {
    doc
  } else {
    columns(cols, gutter: 4%, doc)
  }
  



}


#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
)

#show: document => man(
  runninghead: "CLIMATE SCIENTISTS AND MENTAL HEALTH",
  numberdepth: 3,
  document,
)

\
\
#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Climate Scientists and mental health: Wellbeing, burnout and hope for the future
]
)
]
#set align(center)
#block[
\
Amy Lykins#super[1];, Suzanne M. Cosh#super[2,1];, Nicola Paul#super[1,3];, Jude Fox#super[1];, and Deborah Apthorp#super[1,4]

#super[1];School of Psychology, University of New England

#super[2];School of Psychology, University of Adelaide

#super[3];UNE Business School, University of New England

#super[4];School of Medicine and Psychology, Australian National University

]
#set align(left)
\
\
#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Author Note
]
)
]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Amy Lykins #box(image("_extensions/wjschne/apaquarto/ORCID-iD_icon-vector.svg", width: 4.23mm)) #link("https://orcid.org/0000-0003-2930-3964")

Suzanne M. Cosh #box(image("_extensions/wjschne/apaquarto/ORCID-iD_icon-vector.svg", width: 4.23mm)) #link("https://orcid.org/0000-0002-8003-3704")

Nicola Paul #box(image("_extensions/wjschne/apaquarto/ORCID-iD_icon-vector.svg", width: 4.23mm)) #link("https://orcid.org/0000-0001-8423-8742")

Deborah Apthorp #box(image("_extensions/wjschne/apaquarto/ORCID-iD_icon-vector.svg", width: 4.23mm)) #link("https://orcid.org/0000-0001-5785-024X")

This study was preregistered at the #link("https://osf.io/xegr7/registrations")[OSF] Raw data and code for the study are available on the OSF \[link\]

Correspondence concerning this article should be addressed to Amy Lykins, School of Psychology, University of New England, Armidale, NSW 2351, Australia, Email: #link("mailto:alykins@une.edu.au")[alykins\@une.edu.au]

#pagebreak()

#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Abstract
]
)
]
#block[
Abstract goes here

]
#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Impact Statement
]
)
]
#block[
This study reveals important information about the wellbeing of climate scientists

]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
#emph[Keywords];: Climate change, Climate scientists, Climate anxiety

#pagebreak()

#block[
#heading(
level: 
1
, 
numbering: 
none
, 
outlined: 
false
, 
[
Climate Scientists and mental health: Wellbeing, burnout and hope for the future
]
)
]
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
The threat of climate change's consequences to human physical health have long been recognised, whilst the threat to mental health has received increasing attention over the past 10-15 years (#link(<ref-doherty_psychological_2011>)[Doherty & Clayton, 2011];). Researchers have proposed these effects to occur via one or more of three pathways: 1) direct exposure to extreme weather events (e.g., wildfires, floods); 2) indirect effects of extreme weather and long-term climatic changes (e.g., social unrest, forced migration); and 3) distress associated with the awareness of climate change and its anticipated consequences (#link(<ref-berry_climate_2010>)[Berry et al., 2010];), often referred to as 'climate anxiety' or 'eco-anxiety' (#link(<ref-clayton_climate_2020>)[Clayton, 2020];). Though there is no generally agreed-upon definition of this construct (#link(<ref-van_dijk_limited_2025>)[Dijk et al., 2025];), research has flourished in this space in recent years, showing reliably consistent relationships with symptoms of depression, anxiety, and stress (#link(<ref-cosh_relationship_2024>)[Cosh et al., 2024];), as well as \[MORE HERE\]

Some groups (e.g., children and young people) are considered to be at disproportionately high risk of experiencing psychological distress related to climate change in anticipation of futures that feel uncertain and dangerous (#link(<ref-crandon_socialecological_2022>)[Crandon et al., 2022];). One other group proposed to be at high risk of climate-related distress comprises people whose work brings them into regular contact with the effects of climate change: namely, climate scientists (#link(<ref-pihkala_cost_2020>)[Pihkala, 2020];).

Despite potential interest, little empirical data currently exist on the mental health and well-being of the world's climate scientists, and that which does exist largely relies on relatively small sample sizes. Several studies analysed 44 letters written by climate scientists posted on Duggan's "Is this how you feel?" website (#link("www.isthishowyoufeel.com");), reporting frustration and sadness as most frequently mentioned related to climate change (#link(<ref-clayton_mental_2018>)[Clayton, 2018];), along with the strain associated with managing multiple identities (e.g., personal, parental, scientist, messenger) in the context of their work and lives (#link(<ref-clayton_mental_2018>)[Clayton, 2018];). Similar themes were found in two qualitative studies. Head and Harada (#link(<ref-head_keeping_2017>)[2017];) interviewed 13 Australian climate scientists, observing the tension between the need to remain dispassionate and objective in their work, yet on a personal level continuing to experience painful emotions associated with aspects of their work (e.g., evidence of advancing climate change, receiving hate mail and death threats), often resulting in the need to compartmentalise their work from the rest of their lives. Renouf (#link(<ref-renouf_making_2021>)[2021];) \['s\] interviews with 16 climate experts across 12 countries also revealed a range of negative emotions experienced, including anxiety, sadness, and rage. Compartmentalising efforts were less successful in this sample, with findings showing climate change to have permeated these experts' personal lives significantly.

Critically, research has also revealed positive emotions experienced by climate scientists, with reports of hope, optimism, fascination, and determination (#link(<ref-clayton_mental_2018>)[Clayton, 2018];), along with enjoyment found in the work (#link(<ref-head_keeping_2017>)[Head & Harada, 2017];). Unfortunately, the balance of reports skews negative (#link(<ref-haddaway_safe_2023>)[Haddaway & Duggan, 2023];), with positive emotions sometimes only being reported when asked about specifically (#link(<ref-renouf_making_2021>)[Renouf, 2021];). A common theme amongst research in this area is increasing pessimism that the required changes will be made in time to avoid the most severe impacts of climate change (#link(<ref-head_keeping_2017>)[Head & Harada, 2017];; #link(<ref-renouf_making_2021>)[Renouf, 2021];; #link(<ref-tollefson_top_2021>)[Tollefson, 2021];).

Early efforts into understanding how climate scientists cope with these feelings and the different roles and responsibilities they have in life suggested an emphasis on dispassion, denial, or suppression of these emotions, as well as avoiding consideration of the implications of their findings (#link(<ref-head_keeping_2017>)[Head & Harada, 2017];). More recently, a study of 215 Lithuanian climate experts revealed both problem-focused (i.e., direct efforts in solving climate change issues) and emotion-focused (i.e., delving into feelings, seeking external support) coping strategies preferred over avoidance-based coping (i.e., trying not to think about it; #link(<ref-jovarauskaite_emotional_2021>)[Jovarauskaite & Böhm, 2021];). Though these results are yet to be replicated, they provide a unique and testable assessment of how climate scientists may be coping with feelings of anxiety, anger, and pessimism.

A recent scoping review emphasised the emotional burden climate scientists may experience given their frequent and direct proximity with the newest and most threatening information about climate change (#link(<ref-calabria_scoping_2024>)[Calabria & Marks, 2024];). Combined with a work environment that encourages dispassionate objectivity, alongside often regular and vitriolic personal and professional attacks and a worldwide relative lack of action to curb climate change, climate scientists are uniquely at risk of moral distress and moral injury (#link(<ref-calabria_scoping_2024>)[Calabria & Marks, 2024];). These feelings have been observed in young people (#link(<ref-henritze_moral_2023>)[Henritze et al., 2023];); however, in this population, this has been associated with a perceived lack of agency to effect change, which may not be as much a factor for climate scientists who are actively working on the problem (#link(<ref-calabria_scoping_2024>)[Calabria & Marks, 2024];). Given that higher perceived efficacy in mitigating the effects of climate change may support mental health and well-being in the face of climate distress (#link(<ref-ojala_anxiety_2021>)[Ojala et al., 2021];), it is also possible that engaging in climate science itself serves to protect climate scientists' well-being in the face of these challenges. However, to our knowledge, no one has yet examined these relationships in this population.

To address this knowledge gap, we aimed to recruit a large, international sample of climate scientists to investigate experiences of personal and work-related burnout, psychological distress, and well-being in people engaged in some aspect of climate science. To examine potential differences across time, we collected data via a mixed-methods online survey in two waves eight years apart (2017, 2025). In this paper, we focus only on the quantitative data. Our hypotheses and analytic strategy were pre-registered on the #link("https://osf.io/xegr7/registrations")[OSF];. Based on the extant literature, we hypothesised:

+ Mental ill-health, as assessed by the DASS-21, will be significantly poorer (i.e., greater endorsement of symptoms) in Time 2 than in Time 1
+ Personal burnout will be significantly higher in Time 2 than in Time 1
+ US-based participants will have lower well-being than non-US-based scientists
+ Personal burnout will be significantly higher than work burnout
+ Problem-focused coping will be associated with greater well-being than emotion-focused coping or avoidance
+ Organisational support will moderate the relationship between work burnout and well-being.

= Results
<results>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Hypothesis 1 was that mental ill-health, as assessed by the DASS-21, would be significantly poorer (i.e., greater endorsement of symptoms) at Time 2 than in Time 1. To test this, we carried out three non-parametric t-tests (Mann-Whitney U) on the three subscales of the DASS-21, Depression, Anxiety, and Stress, since the data were heavily right-skewed. This comparison was significant only for anxiety, $W = 10 \, 046.00$, $p = .005$, but not for depression, $W = 11 \, 153.50$, $p = .075$ or stress, $W = 11 \, 806.50$, $p = .217$. Thus Hypothesis 1 was partially supported. These differences are illustrated in #link(<fig-DASS>)[Figure~1];.

Hypothesis 2 was that personal burnout at Time 2 would be higher than at Time 1. Since the data for these scales were more normally distributed, we tested this with a Welch's single-tailed independent samples t-test, since the hypothesis was directional and the variances were unequal. We also tested work burnout, using a two-tailed test since this hypothesis was not preregistered. Personal burnout as measured by the Copenhagen Burnout Inventory was significantly higher at Time 2 compared to Time 1, $Delta M = - 7.57$, 95% CI $[- oo \, - 3.49]$, $t (87.26) = - 3.09$, $p = .001$. Work burnout was also significantly higher, $Delta M = - 8.93$, 95% CI $[- 13.62 \, - 4.24]$, $t (88.99) = - 3.78$, $p < .001$. This difference is illustrated in #link(<fig-CBI>)[Figure~2];.

Hypothesis 3 was that, at Time 2, wellbeing would be significantly lower for US-based participants compared to their non-US counterparts. To test this, we first grouped the data into those who responded that they were US-based for work, using string-matching to "US", "USA" or "United States", and those who were based elsewhere. We then compared these groups on the wellbeing scale (SWEMS) using a general linear model, controlling for age and gender. The results are presented in #link(<fig-USA>)[Figure~3] and #link(<tbl-USA>)[Table~1];. Hypothesis 3 was not supported; the difference in wellbeing was not significant, $b = - 0.11$, 95% CI $[- 0.23 \, 0.02]$, $t = - 1.61$, $p = .108$.

Hypothesis 4 was that personal burnout would be higher than work burnout across both waves. This analysis was a one-tailed paired-samples t-test, since all participants completed both subscales of the Copenhagen Burnout Inventory, and our hypothesis was directional. This hypothesis was supported, with a mean difference of 3.31 percentage points, $M_D = 3.31$, 95% CI $[2.38 \, oo]$, $t (485) = 5.90$, $p < .001$. The results are illustrated in #link(<fig-CBI-paired>)[Figure~4];.

Hypothesis 5 was that problem-focused coping as a strategy would be associated with greater well-being than emotion-focused coping or avoidance. For this analysis we conducted a multiple regression with psychological wellbeing (as measured by the SWEMBS) as the outcome variable, with the three coping subscales as predictors, and age and gender as control variables. Hypothesis 5 was not supported; after controlling for age and gender, only avoidance was associated (strongly, and negatively) with wellbeing, $b = - 0.15$, 95% CI $[- 0.23 \, - 0.07]$, $t (400) = - 3.86$, $p < .001$. The whole model was significant, $R^2 = .12$, 90% CI $[0.07 \, 0.17]$, $F (5 \, 400) = 11.42$, $p < .001$. The full results are presented in #link(<tbl-hyp5>)[Table~2];.

For Hypothesis 6, that organisational support would moderate the relationship between work burnout and wellbeing, we conducted a multiple regression analysis with psychological wellbeing as the DV, work burnout and perceived organisational support (SPOS score) as the IVs, and an interaction term between work burnout and SPOS, with age and gender as control variables. From #link(<tbl-hyp6>)[Table~3];, it is clear that Hypothesis 6 is also not supported; although work burnout had a large and highly significant negative effect on wellbeing, $b = - 0.02$, 95% CI $[- 0.02 \, - 0.01]$, $t (400) = - 11.69$, $p < .001$, and perceived organisational support has a small marginal effect, $b = 0.03$, 95% CI $[0.00 \, 0.06]$, $t (400) = 2.08$, $p = .038$, the interaction between them was not significant, $b = 0.00$, 95% CI $[0.00 \, 0.00]$, $t (400) = - 0.38$, $p = .703$. The whole model was significant, $R^2 = .36$, 90% CI $[0.29 \, 0.42]$, $F (5 \, 400) = 45.70$, $p < .001$.

= Discussion
<discussion>
== Limitations and Future Directions
<limitations-and-future-directions>
== Conclusion
<conclusion>
= Online Methods
<online-methods>
== Participants
<participants>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Wave 1 participants were recruited between 1 March and 23 June, 2017. In total, 61 participants (51 male, 10 female) with a mean age of 54.2 years (SD = 13.0, range: 23 -- 80 years) completed the online survey. More than 90% reported their highest relevant degree obtained as a PhD, with 6.6% reporting master's degree, and 3.3% reporting other (e.g., Scientiae Doctor). Participants primarily resided in the United States (n = 23), Australia (n = 15), and the United Kingdom (n = 13), with two participants from Canada and one each from Brazil, Denmark, France, Germany, Netherlands, New Zealand, Norway, and Switzerland. The majority of participants reported conducting most of their research in their home countries, but others mentioned 'Europe wide,' along with France, Greenland, and Republic of Korea. Participants reported between 3 and 55 years of experience in the field of climate science (M = 29.49 years, SD = 12.34), and described their work as climate science (n = 18), atmospheric science (n = 12), climate modelling (n = 5), oceanography or marine science (n = 5), climate policy (n = 3), or with other terms (n = 16) including glaciology, ecosystems, and paleoclimatology. Wave 2 participants were recruited between 3 March and 1 July, 2025. Overall, 427 participants (250 male, 158 female, 19 'other' or prefer not to say) with a mean age of 54.05 years (SD = 12.32, range = 27 -- 85) completed the online survey. Highest degree obtained was Ph.D.~for 96% of our participants, followed by master's degree (2.3%), bachelor's/honours (0.4%), and other (1.2%; Doctor of Science, M.D., D.V.M.).

== Measures: Wave 1 and 2
<measures-wave-1-and-2>
=== Demographics
<demographics>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Participants were asked a series of demographic questions including age, gender identity, highest level of education attained, the country in which they resided, the country/countries in which they conducted their research, the type of organisation they worked for, and the nature of their role within that organisation.

=== Depression Anxiety Stress Scales (DASS-21)
<depression-anxiety-stress-scales-dass-21>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
The DASS-21 (#link(<ref-lovibond_manual_1995>)[S. H. Lovibond & Lovibond, 1995];) is a 21-item self-report screening measure of depression, anxiety, and stress symptoms experienced over the preceding week. Item response options ranged from 0 (#emph[never];) to 3 (#emph[almost always];). The DASS-21 has well-validated clinical cut-offs identified for mild, moderate, severe, and extremely severe presentations of symptoms on each subscale, with moderate symptoms established as a baseline for clinical relevance. The DASS-21 consistently has been shown to have good psychometric properties (#link(<ref-lovibond_structure_1995>)[P. F. Lovibond & Lovibond, 1995];). Cronbach's alphas in the current samples were .89, .80, and .89 for depression, anxiety and stress respectively.

=== Copenhagen Burnout Inventory (CBI)
<copenhagen-burnout-inventory-cbi>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Two subscales of the CBI (#link(<ref-kristensen_copenhagen_2005>)[Kristensen et al., 2005];) were used to assess the personal burnout (e.g., #emph[How often do you feel worn out?];; 6 items) and work-related burnout (e.g., #emph[Is your work emotionally exhausting?];; 7 items) experiences of our participants. Likert-scale response options ranged from (#emph[never/almost never] or #emph[to a very low degree];) to 100 (#emph[always or to a very high degree];), with three other response options available valued at 25, 50, and 75. Kristensen et al. (#link(<ref-kristensen_copenhagen_2005>)[2005];) reported very high internal reliability and occupational differentiation, indicating good validity. Correlations with assessments of fatigue and psychological well-being were found in the predicted directions, and burnout scores predicted other self-reported well-being indicators such as future sickness absence, sleep problems, and intention to quit. Cronbach's alphas in the current samples for personal and work-related burnout were .91 and .89, respectively.

== Measures: Wave 2
<measures-wave-2>
=== Short Warwick-Edinburgh Mental Well-being Scale (SWEMWBS).
<short-warwick-edinburgh-mental-well-being-scale-swemwbs.>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
The SWEMWBS (#link(<ref-shah_short_2021>)[Shah et al., 2021];) is a widely used 7-item shortened version of the original Warwick-Edinburgh Mental Well-being Scale (#link(<ref-tennant_warwick-edinburgh_2007>)[Tennant et al., 2007];) designed to assess positive experiences of subjective mental well-being over the previous 2 weeks (e.g., #emph[I've been dealing with problems well];). Likert-scale response options ranged from 1 (#emph[none of the time];) to 5 (#emph[all of the time];). A recent systematic review confirmed the SWEMWBS's good psychometric properties with respect to validity and reliability (#link(<ref-perera_psychometric_2025>)[Perera et al., 2025];). Cronbach's alpha in the current sample was .84.

=== Work and Meaning Inventory (WAMI)
<work-and-meaning-inventory-wami>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Participants completed the 10-item WAMI (#link(<ref-steger_measuring_2012>)[Steger et al., 2012];) to assess the degree to which they perceived their work as a subjectively meaningful experience. The WAMI is comprised of three subscales: positive meaning (e.g., #emph[I have a good sense of what makes my job meaningful];; 4 items), meaning making through work (e.g., #emph[My work helps me make sense of the world around me];; 3 items), and greater good motivations (e.g., #emph[The work I do serves a greater purpose];; 3 items). Likert-scale response options ranged from 1 (#emph[absolutely untrue];) to 5 (#emph[absolutely true];). Initial (#link(<ref-steger_measuring_2012>)[Steger et al., 2012];) and later (#link(<ref-paola_evaluating_2023>)[Paola et al., 2023];) assessments of the WAMI indicate its strong psychometric properties with respect to validity and reliability. Cronbach's alpha in the current sample was .89

=== Survey of Perceived Organizational Support (SPOS-8)
<survey-of-perceived-organizational-support-spos-8>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
The SPOS-8 (#link(<ref-bardhoshi_psychometric_2023>)[Bardhoshi et al., 2023];) is an 8-item shortened version of Eisenberger et al.'s (#link(<ref-eisenberger_perceived_1986>)[1986];) 36-item measure which was developed to assess an employee's general belief that their employer is committed to him/her/them, values the employee's ongoing membership, and is concerned about the employee's well-being (e.g., #emph[This organisation really cares about my well-being];). Likert-scale response options ranged from 0 (#emph[strongly disagree];) to 6 (#emph[strongly agree];). Assessments of the longer version have shown unidimensionality, reliability, and acceptable item-total correlations, and examinations of the 8-item version have shown good reliability (#link(<ref-bardhoshi_psychometric_2023>)[Bardhoshi et al., 2023];; #link(<ref-hellman_reliability_2006>)[Hellman et al., 2006];). Cronbach's alpha in the current sample was .92.

=== Hogg Eco-anxiety Scale (HEAS)
<hogg-eco-anxiety-scale-heas>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
The HEAS (#link(<ref-hogg_hogg_2021>)[Hogg et al., 2021];) is a 13-item scale designed to assess anxiety about a variety of environmental conditions (e.g., climate change, environmental degradation, and pollution) and one's personal negative impact on the planet across the preceding two weeks. The HEAS is comprised of 4 subscales: affective symptoms (e.g., #emph[not being able to stop or control worrying];; 4 items), rumination (e.g., #emph[unable to stop thinking about future climate change and other global environmental problems];; 3 items), behavioural symptoms (e.g., #emph[difficulty enjoying social situations with family and friends];; 3 items) , and anxiety about one's negative impact on the planet (e.g., #emph[feeling anxious that your personal behaviours will do little to help fix the problem];; 3 items). Likert-scale response options range from 0 (#emph[not at all];) to 3 (#emph[nearly every day];). The HEAS shows strong psychometric properties including good test-retest reliability, along with differentiation from more general stress, anxiety, and depression (#link(<ref-hogg_validation_2024>)[Hogg et al., 2024];). Cronbach's alphas from the current sample were .89 (affective), .88 (rumination), .83 (behavioural) and .89 (personal impact).

=== Coping Strategies.
<coping-strategies.>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
To assess how participants any distress they may experience related to climate change, participants completed the 11-item coping strategies scale for climate experts created by Jovarauskaite and Böhm (#link(<ref-jovarauskaite_emotional_2021>)[2021];). The scale breaks down coping strategies into three types: problem-focused strategies (e.g., #emph[\[I\] concentrate on the ways in which climate change can be solved];; 3 items), emotion-focused strategies (e.g., #emph[\[I\] tell others how I feel];; 4 items), and avoidance (e.g., #emph[\[I\] pretend that climate change is not happening];; 4 items). Likert-scale response options ranged from 1 (#emph[strongly disagree];) to 6 (#emph[strongly agree];). This scale was validated on a sample of Lithuanian climate experts, with the confirmatory factor analysis showing good model fit (#link(<ref-jovarauskaite_emotional_2021>)[Jovarauskaite & Böhm, 2021];). Because this scale is relatively new, we also conducted a confirmatory factor analysis to confirm its factor structure, with results indicating an acceptable 3-factor fit once item 8 from the avoidance subscale was removed (see Supplementary Materials). Cronbach's alphas in our sample were .82 for problem-focused coping, .86 for emotion-focused coping, and .71 for avoidance.

== Procedure
<procedure>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
All participants were recruited for an international study of climate scientists. Each participant was sent a personalised email invitation with a unique link to the online survey, hosted by the survey company Qualtrics. After providing informed consent, participants completed the demographic questions, followed by the other study measures in a randomised order. Participation took approximately 10 minutes.

In Wave 1, a member of the research team (J. F.) compiled a list of names and email addresses of researchers who had published in the area of climate science, including contributors to the Intergovernmental Panel on Climate Change (IPCC) publications. Personalised invitations were emailed to 538 individuals, with approximately 15% of them bouncing for various reasons (e.g., email address no longer being in use, individual on leave). The research team also approached a number of relevant governmental and non-governmental organisations, several of whom agreed to share our invitation to their members. In Wave 2, a different member of the research team (N. P.) conducted a National Institutes of Health (NIH) Medline search in December, 2023 of journal articles published with 'climate change' as a MeSH (Medical Subject Heading), resulting in more than 15,000 publications since 2009. Separately, we created a list of the names of authors of the IPCC 6th Assessment. After cross-checking and removing individuals listed more than once, and finding the email addresses of IPCC authors that were not listed in the Medline search via internet searches, our final contact list comprised 7,446 names and email addresses of individuals who either had published peer-reviewed journal articles in climate science or had contributed to the latest IPCC assessment at the time of recruitment. We first contacted all of these authors on 3 March, 2025 and sent one reminder (5 June, 2025) to everyone on this list before closing the survey in mid-July, 2025. We received approximately 500 email bounces on each contact (i.e., 1000+ total). Both waves of data collection received approval from the University of New England's Human Research Ethics Committee prior to participant recruitment (W1: HE17-032; W2: HE23-011)

== Data Analysis
<data-analysis>
#par()[#text(size:0.5em)[#h(0.0em)]]
#v(-18pt)
Data were analysed in R Statistical Software (Version 4.5.1) using R Studio (version 2025.09.1+401). Analysis code is available on GitHub (link). Analyses for each hypothesis were conducted according to the preregistered plan: for Hypothesis 1 (#emph[Mental health at time 2 will be poorer than at Time 1];), we used non-parametric t-tests (Mann-Whitney U) for each of the DASS subscales to compare Wave 2 with Wave 1. For Hypothesis 2 (#emph[Personal burnout at time 2 will be higher than at Time 1];), since the assumption of normality for the residuals was met, we used a one-tailed t-test, since the hypothesis was directional; we also compared work burnout using a two-tailed t-test as an exploratory analysis. For Hypothesis 3 (#emph[At Time 2, wellbeing will be significantly lower for US-based participants compared to their non-US counterparts];), we used a general linear model with psychological well-being (SWEMWBS score) as the DV, and geographical location (US-based vs.~non-US-based) as a factor, with age and gender as control variables. For Hypothesis 4 (#emph[Personal burnout will be higher than work burnout];), we used a paired-samples t-test on data from both time points for all participants. For Hypothesis 5 (#emph[Problem-focused coping will be associated with greater well-being than emotion-focused coping or avoidance];) we used a multiple linear regression with psychological well-being (SWEMWBS score) as the dependent variable, with IVs of the three different coping styles (i.e., problem-focused, emotion-focused, and avoidance), and age and gender as control variables; this analysis only used the Wave 2 data, as these variables were not collected in Wave 1. For Hypothesis 6 (#emph[Organisational support will moderate the relationship between work burnout and well-being];), we also used the Wave 2 data only, and we conducted a multiple linear regression with psychological wellbeing (SWEMWBS score) as the DV, organisational support (SPOS) and work burnout (CBI-work) as predictors, and an interaction term between SPOS and CBI-work; all variables were centred before running the model.

In addition to the preregistered analyses, we conducted a confirmatory factor analysis on the coping scales (#link(<ref-jovarauskaite_emotional_2021>)[Jovarauskaite & Böhm, 2021];), since it is a relatively new measure which has not been extensively validated. For this, we used the R package lavaan (#link(<ref-rosseel_lavaan_2025>)[Rosseel et al., 2025];), since there are established subscales onto which the items are designed to load (problem-focused coping, emotion-focused coping and avoidance). We used robust maximum likelihood for the estimator and full information maximum likelihood for missing values.

= References
<references>
#set par(first-line-indent: 0in, hanging-indent: 0.5in)
#block[
#block[
Bardhoshi, G., Erford, B. T., & Um, B. (2023). Psychometric Analysis of the Survey of Perceived Organizational Support (SPOS-8) Using 1,005 School Counselors. #emph[Measurement and Evaluation in Counseling and Development];, #emph[56];(3), 241--253. #link("https://doi.org/10.1080/07481756.2022.2070074")

] <ref-bardhoshi_psychometric_2023>
#block[
Berry, H. L., Bowen, K., & Kjellstrom, T. (2010). Climate change and mental health: A causal pathways framework. #emph[International Journal of Public Health];, #emph[55];(2), 123--132. #link("https://doi.org/10.1007/s00038-009-0112-0")

] <ref-berry_climate_2010>
#block[
Calabria, L., & Marks, E. (2024). A scoping review of the impact of eco-distress and coping with distress on the mental health experiences of climate scientists. #emph[Frontiers in Psychology];, #emph[15];. #link("https://doi.org/10.3389/fpsyg.2024.1351428")

] <ref-calabria_scoping_2024>
#block[
Clayton, S. (2018). Mental health risk and resilience among climate scientists. #emph[Nature Climate Change];, #emph[8];(4), 260--261. #link("https://doi.org/10.1038/s41558-018-0123-z")

] <ref-clayton_mental_2018>
#block[
Clayton, S. (2020). Climate anxiety: Psychological responses to climate change. #emph[Journal of Anxiety Disorders];, #emph[74];, 102263. #link("https://doi.org/10.1016/j.janxdis.2020.102263")

] <ref-clayton_climate_2020>
#block[
Cosh, S. M., Ryan, R., Fallander, K., Robinson, K., Tognela, J., Tully, P. J., & Lykins, A. D. (2024). The relationship between climate change and mental health: A systematic review of the association between eco-anxiety, psychological distress, and symptoms of major affective disorders. #emph[BMC Psychiatry];, #emph[24];(1), 833. #link("https://doi.org/10.1186/s12888-024-06274-1")

] <ref-cosh_relationship_2024>
#block[
Crandon, T. J., Scott, J. G., Charlson, F. J., & Thomas, H. J. (2022). A social--ecological perspective on climate anxiety in children and adolescents. #emph[Nature Climate Change];, #emph[12];(2), 123--131. #link("https://doi.org/10.1038/s41558-021-01251-y")

] <ref-crandon_socialecological_2022>
#block[
Dijk, S. van, Schie, K. van, Smeets, T., & Mertens, G. (2025). Limited consensus on what climate anxiety is: Insights from content overlap analysis on 12 questionnaires. #emph[Journal of Anxiety Disorders];, #emph[109];, 102957. #link("https://doi.org/10.1016/j.janxdis.2024.102957")

] <ref-van_dijk_limited_2025>
#block[
Doherty, T. J., & Clayton, S. (2011). The psychological impacts of global climate change. #emph[American Psychologist];, #emph[66];(4), 265--276. #link("https://doi.org/10.1037/a0023141")

] <ref-doherty_psychological_2011>
#block[
Eisenberger, R., Huntington, R., Hutchison, S., & Sowa, D. (1986). Perceived organizational support. #emph[Journal of Applied Psychology];, #emph[71];(3), 500--507. #link("https://doi.org/10.1037/0021-9010.71.3.500")

] <ref-eisenberger_perceived_1986>
#block[
Haddaway, N. R., & Duggan, J. (2023). “Safe Spaces” and Community Building for Climate Scientists, Exploring Emotions Through a Case Study. #emph[Global Environmental Psychology];, #emph[1];, 1--23. #link("https://doi.org/10.5964/gep.11347")

] <ref-haddaway_safe_2023>
#block[
Head, L., & Harada, T. (2017). Keeping the heart a long way from the brain: The emotional labour of climate scientists. #emph[Emotion, Space and Society];, #emph[24];, 34--41. #link("https://doi.org/10.1016/j.emospa.2017.07.005")

] <ref-head_keeping_2017>
#block[
Hellman, C. M., Fuqua, D. R., & Worley, J. (2006). A Reliability Generalization Study on the Survey of Perceived Organizational Support: The Effects of Mean Age and Number of Items on Score Reliability. #emph[Educational and Psychological Measurement];, #emph[66];(4), 631--642. #link("https://doi.org/10.1177/0013164406288158")

] <ref-hellman_reliability_2006>
#block[
Henritze, E., Goldman, S., Simon, S., & Brown, A. D. (2023). Moral injury as an inclusive mental health framework for addressing climate change distress and promoting justice-oriented care. #emph[The Lancet. Planetary Health];, #emph[7];(3), e238--e241. #link("https://doi.org/10.1016/S2542-5196(22)00335-7")

] <ref-henritze_moral_2023>
#block[
Hogg, T. L., Stanley, S. K., & O'Brien, L. V. (2024). Validation of the Hogg Climate Anxiety Scale. #emph[Climatic Change];, #emph[177];(6), 86. #link("https://doi.org/10.1007/s10584-024-03726-1")

] <ref-hogg_validation_2024>
#block[
Hogg, T. L., Stanley, S. K., O'Brien, L. V., Wilson, M. S., & Watsford, C. R. (2021). The Hogg Eco-Anxiety Scale: Development and validation of a multidimensional scale. #emph[Global Environmental Change];, #emph[71];, 102391. #link("https://doi.org/10.1016/j.gloenvcha.2021.102391")

] <ref-hogg_hogg_2021>
#block[
Jovarauskaite, L., & Böhm, G. (2021). The emotional engagement of climate experts is related to their climate change perceptions and coping strategies. #emph[Journal of Risk Research];, #emph[24];(8), 941--957. #link("https://doi.org/10.1080/13669877.2020.1779785")

] <ref-jovarauskaite_emotional_2021>
#block[
Kristensen, T. S., Borritz, M., Villadsen, E., & Christensen, K. B. (2005). The Copenhagen Burnout Inventory: A new tool for the assessment of burnout. #emph[Work & Stress];, #emph[19];(3), 192--207. #link("https://doi.org/10.1080/02678370500297720")

] <ref-kristensen_copenhagen_2005>
#block[
Lovibond, P. F., & Lovibond, S. H. (1995). The structure of negative emotional states: Comparison of the Depression Anxiety Stress Scales (DASS) with the Beck Depression and Anxiety Inventories. #emph[Behaviour Research and Therapy];, #emph[33];(3), 335--343. #link("https://doi.org/10.1016/0005-7967(94)00075-U")

] <ref-lovibond_structure_1995>
#block[
Lovibond, S. H., & Lovibond, P. F. (1995). #emph[Manual for the depression anxiety stress scales] (2nd ed). Psychology Foundation of Australia.

] <ref-lovibond_manual_1995>
#block[
Ojala, M., Cunsolo, A., Ogunbode, C. A., & Middleton, J. (2021). Anxiety, Worry, and Grief in a Time of Environmental and Climate Crisis: A Narrative Review. #emph[Annual Review of Environment and Resources];, #emph[46];(Volume 46, 2021), 35--58. #link("https://doi.org/10.1146/annurev-environ-012220-022716")

] <ref-ojala_anxiety_2021>
#block[
Paola, M., Rita, Z., & Giuseppe, S. (2023). Evaluating meaningful work: Psychometric properties of the Work and Meaning Inventory (WAMI) in Italian context. #emph[Current Psychology];, #emph[42];(15), 12756--12767. #link("https://doi.org/10.1007/s12144-021-02503-y")

] <ref-paola_evaluating_2023>
#block[
Perera, B. P. R., Wickremasinghe, A. R., & De Za, T. a. P. (2025). Psychometric properties of the Warwick Edinburgh Mental Well-being Scale: A systematic review. #emph[Systematic Reviews];, #emph[14];(1), 149. #link("https://doi.org/10.1186/s13643-025-02897-x")

] <ref-perera_psychometric_2025>
#block[
Pihkala, P. (2020). The Cost of Bearing Witness to the Environmental Crisis: Vicarious Traumatization and Dealing with Secondary Traumatic Stress among Environmental Researchers. #emph[Social Epistemology];, #emph[34];(1), 86--100. #link("https://doi.org/10.1080/02691728.2019.1681560")

] <ref-pihkala_cost_2020>
#block[
Renouf, J. S. (2021). Making sense of climate change---the lived experience of experts. #emph[Climatic Change];, #emph[164];(1), 14. #link("https://doi.org/10.1007/s10584-021-02986-5")

] <ref-renouf_making_2021>
#block[
Rosseel, Y., Jorgensen, T. D., Wilde, L. D., Oberski, D., Byrnes, J., Vanbrabant, L., Savalei, V., Merkle, E., Hallquist, M., Rhemtulla, M., Katsikatsou, M., Barendse, M., Rockwood, N., Scharf, F., Du, H., Jamil, H., & Classe, F. (2025). #emph[Lavaan: Latent Variable Analysis];. #link("https://cran.r-project.org/web/packages/lavaan/index.html")

] <ref-rosseel_lavaan_2025>
#block[
Shah, N., Cader, M., Andrews, B., McCabe, R., & Stewart-Brown, S. L. (2021). Short Warwick-Edinburgh Mental Well-being Scale (SWEMWBS): Performance in a clinical sample in relation to PHQ-9 and GAD-7. #emph[Health and Quality of Life Outcomes];, #emph[19];, 260. #link("https://doi.org/10.1186/s12955-021-01882-x")

] <ref-shah_short_2021>
#block[
Steger, M. F., Dik, B. J., & Duffy, R. D. (2012). Measuring meaningful work: The Work and Meaning Inventory (WAMI). #emph[Journal of Career Assessment];, #emph[20];(3), 322--337. #link("https://doi.org/10.1177/1069072711436160")

] <ref-steger_measuring_2012>
#block[
Tennant, R., Hiller, L., Fishwick, R., Platt, S., Joseph, S., Weich, S., Parkinson, J., Secker, J., & Stewart-Brown, S. (2007). The Warwick-Edinburgh Mental Well-being Scale (WEMWBS): Development and UK validation. #emph[Health and Quality of Life Outcomes];, #emph[5];, 63. #link("https://doi.org/10.1186/1477-7525-5-63")

] <ref-tennant_warwick-edinburgh_2007>
#block[
Tollefson, J. (2021). Top climate scientists are sceptical that nations will rein in global warming. #emph[Nature];, #emph[599];(7883), 22--24. #link("https://doi.org/10.1038/d41586-021-02990-w")

] <ref-tollefson_top_2021>
] <refs>
#set par(first-line-indent: 0.5in, hanging-indent: 0in)
#pagebreak(weak: true)
#figure([
#table(
  columns: 5,
  align: (left,left,left,left,left,),
  table.header([Predictor], [$b$], [95% CI], [$t$], [$p$],),
  table.hline(),
  [Intercept], [2.66], [\[2.38, 2.95\]], [18.57], [\< .001],
  [USATRUE], [-0.11], [\[-0.23, 0.02\]], [-1.61], [.108],
  [Age], [0.01], [\[0.01, 0.02\]], [4.38], [\< .001],
  [Gender], [0.14], [\[0.04, 0.24\]], [2.74], [.006],
)
], caption: figure.caption(
position: top, 
[
(\#tab:tbl-USA) Regression table for the GLM of wellbeing scores for participants within and outside the USA, controlling for age and gender
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-USA>


#pagebreak(weak: true)
#figure([
#table(
  columns: 6,
  align: (left,left,left,left,left,left,),
  table.header([Predictor], [$b$], [95% CI], [$t$], [$italic(d f)$], [$p$],),
  table.hline(),
  [Intercept], [-0.01], [\[-0.07, 0.05\]], [-0.36], [400], [.721],
  [Coping PF score], [0.03], [\[-0.03, 0.10\]], [1.06], [400], [.288],
  [Coping EF score], [0.04], [\[-0.01, 0.10\]], [1.46], [400], [.144],
  [Coping avoidance score], [-0.15], [\[-0.23, -0.07\]], [-3.86], [400], [\< .001],
  [Age], [0.01], [\[0.00, 0.01\]], [2.87], [400], [.004],
  [Gender], [0.13], [\[0.03, 0.22\]], [2.51], [400], [.012],
)
], caption: figure.caption(
position: top, 
[
(\#tab:tbl-hyp5) Coefficients for the multiple regression model of coping styles on wellbeing as measured by the SWEMWS scale
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-hyp5>


#pagebreak(weak: true)
#figure([
#table(
  columns: 6,
  align: (left,left,left,left,left,left,),
  table.header([Predictor], [$b$], [95% CI], [$t$], [$italic(d f)$], [$p$],),
  table.hline(),
  [Intercept], [-0.01], [\[-0.06, 0.04\]], [-0.35], [400], [.727],
  [Cbi work], [-0.02], [\[-0.02, -0.01\]], [-11.69], [400], [\< .001],
  [SPOS score], [0.03], [\[0.00, 0.06\]], [2.08], [400], [.038],
  [Age], [0.00], [\[0.00, 0.01\]], [0.93], [400], [.355],
  [Gender], [0.05], [\[-0.03, 0.13\]], [1.16], [400], [.248],
  [Cbi work $times$ SPOS score], [0.00], [\[0.00, 0.00\]], [-0.38], [400], [.703],
)
], caption: figure.caption(
position: top, 
[
(\#tab:tbl-hyp6) Coefficients for the multiple regression model of work burnout and perceived organisational support on wellbeing as measured by the SWEMWS scale
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-hyp6>


#pagebreak(weak: true)
#figure([
#box(image("index_files/figure-typst/fig-DASS-1.svg"))
], caption: figure.caption(
position: top, 
[
Mental health scores at Time 1 and Time 2 for the three subscales of the DASS-21
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-DASS>


#block[
#block[
#emph[Note];. This~is a raincloud plot showing individual scores and distributions for both time points.
]
]
#pagebreak(weak: true)
#figure([
#box(image("index_files/figure-typst/fig-CBI-1.svg"))
], caption: figure.caption(
position: top, 
[
Burnout scores for personal and work subscales of the Copenhagen Burnout Inventory at Times 1 and 2.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-CBI>


#block[
#block[
#emph[Note];. This~is a raincloud plot showing individual scores and distributions for both time points.
]
]
#pagebreak(weak: true)
#figure([
#box(image("index_files/figure-typst/fig-USA-1.svg"))
], caption: figure.caption(
position: top, 
[
Wellbeing scores for participants who reported working in the USA compared to those from other nations.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-USA>


#block[
#block[
#emph[Note];. This~is a raincloud plot showing individual scores and distributions.
]
]
#pagebreak(weak: true)
#figure([
#box(image("index_files/figure-typst/fig-CBI-paired-1.svg"))
], caption: figure.caption(
position: top, 
[
Personal compared to work burnout (measured as a percentage from 0 to 100) on the Copenhagen Burnout Inventory, for participants across both waves.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-CBI-paired>


#block[
#block[
#emph[Note];. This~is a raincloud plot showing individual scores and distributions, with grey lines connecting eqch participant's data for the two measures.
]
]
#pagebreak(weak: true)
= Appendix A
#counter(figure.where(kind: "quarto-float-fig")).update(0)
#counter(figure.where(kind: "quarto-float-tbl")).update(0)
#appendixcounter.step()
= This Section Is an Appendix
<apx-a>
#pagebreak(weak: true)
= Appendix B
#counter(figure.where(kind: "quarto-float-fig")).update(0)
#counter(figure.where(kind: "quarto-float-tbl")).update(0)
#appendixcounter.step()
= Another Appendix
<apx-b>


 
  
#set bibliography(style: "\_extensions/wjschne/apaquarto/apa.csl") 


