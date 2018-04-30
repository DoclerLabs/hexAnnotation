# hexAnnotation [![TravisCI Build Status](https://travis-ci.org/DoclerLabs/hexAnnotation.svg?branch=master)](https://travis-ci.org/DoclerLabs/hexAnnotation)

Utilities for reading and writing class metadata

*Find more information about hexMachina on [hexmachina.org](http://hexmachina.org/)*

## Dependencies

* [hexReflection](https://github.com/DoclerLabs/hexReflection)

## Features

- Read metadata at compile time.
- Handles inheritance chain.
- Read properties and methods signatures (to be used by DI frameworks).
- Use [hexReflection](https://github.com/DoclerLabs/hexReflection) to export annotated (@Inject, @PostConstruct", @Optional, @PreDestroy) members information (essentially reflection data) to a static field instance.
- Generates logging statements based on method annotations
  - More info [here](src/hex/log/README.md)
- Replaces expressions in annotations with their respective values
  - More info [here](src/hex/annotation/README.md)

## Simple example

To generate a class description at compile-time, implement IInjectorContainer and add annotations on the members that you want to produce reflection.

```haxe
class MockClassInjectee implements IInjectorContainer
{
	@Inject( "id" )
	public var property : String;
	//property informations will be stored
	
	@Inject( "id" )
	public function new( arg : Int ) 
	{
		//constructor informations will be stored
	}
	
	public function doSomething() : Void
	{
		//this method will be ignored
	}
	
	@PostConstruct( 1 )
	public function doSomething() : Void
	{
		//this method description will be stored as well
	}
}
```

To get your reflection data at runtime, use FastClassDescriptionProvider like shown below.

```haxe
var provider = new FastClassDescriptionProvider();
var description = provider.getClassDescription( MockClassInjectee );
```
