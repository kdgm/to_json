# ToJson

A performant Ruby JSON Serializer DSL for Oj. ToJson uses the brand new
Oj StringSerializer to provide the fastest performance and lowest
possible memory footprint.

Why? Because current Ruby JSON serialisers take too long and use too
much memory or can't express **all** valid JSON structures.

ToJson is ORM and ruby web framework agnostic and designed for serving fast
and flexible JSON APIs.

ToJson is able to serialize an impressive 1.4 million operations a second
on a 4 core laptop when running multiple ruby processes.

## Installation

Add this line to your application's Gemfile:

Do this for now:

    gem 'to_json', github: 'ahacking/to_json'

Eventually:

    gem 'to_json'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install to_json

## Design

### Goals

The following goals were the drivers and rationale behind ToJson:
 + Ability to express any JSON structure with a simple DSL
 + Performance.  Existing solutions spend far too much time generating
JSON and this costs money and power.  Server hosting is not free and
needlesly burning power and deploying more servers because of rendering
overhehad should be avoided.

### Design Choices

#### Oj for fast JSON encoding

Leveraging Oj from the start was a deliberate technology choice.  The Oj
gem is as close to native C as anyone is likely to get in Ruby.

I developed a JSON serializer that built temporary Array and Hash structures
to be passed to Oj#dump.  This worked well and was already faster than
exisitng JSON serializers. However I thought we could do better...

#### Streaming architecture

I had the idea that a streaming serializer would be architecturally
superior (more flexible) and as fast (or faster) and use less memory than
an approach that builds temporary array and hash stuctures.  The Oj author
also saw merit in the idea and implemented a new StringSerializer to
support a serialization model where you can push objects in one end and
get JSON out the other without using temporary structures.  This proved to
be slightly faster than building temporary arrays and hashes in synthetic
benchmarks but it also results in less memory overhead which will be a
bigger factor in production systems.

In ToJson, models/objects/values/etc are encoded directly into a buffer with
as close to native C performance as is possible in ruby.

The architectural benefit of a streaming approach is that it paves the way
for being able to serve and stream massive result sets to sockets and files
using any of the available ruby web frameworks once this feature is made
available in Oj.

#### Avoid templates

ToJson does NOT use a Rails ActionView template approach; instead the DSL is
intended to be used directly with a serializer block or within your own serializer
classes. This means ToJson supports all of the expressive power of real Ruby classes
including modules, inheritence, mixins, delegates etc and DOES NOT need to implement
slower and less powerful quasi equivalents in a templating language.

What does this mean?
 + You can easily DRY up your JSON API's
 + You can easily version your API's
 + You can keep your model helpers and formatters nicely namespaced rather than
   global.
 + You will not lose the expressiveness and ability to compose and structure
   your serialization code.  Its 100% ruby, not templates.

#### Avoid slow language features

ToJson purposefully does not require Ruby language features like
`method_missing` because it is about 7 times slower than a regular method
call for very minor syntactical advantage. Whilst that alone does not
account for the majority of the speed of ToJson, every bit helps when you
are serializing thosands of objects multiplied by thousands of attributes.

#### Avoid magic, be explicit, not implicit

To keep the DSL lean and mean, explicitness was favoured over lots of
ruby meta programming shenanigans.  Being explicit about what model
attribute you want encoded in your JSON is consise and allows you to easily
and naturally perform any data presentation formatting without a DSL escape
clause, and more importantly without muddying up your models with presentation
concerns.

Keeping the DSL simpler also made it faster and as a user of ToJson it
leads to a better structuring and separation of concerns. It also avoids
assuming a 'current model' as some DSL's do which further harms flexibility
and composition. Flexibility is especially important where you need to include
attributes from related/parent models, or collect and aggregrate model data for
presentation in JSON.

#### ORM agnostic

Being explicit means we are also ORM agnostic.  ToJson does not care
what ORM you are using, or what class the objects being serialized are.

## ToJson Alternatives

Some alternatives to ToJson and primary diferences.

### ToJson vs Jbuilder
 + DSL relys on method_missing for JSON attribute names
 + Integrated with Rails framework
 + Fragment caching supported in DSL
 + Slower than ToJson

