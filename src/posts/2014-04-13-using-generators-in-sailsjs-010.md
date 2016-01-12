---
layout: post.swig
title: Using generators in SailsJS 0.10.x
date: 2014-04-13 16:59:27
tags:
  - sails,
  - generators,
  - javascript
---

Sails' new [release candidate](https://github.com/balderdashy/sails/tree/v0.10.0-rc5) is a pretty big shift from the 0.9 version, and in a good way.

## What is a generator?
In Sails-land, a generator is basically a templated way to create something inside your project. If you are a [Yeoman](http://yeoman.io) user, sails generators are analgous.
> "[Generators] create new files and folders within your app based on the options and templates you provide the generator"

In previous versions of Sails, there are only built-in generators:
```bash
$ sails generate model foo
```
In turn, Sails would create a new file `Foo.js` in your `api/models` folder. The scaffold for the model was quite limited. Now Sails allows you to create your own custom generators for just about anything you can imagine.

## How do I use custom generators?
The other day on #sailsjs, someone wanted to know how to use generators to create a model in [coffeescript](http://coffeescript.org/). I looked around, and found out that github user [t3chnoboy](https://github.com/t3chnoboy) had pushed code to support it. Unfortunately, it wasn't clear to me just exactly how to get generators and sails working together.

Make sure you have the 0.10.0-rc5 release installed globally
```bash
$ npm install -g sails@beta
```
This will install the latest RC of Sails globally. If you are still using 0.9.x, you can always roll-back later. (If you know how to easily switch between two versions of a globally installed npm package, please let me know!)

Create a new Sails project
```bash
$ sails new testApp && cd testApp
```

Install the `sails-generate-model` package
```bash
$ npm install --save-dev sails-generate-model
```

Modify your `.sailsrc` file to expose your project to the generator
We are using a custom generator for the keyword 'model', so in our `.sailsrc` JSON, we need to tell Sails to use the installed package to generate models when we `sails generate model <modelname>`.
```json
{
  "generators": {
    "modules": {
    	"model" : "sails-generate-model"
    }
  }
}
```

Save that file, and use it to generate a new coffeescript model:
```bash
$ sails generate new model foo --coffee
```
Now if you open up your `api/models` folder, you should see a file `Foo.coffee`:
```
 # Foo.coffee
 #
 # @description :: TODO: You might write a short summary of how this model works and what it represents here.
 # @docs        :: http://sailsjs.org/#!documentation/models

module.exports =

  attributes: {}

```
## Where to go from here?
`npm search sails-generate` is a good way to see what has been created so far.
