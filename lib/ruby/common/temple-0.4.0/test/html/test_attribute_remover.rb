require 'helper'

describe Temple::HTML::AttributeRemover do
  before do
    @remover = Temple::HTML::AttributeRemover.new
    @disabled_remover = Temple::HTML::AttributeRemover.new :remove_empty_attrs => false
  end

  it 'should pass static attributes through' do
    @remover.call([:html, :tag,
      'div',
      [:html, :attrs, [:html, :attr, 'class', [:static, 'b']]],
      [:content]
    ]).should.equal [:html, :tag, "div",
                     [:multi,
                      [:html, :attr, "class", [:static, "b"]]],
                     [:content]]
  end

  it 'should check for empty dynamic attribute if :remove_empty_attrs is true' do
    @remover.call([:html, :tag,
      'div',
      [:html, :attrs, [:html, :attr, 'class', [:dynamic, 'b']]],
      [:content]
    ]).should.equal [:html, :tag, "div",
                    [:multi,
                      [:multi,
                       [:capture, "_temple_html_attributeremover1", [:dynamic, "b"]],
                       [:if, "!_temple_html_attributeremover1.empty?",
                        [:html, :attr, "class", [:dynamic, "_temple_html_attributeremover1"]]]]],
                     [:content]]
  end

  it 'should not check for empty dynamic attribute if :remove_empty_attrs is false' do
    @disabled_remover.call([:html, :tag,
      'div',
      [:html, :attrs, [:html, :attr, 'class', [:dynamic, 'b']]],
      [:content]
    ]).should.equal [:html, :tag, "div",
                     [:multi,
                      [:html, :attr, "class", [:dynamic, "b"]]],
                     [:content]]
  end
end