### ToJson vs ActiveModel::Serializers
 + Currently undergoing unstable changes
 + Tied to ActiveModel ORM
 + Tied to Rails
 + Uses Serializer classes
 + Has a serializer generator
 + Tries to be declarative
 + Very limited control over expression of JSON structure
 + Looks up serializers based on the model class.  If you care about API versioning
   you will realize that this is bad and the controller/presenter MUST decide this.
 + Has notion of a 'current model' for the serialization context.
 + Uses 'filters' over temporary hashes to control what attributes and related
   associations should be serialized.
 + Creates a lot of temporary serializer objects

### ToJson vs RABL
 + A complex (insane) syntax that hinders expressing even simple JSON structures.
 + Inteferes with the order of serialized items.
 + Many DSL surprises.
 + Uses template DSL as opposed to real use Ruby modules and classes for composition.
 + Why?

### ToJson vs ROAR
 + ROAR `extend`s your model instances and invalidates the Ruby method cache which
   is a perfomance killer
 + If using ROAR's decorator approach to avoid the extend problem you must use lambdas
   in the serializer class
 + Tries to be declarative
 + Very limited control over expression of JSON structure
 + ROAR provides bi-directional serialization
 + Explicit support for JSON+HAL, but see ToJson example below

### ToJson vs JSONBuilder
 + JSONBuilder is very slow (but not as slow as Jsonify)
 + DSL relys on method_missing for JSON attribute names

### ToJson vs Jsonify
 + Jsonify is the slowest JSON serialization option I am aware of
 + DSL relys on method_missing for the JSON attribute names
 + Jsonify uses a builder model as opposed to serializer classes
 + Jsonify supports rails template integration through a companion gem
 + Jsonify provides Tilt based view integration


## Benchmarks

You are encouraged to verify benchmarks for yourself as follows:

```
$ cd test/benchmark
$ bundle install
$ ./benchmark.rb
```

On a Intel(R) Core(TM) i7-3610QM CPU @ 2.30GHz (Ivy Bridge):

```
Serialize 500,000 objects separately:
                               user     system      total         real
ToJson (class) - simple    1.330000   0.000000   1.330000 (  1.324826)
ToJson (class) - parallel  0.000000   0.010000  42.880000 (  5.459818)
(8000000 ops)
ToJson (class) - complex   5.000000   0.000000   5.000000 (  5.012555)
ToJson (block) - simple    5.190000   0.000000   5.190000 (  5.191536)
ToJson (block) - complex   9.390000   0.000000   9.390000 (  9.390543)
Jbuilder - simple          6.180000   0.000000   6.180000 (  6.182140)
Jbuilder - complex        22.600000   2.240000  24.840000 ( 24.861366)
```

Ruby 2.7.8

```
Serialize 500,000 objects separately:
                          user     system      total        real
ToJson (class) - simple   0.990960   0.000810   0.991770 (  0.991792)
ToJson (class) - parallel 0.001599   0.017075  37.137801 (  2.362301)
(8000000 ops)
ToJson (class) - complex  7.461308   0.002083   7.463391 (  7.464256)
ToJson (block) - simple   3.501560   0.000000   3.501560 (  3.501646)
ToJson (block) - complex 10.815699   0.000428  10.816127 ( 10.816804)
Jbuilder       - simple   5.677831   0.001979   5.679810 (  5.682258)
Jbuilder       - complex 23.310981   0.001866  23.312847 ( 23.316103)
JSONBuilder    - complex 28.786932   0.002175  28.789107 ( 28.796768)
jsonify        - complex 48.479856   0.006111  48.485967 ( 48.503229)
```

The real time used is the important figure. As can be seen ToJson using a
class based serializer is 4.7 times faster than the fastest alternative.

The benchmark invokes to_json each time as would be the case serving separate
requests. Invoked this way is worst case vs a single large result, however
it is able to serialize 377 thousand address objects per second per CPU, and
just under 100 thousand complex objects a second per CPU.

On a multi-core machine running the benchmark in 32 separate ruby processes
to_json gives impressive throughput. ToJson is able able to serialize
1.4 million individual address serializations per second on a 4 core Intel
laptop (i7-3610QM CPU @ 2.30GHz Ivy Bridge). Performance is linear and in
real applications disk and network I/O will be the limiting factor.


