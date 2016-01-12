---
layout: post.swig
title: Easily create Angular-based frontend scaffolding for Sails
date: 2014-06-24 05:00:00
tags:
  - angular
  - sails
  - javascript
---

SailsJS 0.10 introduces the concept of generators, a layer to allow users to create their own templates around the various pieces of a SailsJS project. One of the generators, sails-generate-frontend will generate all your front-end assets. I have created sails-generate-frontend-angular, a generator to override the default frontend generator and create a simple scaffold for an Angular frontend.

The first thing you will need to do is make sure to install Sails release-candidate 0.10.x.

```
$ npm install -g sails@beta
```

Install sails-generate-frontend-angular.

```
$ npm install -g sails-generate-frontend-angular
```

The best way to use this generator is to have it kick off as part of Sails' `generate-new` generator which runs when you execute `sails new <appName>`. In order for Sails to recognize this generator, we must modify our `.sailsrc` file.

```
$ cd ~ && vim .sailsrc
```

```
{
    "generators": {
        "modules" : {
            "frontend" : "sails-generate-frontend-angular"
        }
    }
}
```

After you have saved your `.sailsrc` file to your home directory, create a new sails project and fire it up! Open up your favorite web browser and go to `http://localhost:1337/`

```
$ sails new ngSailsApp && cd ngSailsApp && sails lift
```

![Screenshot](/assets/img/sails-generate-frontend-angular/new_app_screenshot.jpg)

Exit your Sails app with `ctrl-c`. Now generate an api. For this example, we'll generate an api around a movie class.
```
$ sails generate api movie

info: Created a new model ("Movie") at api/models/Movie.js!
info: Created a new controller ("movie") at api/controllers/MovieController.js!

info: REST API generated @ http://localhost:1337/movie
info: and will be available the next time you run `sails lift`.
```

Modify your generated model file (in `api/models/Movie.js`) to add some attributes.

```
module.exports = {
  attributes: {
    title: 'string',
    year: 'integer',
    genre: 'string',
    rating: 'integer'
  }
};
```

Once again, fire up the Sails app with `sails lift`, and open a browser to `http://localhost:1337/#/movies`. Here you will see a very, very, very unstyled, basic CRUD scaffold built with [Sails](http://sailsjs.org/), [Angular](https://angularjs.org/), [RESTAngular](https://github.com/mgonto/restangular/), and [ui-router](http://angular-ui.github.io/ui-router/site/#/api/ui.router).

![CRUD Movie Example](/assets/img/sails-generate-frontend-angular/new_movie_crud.gif)

Please feel free to check out the [code on github](https://github.com/chiefy/sails-generate-frontend-angular) and make any suggestions you feel would improve the project.
