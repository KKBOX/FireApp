require 'spec_helper'

describe Less::Parser do

  cwd = Pathname(__FILE__).dirname

  it "instantiates" do
    lambda { Less::Parser.new }.should_not raise_error
  end

  describe "simple usage" do
    it "parse less into a tree" do
      root = subject.parse(".class {width: 1+1}")
      root.to_css.gsub(/\n/,'').should eql ".class {  width: 2;}"
    end

    it "accepts options when assembling the parse tree" do
      subject.parse(".class {width: 1+1}").to_css(:compress => true).strip.should eql ".class{width:2;}"
    end
  end

  it "throws a ParseError if the lesscss is bogus" do
    lambda { subject.parse('{^)') }.should raise_error(Less::ParseError, /missing closing `\}`/)
  end

  it "passes exceptions from the less compiler" do
    lambda { subject.parse('body { color: @a; }').to_css }.should raise_error(Less::ParseError, /variable @a is undefined/)
  end

  describe "when configured with source mapping" do
    subject { Less::Parser.new(:filename => 'one.less', :paths => [ cwd.join('one'), cwd.join('two') ], :dumpLineNumbers => 'mediaquery') }
    
    it "prints source maps" do
      subject.parse('@import "one.less"; @import "two.less";').to_css(:compress => false).gsub(/\n/,'').strip.should eql "@media -sass-debug-info{filename{font-family:file\\:\\/\\/one\\.less}line{font-family:\\000031}}.one {  width: 1;}@media -sass-debug-info{filename{font-family:file\\:\\/\\/two\\.less}line{font-family:\\000031}}.two {  width: 1;}"
    end
    
  end
  
  describe "when configured with multiple load paths" do
    subject { Less::Parser.new :paths => [ cwd.join('one'), cwd.join('two'), cwd.join('faulty') ] }

    it "will load files from both paths" do
      subject.parse('@import "one.less";').to_css.gsub(/\n/,'').strip.should eql ".one {  width: 1;}"
      subject.parse('@import "two.less";').to_css.gsub(/\n/,'').strip.should eql ".two {  width: 1;}"
    end

    it "passes exceptions from less imported less files" do
      lambda { subject.parse('@import "faulty.less";').to_css }.should raise_error(Less::ParseError, /variable @a is undefined/)
    end

    it "will track imported files" do
      subject.parse('@import "one.less";')
      subject.parse('@import "two.less";')
      # Parser#imports returns full path names
      subject.imports.grep(/one\.less$/).should_not be_empty
      subject.imports.grep(/two\.less$/).should_not be_empty
    end

    it "reports type, line, column and filename of (parse) error" do
      begin
        subject.parse('@import "faulty.less";').to_css
      rescue Less::ParseError => e
        e.type.should == 'Name'
        e.filename.should == cwd.join('faulty/faulty.less').to_s
        e.line.should == 1
        e.column.should == 16
      else
        fail "parse error not raised"
      end
    end

  end

  describe "when load paths are specified in as default options" do
    before do
      Less.paths << cwd.join('one')
      Less.paths << cwd.join('two')
      @parser = Less::Parser.new
    end
    after do
      Less.paths.clear
    end

    it "will load files from default load paths" do
      @parser.parse('@import "one.less";').to_css.gsub(/\n/,'').strip.should eql ".one {  width: 1;}"
      @parser.parse('@import "two.less";').to_css.gsub(/\n/,'').strip.should eql ".two {  width: 1;}"
    end
  end

  describe "relative urls" do

    it "keeps relative imports when true" do
      parser = Less::Parser.new :paths => [ cwd ], :relativeUrls => true
      expected = "@import \"some/some.css\";\nbody {\n  background: url('some/assets/logo.png');\n}\n"
      expect( parser.parse('@import "some/some.less";').to_css ).to eql expected
    end

    it "does not keep relative imports when false" do
      parser = Less::Parser.new :paths => [ cwd ], :relativeUrls => false
      expected = "@import \"some.css\";\nbody {\n  background: url('assets/logo.png');\n}\n"
      expect( parser.parse('@import "some/some.less";').to_css ).to eql expected
    end
    
  end
  
  # NOTE: runs JS tests from less.js it's a replacement for less-test.js
  describe "less-test", :integration => true do
    
    TEST_LESS_DIR = File.expand_path('../../lib/less/js/test/less', File.dirname(__FILE__))
    TEST_CSS_DIR =  File.expand_path('../../lib/less/js/test/css' , File.dirname(__FILE__))

    before :all do
      # functions.less test expects these exposed :
      Less.tree.functions[:add] = lambda do |*args| # function (a, b)
        a, b = args[-2], args[-1]
        Less.tree['Dimension'].new(a['value'] + b['value'])
        # return new(less.tree.Dimension)(a.value + b.value);
      end
      Less.tree.functions[:increment] = lambda do |*args| # function (a)
        a = args[-1]
        Less.tree['Dimension'].new(a['value'] + 1)
        # return new(less.tree.Dimension)(a.value + 1);
      end
      Less.tree.functions[:_color] = lambda do |*args| # function (str)
        str = args[-1]
        if str.value == 'evil red'
        # if (str.value === "evil red")
          Less.tree['Color'].new('600')
          # return new(less.tree.Color)("600")
        end
      end
    end
    
    after :all do
      Less.tree.functions[:add] = nil
      Less.tree.functions[:increment] = nil
      Less.tree.functions[:_color] = nil
    end
    
    Dir.glob(File.join(TEST_LESS_DIR, '*.less')).each do |less_file|
      
      base_name = File.basename(less_file, '.less')
      css_file = File.join(TEST_CSS_DIR, "#{base_name}.css")
      raise "missing css file: #{css_file}" unless File.exists?(css_file)
      
      less_content = File.read(less_file)
      case base_name
        when 'javascript'
          # adjust less .eval line :
          #   title: `process.title`;
          # later replaced by line :
          #   title: `typeof process.title`;
          # with something that won't fail (since we're not in Node.JS)
          less_content.sub!('process.title', '"node"')
      end
      
      it "#{base_name}.less" do
        parser = Less::Parser.new(:paths => [ File.dirname(less_file) ])
        less = parser.parse( less_content )
        less.to_css.should == File.read(css_file)
      end
      
    end
    
  end
  
end