Old benchmark results for posterity:

```
JSONBuilder original benchmark (500000 complex objects):
                      user     system      total        real
ToJson (class)    7.950000   2.080000  10.030000 ( 10.045144)
ToJson (block)   14.340000   2.130000  16.470000 ( 16.471651)
Jbuilder         29.180000   2.600000  31.780000 ( 31.790766)
JSONBuilder      56.230000   2.820000  59.050000 ( 59.083252)
jsonify         156.310000   2.700000 159.010000 (159.088787)
```

TODO. Add benchmarks for ActiveModel::Serializers, ROAR and RABL benchmarks.
This will require a different JSON structure which they are all
capable of producing.


## Usage

## General Invocation with block

```ruby
  # args are optional
  ToJson::Serializer.json!(args...) do |args...|
    # DSL goes here, callers methods, helpers, instance variables and constants are all in scope
  end
end
```

### Invocation from Rails controller, respond_with and block

```ruby
def index
  @post = Post.all
  # the rails responder will call to_json on the ToJson object
  respond_with ToJson::Serializer.encode! do
    # DSL goes here, contoller methods, helpers, instance variables and
    # constants are all in scope
  end
end
```

### Invocation from Rails API controller, render with block (better)

```ruby
def index
  @post = Post.all
  # generate the json and pass it to render for sending to the client
  render json: ToJson::Serializer.json! do
    # DSL goes here, contoller methods, helpers, instance variables and
    # constants are all in scope
  end
end
```

### Invocation from Rails API controller with custom serializer class (recommended)

```ruby
def index
  # just pass the collection (instead of the controller) to better support
  # serializing Posts in different contexts and controllers. @foo is evil
  render json: PostsSerializer.json!(Post.all)
end
```

### JSON Objects

The `put` method is used to serialize named object values and
create arbitrarily nested objects.

All values will be serialized according to Oj processing rules.

#### Example creating an object with named values:

```ruby
put :title, @post.title
put :body, @post.body
```

#### Example with fields helper

```ruby
put_fields @post, :title,  :body
```

#### Example with fields helper and key mapping.

The DSL accepts array pairs, hashes, arrays containing any
mix of array or hash pairs.

The following examples are all equivalent and map 'title' to 'the_tile'
and 'created_at' to 'post_date' and leave 'body' as is.

```ruby
put_fields @post, [:title, :the_title], :body, [:created_at, :post_date]
put_fields @post, [[:title, :the_title], :body, [:created_at, :post_date]]
put_fields @post, {title: :the_title, body: nil, created_at: :post_date}
put_fields @post, [:title, :the_title], :body, {:created_at => :post_date}
put_fields @post, {title: :the_title}, :body, {created_at: :post_date}
```

#### Example with fields helper with condition.

There are helpers to serialize object fields conditionally.

```ruby
put_fields_unless_blank @post, :title: :body
put_fields_unless_nil @post, :title: :body
put_fields_unless :large?, @post, :title: :body
put_fields_if :allowed, @post, :title: :body
```

#### Example of serializing a single field

There are single field equivalents of the multiple field helpers. these
take an optional mapping key and just like put they accept a block.

```ruby
put_field @post, :title
put_field @post, :title, :the_title
put_field_unless_blank @post, :title, :the_title
put_field_unless_nil @post, :title, :the_title
put_field_unless :large? @post, :body
put_field_if :allowed? @post, :body
```

#### Example creating a nested object

The long way:

```ruby
put :post do
  put :title, @post.title
  put :body, @post.body
end

Using field helper:

```ruby
put :post do put_fields @post, :title :body end
```

### Example of a named object literal

The hash value under 'author' will be serialized directly by Oj.

```ruby
put :author, {name: 'Fred', email: 'fred@example.com', age: 27}
```

### Example of an object literal

The hash value will be serialized by Oj.

```ruby
value {name: 'Fred', email: 'fred@example.com', age: 27}
```

#### Example creating a nested object with argument passed to block

```ruby
put :latest_post, current_user.posts.order(:created_at: :desc).first do |post|
  put_fields post, :title, :body
