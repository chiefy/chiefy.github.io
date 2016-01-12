---
layout: post.swig
title: Using Sails Generators To Integrate An ember-cli Project
date: 2014-09-03 18:00:00
tags:
  - sails
  - generators
  - javascript
  - ember
  - ember-cli
  - ES6
  - modules
---

Recently I have been trying to learn [Ember](http://emberjs.com/) and I came across the amazing command line utility [`ember-cli`](http://www.ember-cli.com/) written by [Stefan Penner](https://github.com/stefanpenner). `ember-cli` is the missing utility belt for ember based projects. Among its features is a generator that creates a strongly opinionated project structure and build chain (`ember` is strongly opinionated - [convention over configuration](http://confy.wecode.io/talks/2013/arrrrcamp/ember-on-rails-convention-over-configuration-on-both-sides-of-the-tubes)). `ember-cli` uses an [ES6 module transpiler](http://esnext.github.io/es6-module-transpiler/) allowing users to use next-gen ES6 module support in their current projects today. It also utilizes [`broccoli`](https://github.com/broccolijs/broccoli) for build tooling as opposed to `grunt` which Sails seems to favor. More on that later.

Along with `ember-cli`, I ran across [`sails-ember-blueprints`](https://github.com/mphasize/sails-ember-blueprints) by [mphasize](https://github.com/mphasize) which overrides some of Sails' blueprint templates for compatibility with [Ember-Data](http://emberjs.com/api/data/)'s `RESTAdapter`.

I decided to take a stab at creating some [Sails](http://sailsjs.org/) generators around these great projects.

## Getting Started

In order to get started, you will need to make sure you have the latest `sails`, `ember-cli` and `sails-generate-new-ember`:
```
$ npm install -g sails ember-cli sails-generate-new-ember sails-generate-frontend-ember sails-generate-backend-ember
```

To use the newly installed generator, you will need to modify (or create) your `.sailsrc` located in your home folder. Sails allows you to override its built-in generators for creating a new application structure. So in theory you could:

```
{
    "generators" : {
        "modules" : {
            "new" : "sails-generate-new-ember"
        }
    }
}
```

The issue with that, especially if you save your `.sailsrc` in your home folder, is that everytime you call `sails new` it will use the ember-based generators. I have a feeling that you probably won't want that, so instead, you should create a `.sailsrc` that uses an alternate module name:

```
{
    "generators" : {
        "modules" : {
            "ember-app" : "sails-generate-new-ember"
        }
    }
}
```

Finally, we can create our new project by calling `sails generate`.
```
$ sails generate ember-app myAwesomeApp
```

## Project Structure
If you are familiar with the default `sails new <app-name>` generator and it's resulting project structure, you will find some large differences here. The first thing to note is that there is no `assets` folder. Instead, there is an `ember` folder which is where all of the `ember-cli` based project structure resides. Since `ember-cli` uses `broccoli` for tooling, I've decided to remove the `Gruntfile.js` and `tasks` folder for the time being as all of the frontend build is being done by `ember serve`.

#### Sails Blueprints
I've taken the `sails-ember-blueprints` project code and inserted it into the `sails-generate-backend-ember` step of the generator. The blueprints reside in the `api/blueprints` folder, they modify Sails' response output to achieve compatibility with Ember-Data's [`RESTAdapter`](http://emberjs.com/api/data/classes/DS.RESTAdapter.html). Many thanks to GitHub user [mphasize](https://github.com/mphasize) for this project as I am sure it saved me a ton of time and effort.

## Fire It Up!
For now, during development, you will need to start up two seperate servers: your Sails API server which will serve your JSON API (port 1337), and `ember-cli`'s server which will serve up the proper client application code (port 4200). As you will see when you point your browser to `http://localhost:4200/`, there is nothing really to show as we haven't created any of our frontend (or backend) project. I recommend opening two console tabs and executing one of these commands in each.

```
$ sails lift
```
```
$ cd ember && ember serve
```

![Initial ember website](/assets/img/welcome_to_ember.png)

## Lessons Learned or How I Learned To Stop Worrying and Love The `broccoli`

When I was developing this generator I was thinking it would be a great opportunity to try to use `broccoli` for building out the frontend and serving it with `sails lift`. Unfortunately, after looking into some of the code in `ember-cli`, it's not as easy as I had hoped. Both `sails lift` and `ember serve` try to serve using their own instances of express. `ember serve` uses `broccoli` under the hood to do a lot when watching templates and files in the `ember` project. I have mostly unsuccesfully tried to bootstrap both of these processes in the project's main `app.js` file, which you can run with `node app.js`, but you will see both commands try to use the output stream asynchronously and it results in a confusing jumble of console output. This would especially be confusing when trying to debug.

## Next Steps

Obviously this site doesn't do anything with our Sails backend,  but it gives you a starting point to create your web application using Sails and Ember. Having to run two commands to serve the Sails backend and Ember frontend is not optimal. I created these generators as an exercise to learn `ember-cli`, ES6 Modules and dig a little deeper into Sails generators. As Ember projects seem to gravitate towards using Rails, I thought this would be a clear next-step to get the application stack *one hundred percent JS*.

#### !CAUTION!
These generators are not intended for production use (yet), but any feedback and/or critique is welcome.
