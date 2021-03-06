# IsLoggable

Utility inteface that allows you to use special metadata to add logging statements to your methods.

Build macro attached to the `IsLoggable` interface will cause several things to happen.
- Macro will scan class for any variable or property of type ILogger
  - If one exists it will be used in the logger calls
  - If more than one exists the first one will be used and macro will produce a warning
  - If no such property exists it will search through the inheritance chain until it finds one (using previous two rules)
  - If search was still unseccessful a public variable `@Inject @Optional(true) public var logger:ILogger` will be created
- in every method which is annotated with one of `@Debug`, `@Info`, `@Warn`, `@Error` or `@Fatal` metadata will be created a logger call
  - `@Debug` will produce `logger.debug` and vice versa


## Default behavior

Each method in following example contains generated logger statement.

```haxe
class MyClass implements IsLoggable
{
  public function new()
  {
  }

  @Debug
  public function someMethod()
  {
    // Produces:
    // logger.debug("{}()", ["someMethod"]);
  }

  @Debug
  public fuction someMethodWithArgs(arg0:Int)
  {
    // Produces:
    // logger.debug("{}(arg0='{}')", ["someMethodWithArgs", arg0]);
  }

  @Warn
  public fuction someMethodWithMultipleArgs(num:Int, str:String)
  {
    // Produces:
    // logger.warn("{}(num='{}', str='{}')", ["someMethodWithArgs", num, str]);
  }
}
```

## Customizing log statements

Sometimes default statements are just not enough or you need to print out additional information. IsLoggable also allows yout to customize the statements.

Object within the metadata can have following properties:
- `msg` - Replaces default generated message string with this value
- `arg` - Replaces default generated params array with this value
- `includeArgs` - if `true` generated array of arguments will be appended to the `msg`

```haxe
class MyClass implements IsLoggable
{
  var id:Int;

  public function new(id:Int)
  {
    this.id = id;
  }

  @Debug({
    msg:"Something happened to myObject with id={}",
    arg:[this.id]
  })
  public function someMethodWithCustomMessage()
  {
    // Produces:
    // logger.debug("Something happened to myObject with id={}", [this.id]);
  }

  @Debug({
    msg:">>>>>>>> Important",
    includeArgs: true
  })
  public function someMethodThatStandsOutInLog(arg0:Int, someString:String, anotherString:String)
  {
    // Produces:
    // logger.debug(">>>>>>>> Important [arg0='{}', someString='{}', anotherString='{}']", [arg0, someString, anotherString]);
  }

  @Debug({
    arg:[this.id,someString]
  })
  public function methodWithCustomArguemts(arg0:Int, someString:String, anotherString:String)
  {
    // Produces:
    // logger.debug("{}(this.id='{}', someString='{}')", ["methodWithCustomArguemts", this.id, someString]);
  }
}
```