end
```

### JSON Arrays

Arrays provide aggregation in JSON and are created with the `array` method.  Array
elements can be created through:
+ literal value(s) passed to `array` without a block
+ evaluating blocks over the argument passed to array (similar to `each_with_index`)
+ evaluating a block with no argument

Within the array block, array elements can be created using `value`, however this is
called implicitly for you when using `put` or `array` inside the array block.

### Example of an array literal

The literal array value will be passed to Oj for serialization.

```ruby
array ['Fred', 'fred@example.com', 27]
```

### Example of an array collection

The @posts collection will be passed to Oj for serialization.

```ruby
array @posts
```

### Example of array with block for custom object serialization

```ruby
array @posts do |post|
  # calling put/put_* inside an array does an implicit 'value' call
  # placing all named values into a single object
  put_fields post, :title, post.body
end
```

### Example of array with block and item index for custom object serialization

```ruby
array @posts do |post, index|
  put_fields post, :title, post.body
  put :position, index
end
```

### Example collecting post author emails into a single array.

Each post item will be processed and the email addresses of the author
serialized.

```ruby
array @posts do |post|
  @post.author.emails.each do |email|
    value email.address
  end
end
```

### Example creating array element values explicitly

The following example will an array containing 3 elements.

```ruby
array do
  value 'one'
  value 2
  value do
    put label: 'three'
  end
end
```

### Example creating array with a nested object and nested collection

```ruby
array do
  value do
    put :total_entries, @posts.total_entries
    put :total_pages, @posts.total_pages
  end
  array @posts do
    put :title, post.title
    put :body, post.body
  end
end
```

### Example creating a paged collection as per the HAL specification:

```ruby
put :meta do
  put_fields @posts, :total_entries, :total_pages
end
put :collection do
  array @posts do |post| put_fields post, :title, :body end
end
put :_links do
  put :self { put :href, url_for(page: @posts.current_page) }
  put :first { put :href, url_for(page: 1) }
  put :previous { @posts.current_page <= 1 ? nil : put :href, url_for(page: @posts.current_page-1) }
  put :next { current_page_num >= @posts.total_pages ? nil : put :href, url_for(page: @posts.current_page+1) }
  put :last { put :href, url_for(page: @posts.total_pages) }
end
```

### Example of nested arrays, and dynamic array value generation:

```ruby
array do
  # this nested array is a single value in the outer array
  array do
    value 'a'
    value 'b'
    value 'b'
  end
  # this nested array is a single value in the outer array
  array (1..3)
    (1..4).each do |count|
      # generate 'count' values in the nested array
      count.times { value "item #{count}" }
    end
  end
end
```

### Example of defining and using a helper

```ruby
def fullname(*names)
  names.join(' ')
end

put :author, fullname(@post.author.first_name, @post.author.last_name)
```

### Example of class based serialization and composition:


```ruby
# A Post model serializer, using ::ToJson::Serializer inheritance
class PostSerializer < ::ToJson::Serializer
  include PostSerialization

  # override the serialize method and use the ToJson DSL
  # any arguments passed to encode! or json! are passed into serialize
  def serialize(model)
    put_post_nested model
  end
end

# A Post collection serializer using include ToJson::Serialize approach
class PostsSerializer
  include PostSerialization

  def serialize(collection)
    put_posts collection
  end
end

# define a module so we can mixin Post model serialization concerns
anywhere and avoid temporary serializer objects for collection items
module PostSerialization
  include  ::ToJson::Serialize

  # formatting helper
  def fullname(*names)
    names.join(' ')
  end

  def put_post(post)
    put :title, post.title
    put :body, post.body
    put :author, fullname(post.author.first_name, post.author.last_name)
    put :comments, CommentsSerializer.new(post.comments)
  end

  def put_post_nested(post)
    put :post do
      put_post(post)
    end
  end

  def serialize_posts(posts)
    put :meta do
      put :total_entries, posts.total_entries
      put :total_pages, posts.total_pages
    end
    put :collection, posts do |post|
      put_post post
    end

  end
end
```

## ToDo

+ Tests and more tests.
+ API Documentation.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
