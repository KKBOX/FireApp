# less.rb

The **dynamic** stylesheet language.

<http://lesscss.org>

[![Build Status](https://secure.travis-ci.org/cowboyd/less.rb.png)](http://travis-ci.org/cowboyd/less.rb)

## About

These are Ruby bindings for the next generation LESS, which is implemented in JavaScript

For more information, visit <http://lesscss.org>.

## Usage

less.rb exposes the `less.Parser` constructor to ruby code via `Less::Parser`. You can instate it
context free:

```ruby
parser = Less::Parser.new
```

or with configuration options:

```ruby
parser = Less::Parser.new :paths => ['./lib', 'other/lib'], :filename => 'mystyles.less'
```

Once you have a parser instantiated, you can parse code to get your AST !

```ruby
tree = parser.parse(".class {width: 1+1}") # => Less::Tree
tree.to_css #=> .class {\n  width: 2;\n}\n
tree.to_css(:compress => true) #=> .class{width:2;}
```

## License

less.rb is licensed under the same terms as less.js

See `lib/js/LICENSE` file.


> copyright 2011,2012 Charles Lowell
