---
layout: post
title:  "Angular 2 build with maven"
date:   2016-10-9 14:30:39 +0600
categories:
tags: Angular2 Npm Maven Build
---

A few weeks ago Google published Angular 2.0 final release. I've already tried it and I like it. However, if you 
face with problem, it probably will be difficult to find solution in the internet. Angular2 has been strongly changed 
since rc1 was published. I think we must fix this problem and publish a lot of articles and posts about angular2. My
 contribution is article about building the application with angular2. 
 
### Build requirements

I used to have following features in client build system:

* Dependency management
* Build for development with debugging
* Build for production (compressed)
* Check style
* Unit tests
* E2E tests

### Possible implementations

Angular2 tutorial recommends us to use npm as a dependency manager. As I know, Bower is officially not supported,
but there are some ways to use it too. In short, the package manager is npm without alternatives.

Firstly I tried to use gulp to write build script. I've almost done it, but the system was too complicated. 

//todo describe why is it complicated?

[Angular-CLI][angularCli]{:target="_blank"} 

### Integration with maven`

[angularCli]: https://github.com/angular/angular-cli