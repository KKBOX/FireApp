require 'helper'

describe Temple::HTML::Pretty do
  before do
    @html = Temple::HTML::Pretty.new
  end

  it 'should indent nested tags' do
    @html.call([:html, :tag, 'div', [:multi],
      [:html, :tag, 'p', [:multi], [:multi, [:static, 'text'], [:dynamic, 'code']]]
    ]).should.equal [:multi,
                     [:code, "_temple_html_pretty1 = /<code|<pre|<textarea/"],
                     [:multi,
                      [:static, "<div"],
                      [:multi],
                      [:static, ">"],
                      [:multi,
                       [:static, "\n  <p"],
                       [:multi],
                       [:static, ">"],
                       [:multi,
                        [:static, "\n    text"],
                        [:multi,
                         [:code, "_temple_html_pretty2 = (code).to_s"],
                         [:code, "if _temple_html_pretty1 !~ _temple_html_pretty2; _temple_html_pretty2 = _temple_html_pretty2.gsub(\"\n\", \"\\n    \"); end"],
                         [:dynamic, "_temple_html_pretty2"]]],
                       [:static, "\n  </p>"]],
                      [:static, "\n</div>"]]]
  end

  it 'should not indent preformatted tags' do
    @html.call([:html, :tag, 'pre', [:multi],
      [:html, :tag, 'p', [:multi], [:static, 'text']]
    ]).should.equal [:multi,
                     [:code, "_temple_html_pretty1 = /<code|<pre|<textarea/"],
                     [:multi,
                      [:static, "<pre"],
                      [:multi],
                      [:static, ">"],
                      [:multi,
                       [:static, "<p"],
                       [:multi],
                       [:static, ">"],
                       [:static, "text"],
                       [:static, "</p>"]],
                      [:static, "</pre>"]]]
  end

  it 'should not escape html_safe strings' do
    with_html_safe do
      @html.call(
        [:dynamic, '"text<".html_safe']
      ).should.equal [:multi,
                      [:code, "_temple_html_pretty1 = /<code|<pre|<textarea/"],
                      [:multi,
                       [:code, "_temple_html_pretty2 = (\"text<\".html_safe).to_s"],
                       [:code, "if _temple_html_pretty1 !~ _temple_html_pretty2; _temple_html_pretty3 = _temple_html_pretty2.html_safe?; _temple_html_pretty2 = _temple_html_pretty2.gsub(\"\n\", \"\\n\"); _temple_html_pretty2 = _temple_html_pretty2.html_safe if _temple_html_pretty3; end"],
                       [:dynamic, "_temple_html_pretty2"]]]
    end
  end
end
